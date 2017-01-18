//
//  NotesThread.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Notes threads are topics for different conversations about a certaing paragraph and its translation
final class NotesThread: Storable
{
	// ATTRIBUTES	-----------
	
	static let PROPERTY_NOTE = "note"
	
	static let type = "thread"
	
	let uid: String
	
	let noteId: String
	let creatorId: String
	let created: TimeInterval
	
	var resolved: Bool
	var name: String
	
	
	// COMP. PROPERTIES	-------
	
	static var idIndexMap: [String : IdIndex]
	{
		let noteMap = ParagraphNotes.idIndexMap
		let noteIndex = IdIndex.of(indexMap: noteMap)
		
		return noteMap + [PROPERTY_NOTE: noteIndex, "thread_uid": noteIndex + 1]
	}
	
	var idProperties: [Any] { return [noteId, uid] }
	var properties: [String : PropertyValue]
	{
		return ["creator": PropertyValue(creatorId), "created": PropertyValue(created), "resolved": PropertyValue(resolved), "name": PropertyValue(name)]
	}
	
	var collectionId: String { return ParagraphNotes.collectionId(fromId: noteId) }
	var chapterIndex: Int { return ParagraphNotes.chapterIndex(fromId: noteId) }
	
	
	// INIT	-------------------
	
	init(noteId: String, creatorId: String, name: String, resolved: Bool = false, uid: String = UUID().uuidString.lowercased(), created: TimeInterval = Date().timeIntervalSince1970)
	{
		self.uid = uid
		self.noteId = noteId
		self.creatorId = creatorId
		self.created = created
		self.resolved = resolved
		self.name = name
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> NotesThread
	{
		return NotesThread(noteId: id[PROPERTY_NOTE].string(), creatorId: properties["creator"].string(), name: properties["name"].string(), resolved: properties["resolved"].bool(), uid: id["thread_uid"].string(), created: properties["created"].time())
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func update(with properties: PropertySet)
	{
		if let resolved = properties["resolved"].bool
		{
			self.resolved = resolved
		}
		if let name = properties["name"].string
		{
			self.name = name
		}
	}


	// OTHER METHODS	--------

	static func noteId(from idString: String) -> String
	{
		return property(withName: PROPERTY_NOTE, fromId: idString).string()
	}
}
