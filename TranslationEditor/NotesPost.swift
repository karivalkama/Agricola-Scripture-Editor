//
//  NotesPost.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A single post is one persons contribution to a certain notes thread
final class NotesPost: Storable
{
	// ATTRIBUTES	------------
	
	static let type = "post"
	
	static let PROPERTY_THREAD = "thread"
	static let PROPERTY_CREATED = "created"
	
	let threadId: String
	let creatorId: String
	let created: TimeInterval
	
	var content: String
	
	
	// COMP. PROPERTIES	--------
	
	static var idIndexMap: [String : IdIndex]
	{
		let threadMap = NotesThread.idIndexMap
		let threadIndex = IdIndex.of(indexMap: threadMap)
		
		return threadMap + [PROPERTY_THREAD: threadIndex, PROPERTY_CREATED: threadIndex + 1]
	}
	
	var idProperties: [Any] { return [threadId, created] }
	var properties: [String : PropertyValue]
	{
		return ["creator": PropertyValue(creatorId), "content": PropertyValue(content)]
	}
	
	var collectionId: String { return ParagraphNotes.collectionId(fromId: threadId) }
	var chapterIndex: Int { return ParagraphNotes.chapterIndex(fromId: threadId) }
	var noteId: String { return NotesThread.noteId(fromId: threadId) }
	var threadCreated: TimeInterval { return NotesThread.created(fromId: threadId) }
	
	
	// INIT	--------------------
	
	init(threadId: String, creatorId: String, content: String, created: TimeInterval = Date().timeIntervalSince1970)
	{
		self.threadId = threadId
		self.creatorId = creatorId
		self.content = content
		self.created = created
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> NotesPost
	{
		return NotesPost(threadId: id[PROPERTY_THREAD].string(), creatorId: properties["creator"].string(), content: properties["content"].string(), created: id[PROPERTY_CREATED].time())
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func update(with properties: PropertySet)
	{
		if let content = properties["content"].string
		{
			self.content = content
		}
	}
}
