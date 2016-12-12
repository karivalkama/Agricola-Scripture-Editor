//
//  ParagraphEdit.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These instances are used for storing and accessing temporary edit status of a paragraph
final class ParagraphEdit: Storable
{
	// PROPERTIES	---------
	
	static let type = "edit"
	
	static let PROPERTY_USER_ID = "creator_user"
	static let PROPERTY_CREATED = "created"
	
	let userId: String
	let created: Double
	
	var paragraph: Paragraph
	var isConflict: Bool
	
	
	// COMP. PROPERTIES	-----
	
	static var idIndexMap: [String : IdIndex]
	{
		return ["edit" : IdIndex(0), ParagraphEdit.PROPERTY_USER_ID : IdIndex(1), ParagraphEdit.PROPERTY_CREATED : IdIndex(2)]
	}
	
	var idProperties: [Any] {return ["Edit", userId, created]}
	
	var properties: [String : PropertyValue] {return ["targetId" : PropertyValue(targetId), "paragraph" : PropertyValue(paragraph), "conflict" : PropertyValue(isConflict)]}
	
	var targetId: String {return paragraph.idString}
	
	
	// INIT	-----------------
	
	init(userId: String, paragraph: Paragraph, isConflict: Bool = false, created: Double = Date().timeIntervalSince1970)
	{
		self.userId = userId
		self.paragraph = paragraph
		self.created = created
		self.isConflict = isConflict
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> ParagraphEdit
	{
		// Parses the paragraph first
		let paragraph = try Paragraph.create(from: properties["paragraph"].object(), withId: Paragraph.createId(from: properties["targetId"].string()))
		
		return ParagraphEdit(userId: id[PROPERTY_USER_ID].string(), paragraph: paragraph, isConflict: properties["conflict"].bool(or: false), created: id[PROPERTY_CREATED].double(or: Date().timeIntervalSince1970))
	}
	
	
	// STORABLE	-------------
	
	func update(with properties: PropertySet) throws
	{
		if let isConflict = properties["conflict"].bool
		{
			self.isConflict = isConflict
		}
		if properties["targetId"].isDefined || properties["paragraph"].isDefined
		{
			var newParagraphId: String!
			if let targetId = properties["targetId"].string
			{
				newParagraphId = targetId
			}
			else
			{
				newParagraphId = self.targetId
			}
			
			var newParagraphProperties: PropertySet!
			if let paragraphData = properties["paragraph"].object
			{
				newParagraphProperties = paragraphData
			}
			else
			{
				newParagraphProperties = self.paragraph.toPropertySet
			}
			
			self.paragraph = try Paragraph.create(from: newParagraphProperties, withId: Paragraph.createId(from: newParagraphId))
		}
	}
	
	
	// OTHER	------------
	
	static func userId(fromId idString: String) -> String
	{
		return createId(from: idString)[PROPERTY_USER_ID].string()
	}
	
	static func creationTime(fromId idString: String) -> Double
	{
		return createId(from: idString)[PROPERTY_CREATED].double(or: Date().timeIntervalSince1970)
	}
}
