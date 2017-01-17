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
	static let PROPERTY_CREATED = "created"
	static let idIndexMap = ["post_uid": IdIndex(0), PROPERTY_CREATED: IdIndex(1)]
	
	let uid: String
	
	let threadId: String
	let creatorId: String
	let created: TimeInterval
	
	var content: String
	
	
	// COMP. PROPERTIES	--------
	
	var idProperties: [Any] { return [uid, created] }
	var properties: [String : PropertyValue]
	{
		return ["thread": PropertyValue(threadId), "creator": PropertyValue(creatorId), "content": PropertyValue(content)]
	}
	
	
	// INIT	--------------------
	
	init(threadId: String, creatorId: String, content: String, uid: String = UUID().uuidString.lowercased(), created: TimeInterval = Date().timeIntervalSince1970)
	{
		self.threadId = threadId
		self.creatorId = creatorId
		self.content = content
		self.uid = uid
		self.created = created
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> NotesPost
	{
		return NotesPost(threadId: properties["thread"].string(), creatorId: properties["creator"].string(), content: properties["content"].string(), uid: id["post_uid"].string(), created: id[PROPERTY_CREATED].time())
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
