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
	let originalCommentId: String?
	
	var content: String
	
	
	// COMP. PROPERTIES	--------
	
	static var idIndexMap: IdIndexMap
	{
		return NotesThread.idIndexMap.makeChildPath(parentPathName: PROPERTY_THREAD, childPath: [PROPERTY_CREATED])
	}
	
	var idProperties: [Any] { return [threadId, created] }
	var properties: [String : PropertyValue]
	{
		return ["creator": creatorId.value, "content": content.value, "original_comment": originalCommentId.value]
	}
	
	var collectionId: String { return ParagraphNotes.collectionId(fromId: threadId) }
	var chapterIndex: Int { return ParagraphNotes.chapterIndex(fromId: threadId) }
	var noteId: String { return NotesThread.noteId(fromId: threadId) }
	var threadCreated: TimeInterval { return NotesThread.created(fromId: threadId) }
	
	
	// INIT	--------------------
	
	init(threadId: String, creatorId: String, content: String, created: TimeInterval = Date().timeIntervalSince1970, originalCommentId: String? = nil)
	{
		self.threadId = threadId
		self.creatorId = creatorId
		self.content = content
		self.created = created
		self.originalCommentId = originalCommentId
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> NotesPost
	{
		return NotesPost(threadId: id[PROPERTY_THREAD].string(), creatorId: properties["creator"].string(), content: properties["content"].string(), created: id[PROPERTY_CREATED].time(), originalCommentId: properties["original_comment"].string())
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
