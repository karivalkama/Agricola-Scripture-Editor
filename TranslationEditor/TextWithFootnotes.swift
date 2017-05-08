//
//  TextWithFootnotes.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 25.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This element contains both text element, cross reference and footnote data
// The elements are ordered in a very specific way
final class TextWithNotes: USXConvertible, JSONConvertible, AttributedStringConvertible, Copyable
{
	// ATTRIBUTES	------------
	
	var crossReferences: [CrossReference]
	
	private(set) var textElements: [TextElement]
	private(set) var footNotes: [FootNote]
	
	
	// COMPUTED PROPERTIES	----
	
	var content: [ParaContent]
	{
		var content = [ParaContent]()
		
		var nextTextIndex = 0
		for footNote in footNotes
		{
			// A text element is added before each foot note
			if textElements.count > nextTextIndex
			{
				content.add(textElements[nextTextIndex])
				nextTextIndex += 1
			}
			
			content.add(footNote)
		}
		
		// Adds the remaining text element(s)
		for i in nextTextIndex ..< textElements.count
		{
			content.add(textElements[i])
		}
		
		return content
	}
	
	var toUSX: String { return crossReferences.reduce("", { $0 + $1.toUSX }) + content.reduce("", { $0 + $1.toUSX }) }
	
	var properties: [String : PropertyValue] { return ["text": textElements.value, "notes": footNotes.value, "cross_references": crossReferences.value] }
	
	var text: String { return content.reduce("", { $0 + $1.text }) }
	
	
	// INIT	--------------------
	
	init()
	{
		self.textElements = [TextElement.empty()]
		self.footNotes = []
		self.crossReferences = []
	}
	
	init(text: String)
	{
		self.textElements = [TextElement(charData: [CharData(text: text)])]
		self.footNotes = []
		self.crossReferences = []
	}
	
	init(textElements: [TextElement], footNotes: [FootNote], crossReferences: [CrossReference] = [])
	{
		self.textElements = textElements
		self.footNotes = footNotes
		self.crossReferences = crossReferences
	}
	
	static func parse(from properties: PropertySet) -> TextWithNotes
	{
		return TextWithNotes(textElements: TextElement.parseArray(from: properties["text"].array(), using: TextElement.parse), footNotes: FootNote.parseArray(from: properties["notes"].array(), using: FootNote.parse), crossReferences: CrossReference.parseArray(from: properties["cross_references"].array(), using: CrossReference.parse))
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func toAttributedString(options: [String : Any]) -> NSAttributedString
	{
		let attStr = NSMutableAttributedString()
		content.forEach { attStr.append($0.toAttributedString(options: options)) }
		return attStr
	}
	
	func copy() -> TextWithNotes
	{
		return TextWithNotes(textElements: textElements.map { $0.copy() }, footNotes: footNotes.map { $0.copy() }, crossReferences: crossReferences)
	}
	
	
	// OPERATORS	-----------
	
	static func +(_ left: TextWithNotes, _ right: TextWithNotes) -> TextWithNotes
	{
		// The last text element of the left hand side is combined with the first text element on the right hand side so that there won't be two consecutive text elements
		var newTextElements = [TextElement]()
		
		if left.textElements.isEmpty
		{
			newTextElements = right.textElements.copy()
		}
		else if right.textElements.isEmpty
		{
			newTextElements = left.textElements.copy()
		}
		else
		{
			newTextElements.append(contentsOf: left.textElements.dropLast().map { $0.copy() })
			newTextElements.add(left.textElements.last! + right.textElements.first!)
			newTextElements.append(contentsOf: right.textElements.dropFirst().map { $0.copy() })
		}
		
		return TextWithNotes(textElements: newTextElements, footNotes: left.footNotes.copy() + right.footNotes.copy(), crossReferences: left.crossReferences + right.crossReferences)
	}
	
	
	// OTHER METHODS	-------
	
	func emptyCopy() -> TextWithNotes
	{
		return TextWithNotes(textElements: textElements.map { $0.emptyCopy() }, footNotes: footNotes.map { $0.emptyCopy() }, crossReferences: crossReferences.map { $0.emptyCopy() })
	}
	
	func contentEquals(with other: TextWithNotes) -> Bool
	{
		return textElements.contentEquals(with: other.textElements) && footNotes.contentEquals(with: other.footNotes) && crossReferences == other.crossReferences
	}
	
	func update(with attString: NSAttributedString) -> TextWithNotes?
	{
		// Finds all the notes markers from the string first
		var notesRanges = [(Int, Int)]() // Note start index, note end index
		var openStartIndex: Int?
		
		attString.enumerateAttribute(NoteMarkerAttributeName, in: NSMakeRange(0, attString.length), options: [])
		{
			isNoteStart, range, _ in
			
			if let isNoteStart = isNoteStart as? Bool
			{
				// The previous note must be ended before a new one can begin
				if isNoteStart
				{
					if openStartIndex == nil
					{
						openStartIndex = range.location
					}
				}
				else if let startIndex = openStartIndex
				{
					notesRanges.add((startIndex, range.location))
					openStartIndex = nil
				}
			}
		}
		
		let breakIndices = notesRanges.flatMap { [$0.0, $0.1] }
		
		// Parses the character data
		var charData = [[CharData]]()
		var textStartIndex = 0
		for breakIndex in breakIndices
		{
			charData.add(parseCharData(from: attString, range: NSMakeRange(textStartIndex, breakIndex - textStartIndex)))
			textStartIndex = breakIndex + 1
		}
		charData.add(parseCharData(from: attString, range: NSMakeRange(textStartIndex, attString.length - textStartIndex)))
		
		// Updates the content with the new data
		var content = self.content
		for i in 0 ..< content.count
		{
			if i < charData.count
			{
				content[i].charData = CharData.update(content[i].charData, with: charData[i])
			}
			else
			{
				break
			}
		}
		
		// If there was less data provided than what there were slots in this element, 
		// cuts the remaining elements and returns a new element based on that data
		if charData.count < content.count
		{
			// If the last included element was a footnote, adds an empty text data element to the end of this element
			if charData.count % 2 == 0
			{
				let splitIndex = charData.count / 2
				
				let cutElement = TextWithNotes(textElements: Array(textElements.dropFirst(splitIndex)), footNotes: Array(footNotes.dropFirst(splitIndex)))
				
				textElements = Array(textElements.prefix(splitIndex)) + TextElement.empty()
				footNotes = Array(footNotes.prefix(splitIndex))
				
				return cutElement
			}
			// If the last included element was text data, adds an empty text data element to the beginning of the generated element
			else
			{
				let noteSplitIndex = charData.count / 2
				let textSplitIndex = noteSplitIndex + 1
				
				let cutElement = TextWithNotes(textElements: TextElement.empty() + Array(textElements.dropFirst(textSplitIndex)), footNotes: Array(footNotes.dropFirst(noteSplitIndex)))
				
				textElements = Array(textElements.prefix(textSplitIndex))
				footNotes = Array(footNotes.prefix(noteSplitIndex))
				
				return cutElement
			}
		}
		
		// TODO: Handle cases where new chardata count is smaller than previous content count
		return nil
	}
	
	private func parseCharData(from attStr: NSAttributedString, range: NSRange) -> [CharData]
	{
		// Function for parsing character data from the provided usxString
		// The array will contain the parsed data. Should be emptied after each iteration.
		var parsedData = [CharData]()
		
		attStr.enumerateAttribute(CharStyleAttributeName, in: range, options: [])
		{
			style, range, _ in
			
			let text = (attStr.string as NSString).substring(with: range)
			let style = style as? CharStyle
			
			// If the consecutive chardata elements would have the same styling, they are appended to each other
			if let lastData = parsedData.last, lastData.style == style
			{
				parsedData[parsedData.count - 1] = CharData(text: lastData.text.appending(text), style: style)
			}
			else
			{
				parsedData.append(CharData(text: text, style: style))
			}
		}
		
		return parsedData
	}
}
