//
//  ParagraphEdit.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These instances are used for storing and accessing temporary edit status of a paragraph
final class ParagraphEdit: Storable
{
	// PROPERTIES	---------
	
	static let type = "edit"
	
	static let PROPERTY_BOOK_ID = "book_id"
	static let PROPERTY_CHAPTER_INDEX = "chapter_index"
	static let PROPERTY_USER_ID = "creator_user"
	
	let bookId: String
	let chapterIndex: Int
	let userId: String
	let created: TimeInterval
	
	// Key = paragraph id, value = paragraph
	var edits: [String : Paragraph]
	
	
	// COMP. PROPERTIES	-----
	
	static var idIndexMap: IdIndexMap
	{
		return Book.idIndexMap.makeChildPath(parentPathName: PROPERTY_BOOK_ID, childPath: [PROPERTY_CHAPTER_INDEX, PROPERTY_USER_ID])
	}
	
	var idProperties: [Any] {return [bookId, "edit", chapterIndex, userId]}
	
	var properties: [String : PropertyValue]
	{
		return ["created" : PropertyValue(created), "edits" : PropertyValue(PropertySet(edits))]
	}
	
	
	// INIT	-----------------
	
	init(bookId: String, chapterIndex: Int, userId: String, edits: [String : Paragraph], created: Double = Date().timeIntervalSince1970)
	{
		self.bookId = bookId
		self.chapterIndex = chapterIndex
		self.userId = userId
		self.edits = edits
		self.created = created
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> ParagraphEdit
	{
		// Parses the edit data
		let editSet = properties["edits"].object()
		var edit = [String : Paragraph]()
		
		for (paragraphId, paragraphData) in editSet.properties
		{
			edit[paragraphId] = try Paragraph.create(from: paragraphData.object(), withId: Paragraph.createId(from: paragraphId))
		}
		
		return ParagraphEdit(bookId: id[ParagraphEdit.PROPERTY_BOOK_ID].string(), chapterIndex: id[ParagraphEdit.PROPERTY_CHAPTER_INDEX].int(), userId: id[ParagraphEdit.PROPERTY_USER_ID].string(), edits: edit, created: properties["created"].time())
	}
	
	
	// STORABLE	-------------
	
	func update(with properties: PropertySet) throws
	{
		if let editData = properties["edits"].object
		{
			edits = [:]
			for (paragraphId, paragraphData) in editData.properties
			{
				edits[paragraphId] = try Paragraph.create(from: paragraphData.object(), withId: Paragraph.createId(from: paragraphId))
			}
		}
	}
	
	
	// OTHER	------------
	
	static func bookId(fromId idString: String) -> String
	{
		return property(withName: PROPERTY_BOOK_ID, fromId: idString).string()
	}
	
	static func chapterIndex(fromId idString: String) -> Int
	{
		return property(withName: PROPERTY_CHAPTER_INDEX, fromId: idString).int()
	}
	
	static func userId(fromId idString: String) -> String
	{
		return property(withName: PROPERTY_USER_ID, fromId: idString).string()
	}
}
