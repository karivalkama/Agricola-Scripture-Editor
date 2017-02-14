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
	let originalTargetParagraphId: String
	
	var isResolved: Bool
	var name: String
	var targetVerseIndex: VerseIndex?
	var tags: [String]
	
	
	// COMP. PROPERTIES	-------
	
	static var idIndexMap: IdIndexMap
	{
		return ParagraphNotes.idIndexMap.makeChildPath(parentPathName: PROPERTY_NOTE, childPath: [PROPERTY_CREATED])
	}
	
	var idProperties: [Any] { return [noteId, created] }
	var properties: [String : PropertyValue]
	{
		return ["creator": creatorId.value, "resolved": isResolved.value, "name": name.value, "verse": targetVerseIndex.value, "tags": tags.value, "original_paragraph": originalTargetParagraphId.value]
	}
	
	var collectionId: String { return ParagraphNotes.collectionId(fromId: noteId) }
	var chapterIndex: Int { return ParagraphNotes.chapterIndex(fromId: noteId) }
	
	
	// INIT	-------------------
	
	init(noteId: String, creatorId: String, name: String, targetParagraphId: String, targetVerseIndex: VerseIndex? = nil, tags: [String] = [], resolved: Bool = false, created: TimeInterval = Date().timeIntervalSince1970)
	{
		self.noteId = noteId
		self.creatorId = creatorId
		self.created = created
		self.isResolved = resolved
		self.name = name
		self.targetVerseIndex = targetVerseIndex
		self.tags = tags
		self.originalTargetParagraphId = targetParagraphId
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> NotesThread
	{
		let verseIndexData = properties["verse"].object
		let verseIndex = verseIndexData == nil ? nil : try VerseIndex.parse(from: verseIndexData!)
		
		return NotesThread(noteId: id[PROPERTY_NOTE].string(), creatorId: properties["creator"].string(), name: properties["name"].string(), targetParagraphId: properties["original_paragraph"].string(), targetVerseIndex: verseIndex, tags: properties["tags"].array { $0.string }, resolved: properties["resolved"].bool(), created: id[PROPERTY_CREATED].time())
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func update(with properties: PropertySet) throws
	{
		if let resolved = properties["resolved"].bool
		{
			self.isResolved = resolved
		}
		if let name = properties["name"].string
		{
			self.name = name
		}
		if let indexData = properties["verse"].object
		{
			self.targetVerseIndex = try VerseIndex.parse(from: indexData)
		}
		if let tags = properties["tags"].array
		{
			self.tags = tags.flatMap { $0.string }
		}
	}


	// OTHER METHODS	--------

	// Sets a new resolved status for the thread. Saves the changes to the database
	func setResolved(_ resolved: Bool) throws
	{
		if isResolved != resolved
		{
			isResolved = resolved
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
