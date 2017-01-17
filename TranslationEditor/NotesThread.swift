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
	
	static let type = "thread"
	static let PROPERTY_CREATED = "created"
	
	static let idIndexMap = ["thread_uid": IdIndex(0), PROPERTY_CREATED: IdIndex(1)]
	
	let uid: String
	
	let noteId: String
	let creatorId: String
	let created: TimeInterval
	
	var resolved: Bool
	var name: String
	
	
	// COMP. PROPERTIES	-------
	
	var idProperties: [Any] { return [uid, created] }
	var properties: [String : PropertyValue]
	{
		return ["note": PropertyValue(noteId), "creator": PropertyValue(creatorId), "created": PropertyValue(created), "resolved": PropertyValue(resolved), "name": PropertyValue(name)]
	}
	
	
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
		return NotesThread(noteId: properties["note"].string(), creatorId: properties["creator"].string(), name: properties["name"].string(), resolved: properties["resolved"].bool(), uid: id["thread_uid"].string(), created: id[PROPERTY_CREATED].time())
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
}
