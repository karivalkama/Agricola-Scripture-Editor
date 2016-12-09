//
//  Commit.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A commit is a saved version of a paragraph
final class Commit: Storable
{
	// PROPERTIES	---------
	
	static let PROPERTY_PARAGRAPH_ID = "paragraph_id"
	static let PROPERTY_CREATION_TIME = "created"
	
	static let type = "commit"
	
	let paragraphId: String
	let created: Double
	
	var creatorId: String
	var content: [Para]
	
	var idProperties: [Any] { return [paragraphId, created] }
	
	var properties: [String : PropertyValue] { return ["creator" : PropertyValue(creatorId), "paras" : PropertyValue(content)] }
	
	static var idIndexMap: [String : IdIndex]
	{
		let paragraphIndexMap = Paragraph.idIndexMap
		let paragraphIdIndex = IdIndex.of(indexMap: paragraphIndexMap)
		
		return paragraphIndexMap + [PROPERTY_PARAGRAPH_ID : paragraphIdIndex, PROPERTY_CREATION_TIME : IdIndex(paragraphIdIndex.end)]
	}
	
	
	// INIT	-----------------
	
	init(paragraphId: String, content: [Para], creatorId: String, created: Double = Date().timeIntervalSince1970)
	{
		self.paragraphId = paragraphId
		self.content = content
		self.creatorId = creatorId
		self.created = created
	}
	
	convenience init(paragraph: Paragraph, creatorId: String, created: Double = Date().timeIntervalSince1970)
	{
		self.init(paragraphId: paragraph.idString, content: paragraph.content.copy(), creatorId: creatorId, created: created)
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> Commit
	{
		return Commit(paragraphId: id[PROPERTY_PARAGRAPH_ID].string(), content: try Para.parseArray(from: properties["paras"].array(), using: Para.parse), creatorId: properties["creator"].string(), created: properties["created"].double(or: Date().timeIntervalSince1970))
	}
	
	
	// IMPLEMENTED	--------
	
	func update(with properties: PropertySet) throws
	{
		if let creatorId = properties["creator"].string
		{
			self.creatorId = creatorId
		}
		if let contentArray = properties["paras"].array
		{
			self.content = try Para.parseArray(from: contentArray, using: Para.parse)
		}
	}
}
