//
//  TextWithFootnotes.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 25.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This element contains both text element and footnote data
// The elements are ordered in a very specific way
final class TextWithFootnotes: USXConvertible, JSONConvertible, AttributedStringConvertible, Copyable
{
	// ATTRIBUTES	------------
	
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
	
	var toUSX: String { return content.reduce("", { $0 + $1.toUSX }) }
	
	var properties: [String : PropertyValue] { return ["text": textElements.value, "notes": footNotes.value] }
	
	
	// INIT	--------------------
	
	init()
	{
		self.textElements = []
		self.footNotes = []
	}
	
	private init(textElements: [TextElement], footNotes: [FootNote])
	{
		self.textElements = textElements
		self.footNotes = footNotes
	}
	
	static func parse(from properties: PropertySet) -> TextWithFootnotes
	{
		return TextWithFootnotes(textElements: TextElement.parseArray(from: properties["text"].array(), using: TextElement.parse), footNotes: FootNote.parseArray(from: properties["notes"].array(), using: FootNote.parse))
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func toAttributedString(options: [String : Any]) -> NSAttributedString
	{
		let attStr = NSMutableAttributedString()
		content.forEach { attStr.append($0.toAttributedString(options: options)) }
		return attStr
	}
	
	func copy() -> TextWithFootnotes
	{
		return TextWithFootnotes(textElements: textElements.map { $0.copy() }, footNotes: footNotes.map { $0.copy() })
	}
	
	
	// OTHER METHODS	-------
	
	func emptyCopy() -> TextWithFootnotes
	{
		return TextWithFootnotes(textElements: textElements.map { $0.emptyCopy() }, footNotes: footNotes.map { $0.emptyCopy() })
	}
	
	func update(with attString: NSAttributedString)
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
			textStartIndex = breakIndex
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
