//
//  ParagraphNotes.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This instance ties together all notes threads for a single paragraph (path)
final class ParagraphNotes: Storable
{
	// ATTRIBUTES	---------
	
	static let PROPERTY_COLLECTION = "collection"
	static let PROPERTY_CHAPTER = "chapter"
	static let PROPERTY_UID = "notes_uid"
	
	static let type = "paragraph_notes"
	
	let uid: String
	let collectionId: String
	let chapterIndex: Int
	
	var pathId: String
	
	
	// COMP. PROPERTIES	-----
	
	static var idIndexMap: IdIndexMap
	{
		return ResourceCollection.idIndexMap.makeChildPath(parentPathName: PROPERTY_COLLECTION, childPath: [PROPERTY_CHAPTER, PROPERTY_UID])
	}
	
	var idProperties: [Any] { return [collectionId, chapterIndex, uid] }
	var properties: [String : PropertyValue]
	{
		return ["path_id": PropertyValue(pathId)]
	}
	
	
	// INIT	-----------------
	
	init(collectionId: String, chapterIndex: Int, pathId: String, uid: String = UUID().uuidString.lowercased())
	{
		self.collectionId = collectionId
		self.chapterIndex = chapterIndex
		self.pathId = pathId
		self.uid = uid
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> ParagraphNotes
	{
		return ParagraphNotes(collectionId: id[PROPERTY_COLLECTION].string(), chapterIndex: id[PROPERTY_CHAPTER].int(), pathId: properties["path_id"].string(), uid: id[PROPERTY_UID].string())
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func update(with properties: PropertySet)
	{
		if let pathId = properties["pathId"].string
		{
			self.pathId = pathId
		}
	}
	
	
	// OTHER METHODS	------
	
	static func collectionId(fromId idString: String) -> String
	{
		return property(withName: PROPERTY_COLLECTION, fromId: idString).string()
	}
	
	static func chapterIndex(fromId idString: String) -> Int
	{
		return property(withName: PROPERTY_CHAPTER, fromId: idString).int()
	}
	
	static func uid(fromId idString: String) -> String
	{
		return property(withName: PROPERTY_UID, fromId: idString).string()
	}
	
	static func makeId(collectionId: String, chapterIndex: Int, uid: String) -> String
	{
		return parseId(from: [collectionId, chapterIndex, uid])
	}
}
