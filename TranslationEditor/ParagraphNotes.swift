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
	
	static let type = "paragraph_notes"
	static let idIndexMap = ["pnote_uid": IdIndex(0)]
	
	let uid: String
	
	let collectionId: String
	let chapterIndex: Int
	
	var pathId: String
	
	
	// COMP. PROPERTIES	-----
	
	var idProperties: [Any] { return [uid] }
	var properties: [String : PropertyValue]
	{
		return ["collection": PropertyValue(collectionId), "chapter": PropertyValue(chapterIndex), "path_id": PropertyValue(pathId)]
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
		return ParagraphNotes(collectionId: properties["collection"].string(), chapterIndex: properties["chapter"].int(), pathId: properties["path_id"].string(), uid: id["pnote_uid"].string())
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func update(with properties: PropertySet)
	{
		if let pathId = properties["pathId"].string
		{
			self.pathId = pathId
		}
	}
}
