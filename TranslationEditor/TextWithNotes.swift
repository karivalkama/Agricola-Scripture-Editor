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
	
	// Whether all of this element contains text (doesn't require notes to contain any text)
	var isFilled: Bool { return textElements.forAll { !$0.isEmpty } }
	
	// Whether the element is completely empty of any text and doesn't contain a single note element
	var isEmpty: Bool { return textElements.forAll { $0.isEmpty } && footNotes.isEmpty && crossReferences.isEmpty }
	
	// Whether this element contains any notes (empty or not)
	var containsNotes: Bool { return !crossReferences.isEmpty || !footNotes.isEmpty }
	
	
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
		return TextWithNotes(textElements: textElements.map { $0.emptyCopy() }, footNotes: footNotes.map { $0.emptyCopy() }, crossReferences: crossReferences)
	}
	
	func contentEquals(with other: TextWithNotes) -> Bool
	{
		/*
		print("STATUS: Comparing two texts: '\(text)' and '\(other.text)'")
		print("STATUS: Text elements are equal: \(textElements.contentEquals(with: other.textElements))")
		print("STATUS: Footnotes are equal: \(footNotes.contentEquals(with: other.footNotes))")
		print("STATUS: Cross references are equal: \(crossReferences == other.crossReferences)")
		*/
		return textElements.contentEquals(with: other.textElements) && footNotes.contentEquals(with: other.footNotes) && crossReferences == other.crossReferences
	}
	
	func clearText()
	{
		textElements.forEach { $0.charData = [] }
		footNotes.forEach { $0.charData = [] }
	}
	
	func update(with attString: NSAttributedString, cutOutCrossReferencesOutside rangeLimit: VerseRange? = nil) -> TextWithNotes?
	{
		// Finds all the notes markers from the string first
		var notesRanges = [(startMarker: NSRange, endMarker: NSRange)]() // Note start range, note end range
		var openStartMarker: NSRange?
		
		attString.enumerateAttribute(NoteMarkerAttributeName, in: NSMakeRange(0, attString.length), options: [])
		{
			isNoteStart, range, _ in
			
			if let isNoteStart = isNoteStart as? Bool
			{
				// The previous note must be ended before a new one can begin
				if isNoteStart
				{
					if openStartMarker == nil
					{
						openStartMarker = range
					}
				}
				else if let startMarker = openStartMarker
				{
					notesRanges.add((startMarker: startMarker, endMarker: range))
					openStartMarker = nil
				}
			}
		}
		
		let breakMarkers = notesRanges.flatMap { [$0.startMarker, $0.endMarker] }
		
		// Parses the character data
		var charData = [[CharData]]()
		var textStartIndex = 0
		for breakMarker in breakMarkers
		{
			charData.add(parseCharData(from: attString, range: NSMakeRange(textStartIndex, breakMarker.location - textStartIndex)))
			textStartIndex = breakMarker.location + breakMarker.length
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
		
		// Finds out which cross references to keep and which to cut
		var cutCrossReferences: [CrossReference]?
		if let rangeLimit = rangeLimit
		{
			cutCrossReferences = crossReferences.filter { $0.originVerseIndex != nil && !rangeLimit.contains(index: $0.originVerseIndex!) }
			crossReferences = crossReferences - cutCrossReferences!
		}
		
		// If there was less data provided than what there were slots in this element, 
		// cuts the remaining elements and returns a new element based on that data
		if charData.count < content.count
		{
			// TODO: Distribute cross reference instances between the two parts
			
			// If the last included element was a footnote, adds an empty text data element to the end of this element
			if charData.count % 2 == 0
			{
				let splitIndex = charData.count / 2
				
				let cutElement = TextWithNotes(textElements: Array(textElements.dropFirst(splitIndex)), footNotes: Array(footNotes.dropFirst(splitIndex)), crossReferences: cutCrossReferences ?? [])
				
				textElements = Array(textElements.prefix(splitIndex)) + TextElement.empty()
				footNotes = Array(footNotes.prefix(splitIndex))
				
				return cutElement
			}
			// If the last included element was text data, adds an empty text data element to the beginning of the generated element
			else
			{
				let noteSplitIndex = charData.count / 2
				let textSplitIndex = noteSplitIndex + 1
				
				let cutElement = TextWithNotes(textElements: TextElement.empty() + Array(textElements.dropFirst(textSplitIndex)), footNotes: Array(footNotes.dropFirst(noteSplitIndex)), crossReferences: cutCrossReferences ?? [])
				
				textElements = Array(textElements.prefix(textSplitIndex))
				footNotes = Array(footNotes.prefix(noteSplitIndex))
				
				return cutElement
			}
		}
		
		// TODO: Handle cases where new chardata count is smaller than previous content count
		if let cutCrossReferences = cutCrossReferences
		{
			return TextWithNotes(textElements: [TextElement.empty()], footNotes: [], crossReferences: cutCrossReferences)
		}
		else
		{
			return nil
		}
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
