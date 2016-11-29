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
	static let PROPERTY_CHAPTER_ID = "chapterid"
	static let PROPERTY_PARAGRAPH_INDEX = "paragraphindex"
	static let TYPE = "paragraph"
	
	let chapterId: String
	let paragraphIndex: Int
	
	var content: [Para]
	
	
	// COMP. PROPERTIES	-----
	
	var idProperties: [Any] {return [chapterId, paragraphIndex]}
	
	var properties: [String : PropertyValue] {return [PROPERTY_TYPE : PropertyValue(Paragraph.TYPE), "paras" : PropertyValue(content), "first_verse_marker" : PropertyValue(range?.firstVerseMarker), "last_verse_marker" : PropertyValue(range?.lastVerseMarker)]}
	
	var range: VerseRange?
	{
		return Paragraph.range(of: content)
	}
	
	var chapterIndex: Int {return Chapter.chapterIndex(fromId: chapterId)}
	var bookId: String {return Chapter.bookId(fromId: chapterId)}
	
	var isFirstInChapter: Bool {return paragraphIndex == 1}
	
	static var idIndexMap: [String : IdIndex] {return Chapter.idIndexMap + [PROPERTY_CHAPTER_ID : IdIndex(0, 3),  PROPERTY_PARAGRAPH_INDEX : IdIndex(3)]}
	
	
	// INIT	-----------------
	
	init(chapterId: String, index: Int, content: [Para])
	{
		self.chapterId = chapterId
		self.paragraphIndex = index
		self.content = content
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> Paragraph
	{
		return try Paragraph(chapterId: id[PROPERTY_CHAPTER_ID].string(), index: id[PROPERTY_PARAGRAPH_INDEX].int(), content: Para.parseArray(from: properties["paras"].array(), using: Para.parse))
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
