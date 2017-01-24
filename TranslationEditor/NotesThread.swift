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
	static let PROPERTY_CREATED = "created"
	
	static let type = "thread"
	
	let noteId: String
	let creatorId: String
	let created: TimeInterval
	
	var isResolved: Bool
	var name: String
	var targetVerseIndex: VerseIndex?
	
	
	// COMP. PROPERTIES	-------
	
	static var idIndexMap: [String : IdIndex]
	{
		let noteMap = ParagraphNotes.idIndexMap
		let noteIndex = IdIndex.of(indexMap: noteMap)
		
		return noteMap + [PROPERTY_NOTE: noteIndex, PROPERTY_CREATED: noteIndex + 1]
	}
	
	var idProperties: [Any] { return [noteId, created] }
	var properties: [String : PropertyValue]
	{
		return ["creator": PropertyValue(creatorId), "resolved": PropertyValue(isResolved), "name": PropertyValue(name), "verse": PropertyValue(targetVerseIndex)]
	}
	
	var collectionId: String { return ParagraphNotes.collectionId(fromId: noteId) }
	var chapterIndex: Int { return ParagraphNotes.chapterIndex(fromId: noteId) }
	
	
	// INIT	-------------------
	
	init(noteId: String, creatorId: String, name: String, targetVerseIndex: VerseIndex? = nil, resolved: Bool = false, created: TimeInterval = Date().timeIntervalSince1970)
	{
		self.noteId = noteId
		self.creatorId = creatorId
		self.created = created
		self.isResolved = resolved
		self.name = name
		self.targetVerseIndex = targetVerseIndex
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> NotesThread
	{
		let verseIndexData = properties["verse"].object
		let verseIndex = verseIndexData == nil ? nil : try VerseIndex.parse(from: verseIndexData!)
		
		return NotesThread(noteId: id[PROPERTY_NOTE].string(), creatorId: properties["creator"].string(), name: properties["name"].string(), targetVerseIndex: verseIndex, resolved: properties["resolved"].bool(), created: id[PROPERTY_CREATED].time())
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func update(with properties: PropertySet)
	{
		if let resolved = properties["resolved"].bool
		{
			self.isResolved = resolved
		}
		if let name = properties["name"].string
		{
			self.name = name
		}
	}


	// OTHER METHODS	--------

	// Marks the thread as resolved, if it isn't already. Saves the changes to the database
	func resolve() throws
	{
		if !isResolved
		{
			isResolved = true
			try pushProperties(named: ["resolved"])
		}
	}
	
	static func noteId(fromId idString: String) -> String
	{
		return property(withName: PROPERTY_NOTE, fromId: idString).string()
	}
	
	static func created(fromId idString: String) -> TimeInterval
	{
		return property(withName: PROPERTY_CREATED, fromId: idString).time()
	}
	
	static func makeId(noteId: String, created: TimeInterval) -> String
	{
		return parseId(from: [noteId, created])
	}
}
