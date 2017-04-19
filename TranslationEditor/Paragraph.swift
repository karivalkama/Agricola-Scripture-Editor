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
final class Paragraph: AttributedStringConvertible, PotentialVerseRangeable, Storable, Copyable
{
	// ATTRIBUTES	---------
	
	// Attributed string conversion option that defines whether paragraph ranges are displayed at paragraph starts. Default true
	static let optionDisplayParagraphRange = "displayParagraphRange"
	
	static let PROPERTY_BOOK_ID = "bookid"
	static let PROPERTY_CHAPTER_INDEX = "chapter_index"
	static let PROPERTY_PATH_ID = "path_id"
	static let PROPERTY_CREATED = "paragraph_created"
	
	static let type = "paragraph"
	
	let bookId: String
	let pathId: String
	
	let chapterIndex: Int
	let sectionIndex: Int
	let index: Int
	
	private(set) var created = Date().timeIntervalSince1970
	private(set) var creatorId: String
	private(set) var createdFrom: String?
	
	var content: [Para]
	var isDeprecated = false
	var isMostRecent = true
	
	
	// COMP. PROPERTIES	-----
	
	var idProperties: [Any] {return [bookId, chapterIndex, pathId, created]}
	
	var properties: [String : PropertyValue] {return [
		"paras" : content.value,
		"section" : sectionIndex.value,
		"index" : index.value,
		"creator" : creatorId.value,
		"created_from" : createdFrom.value,
		"deprecated" : isDeprecated.value,
		"most_recent" : isMostRecent.value]}
	
	var range: VerseRange?
	{
		return Paragraph.range(of: content)
	}
	
	// Whether this is the first paragraph in the chapter
	var isFirstInChapter: Bool {return sectionIndex == 1 && index == 1}
	
	// The code of the book this paragraph belongs to
	var bookCode: BookCode { return Book.code(fromId: bookId) }
	
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
	
	static var idIndexMap: IdIndexMap
	{
		return Book.idIndexMap.makeChildPath(parentPathName: PROPERTY_BOOK_ID, childPath: [PROPERTY_CHAPTER_INDEX, PROPERTY_PATH_ID, PROPERTY_CREATED])
	}
	
	
	// INIT	-----------------
	
	init(
		bookId: String, chapterIndex: Int, sectionIndex: Int, index: Int,
		content: [Para], creatorId: String,
		createdFrom: String? = nil, pathId: String = UUID().uuidString.lowercased(),
		created: TimeInterval = Date().timeIntervalSince1970, mostRecent: Bool = true, deprecated: Bool = false)
	{
		self.pathId = pathId
		self.bookId = bookId
		self.chapterIndex = chapterIndex
		self.content = content
		self.sectionIndex = sectionIndex
		self.index = index
		self.created = created
		self.creatorId = creatorId
		self.createdFrom = createdFrom
		self.isDeprecated = deprecated
		self.isMostRecent = mostRecent
	}
	
	func copy() -> Paragraph
	{
		return Paragraph(
			bookId: bookId, chapterIndex: chapterIndex, sectionIndex: sectionIndex, index: index,
			content: content.copy(), creatorId: creatorId,
			createdFrom: createdFrom, pathId: pathId,
			created: created, mostRecent: isMostRecent, deprecated: isDeprecated)
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> Paragraph
	{
		return try Paragraph(
			bookId: id[PROPERTY_BOOK_ID].string(), chapterIndex: id[PROPERTY_CHAPTER_INDEX].int(), sectionIndex: properties["section"].int(or: 1), index: properties["index"].int(),
			content: Para.parseArray(from: properties["paras"].array(), using: Para.parse), creatorId: properties["creator"].string(),
			createdFrom: properties["created_from"].string, pathId: id[PROPERTY_PATH_ID].string(),
			created: id[PROPERTY_CREATED].time(), mostRecent: properties["most_recent"].bool(or: true), deprecated: properties["deprecated"].bool(or: false))
	}
	
	
	// IMPLEMENTED METHODS	--
	
	func update(with properties: PropertySet) throws
	{
		if let paras = properties["paras"].array
		{
			content = try Para.parseArray(from: paras, using: Para.parse)
		}
		if let deprecated = properties["deprecated"].bool
		{
			self.isDeprecated = deprecated
		}
		if let mostRecent = properties["most_recent"].bool
		{
			self.isMostRecent = mostRecent
		}
		if let createdFrom = properties["createdFrom"].string
		{
			self.createdFrom = createdFrom
		}
		if let creatorId = properties["creator"].string
		{
			self.creatorId = creatorId
		}
	}
	
	
	// OTHER METHODS	-----
	
	// Deprecates the paragraph's history until a specific instance
	// If whole history should be deprecated, please use paragraphHistoryView instead
	func deprecateWithHistory(until versionId: String) throws
	{
		if idString != versionId
		{
			// Deprecates this paragraph as well as any previous version
			isDeprecated = true
			try pushProperties(named: ["deprecated"])
			
			if let previousVersionId = createdFrom, let previousVersion = try Paragraph.get(previousVersionId)
			{
				try previousVersion.deprecateWithHistory(until: versionId)
			}
		}
	}
	
	// Finds the latest version (going back only) of this paragraph that was created at or before the provided time limit (inclusive)
	func latestVersionBefore(_ timeLimit: TimeInterval) throws -> Paragraph?
	{
		// If this paragraph was created before, it will suffice
		if created <= timeLimit
		{
			return self
		}
		// Otherwise, if this paragraph has a history, searches that using recursion
		else if let createdFrom = createdFrom, let lastVersion = try Paragraph.get(createdFrom)
		{
			return try lastVersion.latestVersionBefore(timeLimit)
		}
		// It is possible there is no sufficient version available
		else
		{
			return nil
		}
	}
	
	// Creates a new version of this paragraph and saves it to the database
	// Returns the created commit version (or this version if no changes were made)
	// Parameters content and text are mutually exclusive
	func commit(userId: String, chapterIndex: Int? = nil, sectionIndex: Int? = nil, paragraphIndex: Int? = nil, content: [Para]? = nil, text: NSAttributedString? = nil) throws -> Paragraph
	{
		let content = content.or(text == nil ? self.content.copy() : [])
		
		let newVersion = Paragraph(
			bookId: bookId, chapterIndex: chapterIndex.or(self.chapterIndex), sectionIndex: sectionIndex.or(self.sectionIndex), index: paragraphIndex.or(self.index),
			content: content, creatorId: userId,
			createdFrom: idString, pathId: pathId)
		
		if let text = text
		{
			newVersion.replaceContents(with: text)
		}
		
		// Only saves changes if there were any
		if newVersion.chapterIndex != self.chapterIndex || newVersion.sectionIndex != self.sectionIndex || newVersion.index != self.index || !paraContentsEqual(with: newVersion)
		{
			try newVersion.push()
			
			// This version is no longer the most recent out there
			isMostRecent = false
			try pushProperties(named: ["most_recent"])
			
			return newVersion
		}
		else
		{
			return self
		}
	}
	
	// Creates a copy of this paragraph that has no content (layout and index are preserved)
	// The book, uid, creator and created values are also different
	func emptyCopy(forBook bookId: String, creatorId: String) -> Paragraph
	{
		return Paragraph(bookId: bookId, chapterIndex: chapterIndex, sectionIndex: sectionIndex, index: index, content: content.map { $0.emptyCopy() }, creatorId: creatorId)
	}
	
	// Display paragraph range option available
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
	
	func paraContentsEqual(with other: Paragraph) -> Bool
	{
		if content.count == other.content.count
		{
			for i in 0 ..< content.count
			{
				if !content[i].contentEquals(with: other.content[i])
				{
					return false
				}
			}
			
			return true
		}
		else
		{
			return false
		}
	}
	
	// Marks each of the provided ids as deprecated
	static func deprecate(ids: [String]) throws
	{
		try DATABASE.tryTransaction
		{
			try ids.forEach { try pushProperties(["deprecated" : PropertyValue(true)], forId: $0) }
		}
	}
	
	// Creates a new id that combines the provided data
	/*
	static func createId(bookId: String, chapterIndex: Int, pathId: String, created: TimeInterval) -> Id
	{
		return createId(from: parseId(from: [bookId, chapterIndex, pathId, created]))
	}*/
	
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
	
	// Finds the path id from a paragraph id string
	static func pathId(fromId paragraphIdString: String) -> String
	{
		return createId(from: paragraphIdString)[PROPERTY_PATH_ID].string()
	}
	
	// Finds the paragraph creation time from a paragraph id string
	static func created(fromId paragraphIdString: String) -> TimeInterval
	{
		return createId(from: paragraphIdString)[PROPERTY_CREATED].time()
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
				}
				
				lastRangeStart = range.location + range.length
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
