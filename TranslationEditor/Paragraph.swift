//
//  Paragraph.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Paragraph are used as the base translation units
// A paragraph contains certain text range, and has some resources associated with it
final class Paragraph: AttributedStringConvertible, PotentialVerseRangeable, Storable
{
	// ATTRIBUTES	---------
	
	// Attributed string conversion option that defines whether paragraph ranges are displayed at paragraph starts. Default true
	static let optionDisplayParagraphRange = "displayParagraphRange"
	
	static let PROPERTY_BOOK_ID = "bookid"
	static let PROPERTY_PARAGRAPH_INDEX = "paragraphindex"
	static let PROPERTY_CHAPTER_INDEX = "chapterindex"
	
	static let TYPE = "paragraph"
	
	let bookId: String
	let chapterIndex: Int
	let paragraphIndex: Int
	
	var content: [Para]
	
	
	// COMP. PROPERTIES	-----
	
	var idProperties: [Any] {return [bookId, chapterIndex, paragraphIndex]}
	
	var properties: [String : PropertyValue] {return [PROPERTY_TYPE : PropertyValue(Paragraph.TYPE), "paras" : PropertyValue(content), "first_verse_marker" : PropertyValue(range?.firstVerseMarker), "last_verse_marker" : PropertyValue(range?.lastVerseMarker)]}
	
	var range: VerseRange?
	{
		return Paragraph.range(of: content)
	}
	
	// Whether this is the first paragraph in the chapter
	var isFirstInChapter: Bool {return paragraphIndex == 1}
	
	// The code of the book this paragraph belongs to
	var bookCode: String {return Book.code(fromId: bookId)}
	
	var text: String
	{
		var text = ""
		for i in 0 ..< content.count
		{
			if i != 0
			{
				text.append("\n")
			}
			text.append(content[i].text)
		}
		
		return text
	}
	
	static var idIndexMap: [String : IdIndex] {return Book.idIndexMap + [PROPERTY_BOOK_ID : IdIndex(0, 2), PROPERTY_CHAPTER_INDEX : IdIndex(2), PROPERTY_PARAGRAPH_INDEX : IdIndex(3)]}
	
	
	// INIT	-----------------
	
	init(bookId: String, chapterIndex: Int, paragraphIndex: Int, content: [Para])
	{
		self.bookId = bookId
		self.chapterIndex = chapterIndex
		self.paragraphIndex = paragraphIndex
		self.content = content
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> Paragraph
	{
		return try Paragraph(bookId: id[PROPERTY_BOOK_ID].string(), chapterIndex: id[PROPERTY_CHAPTER_INDEX].int(), paragraphIndex: id[PROPERTY_PARAGRAPH_INDEX].int(), content: Para.parseArray(from: properties["paras"].array(), using: Para.parse))
	}
	
	
	// IMPLEMENTED METHODS	--
	
	func update(with properties: PropertySet) throws
	{
		if let paras = properties["paras"].array
		{
			content = try Para.parseArray(from: paras, using: Para.parse)
		}
	}
	
	
	// OTHER METHODS	-----
	
	func toAttributedString(options: [String : Any]) -> NSAttributedString
	{
		let str = NSMutableAttributedString()
		
		var displayParagraphRange = true
		if let displayRangeOption = options[Paragraph.optionDisplayParagraphRange] as? Bool
		{
			displayParagraphRange = displayRangeOption
		}
		
		for para in content
		{
			// Paras other than the first are indicated with a newline character
			var paraIdentifier = "\n"
			
			// Parses the style information for the first para element
			// At this point the paragraph range is used to mark the start. Replace with a better solution when possible
			if str.length == 0
			{
				if isFirstInChapter
				{
					paraIdentifier = "\(chapterIndex). "
				}
				else
				{
					if let range = range, displayParagraphRange
					{
						paraIdentifier = range.simpleName + ". "
					}
					else
					{
						paraIdentifier = " "
					}
				}
			}
			
			
			var attributes = [ParaStyleAttributeName : para.style] as [String : Any]
			if isFirstInChapter
			{
				attributes[ChapterMarkerAttributeName] = chapterIndex
				attributes[VerseIndexMarkerAttributeName] = 1
			}
			attributes[ParaMarkerAttributeName] = para.style
			
			let paraMarker = NSAttributedString(string: paraIdentifier, attributes: attributes)
			str.append(paraMarker)
			
			// Adds para contents
			str.append(para.toAttributedString(options: options))
			
		}
		
		return str
	}
	
	func replaceContents(with usxString: NSAttributedString)
	{
		// Deletes previous content
		self.content = []
		
		// Parses the para content ranges and generates the para elements
		let paraRanges = parseParaRanges(from: usxString)
		for (style, contentRange) in paraRanges
		{
			content.append(Para(content: usxString.attributedSubstring(from: contentRange), style: style))
		}
	}
	
	// Finds the book id from a paragraph id string
	static func bookId(fromId paragraphIdString: String) -> String
	{
		return createId(from: paragraphIdString)[PROPERTY_BOOK_ID].string()
	}
	
	// Finds the chapter index from a paragraph id string
	static func chapterIndex(fromId paragraphIdString: String) -> Int
	{
		return createId(from: paragraphIdString)[PROPERTY_CHAPTER_INDEX].int()
	}
	
	// Finds the paragraph index from a paragraph id string
	static func paragraphIndex(fromId paragraphIdString: String) -> Int
	{
		return createId(from: paragraphIdString)[PROPERTY_PARAGRAPH_INDEX].int()
	}
	
	private func parseParaRanges(from usxString: NSAttributedString) -> [(ParaStyle, NSRange)]
	{
		// Enumerates through the paramarker attribute values and collects each range for style
		var parsedRanges = [(ParaStyle, NSRange)]()
		var lastStyle: ParaStyle?
		var lastRangeStart = 0
		
		usxString.enumerateAttribute(ParaMarkerAttributeName, in: NSMakeRange(0, usxString.length), options: [])
		{
			value, range, _ in
			
			// If a new para marker is found, the last range is parsed and new one begins
			if let style = value as? ParaStyle
			{
				if let lastStyle = lastStyle
				{
					parsedRanges.append((lastStyle, NSMakeRange(lastRangeStart, range.location - lastRangeStart)))
					lastRangeStart = range.location + range.length
				}
				
				lastStyle = style
			}
		}
		// Appends the last para range as well
		if let style = lastStyle
		{
			parsedRanges.append((style, NSMakeRange(lastRangeStart, usxString.length - lastRangeStart)))
		}
		
		return parsedRanges
	}
}
