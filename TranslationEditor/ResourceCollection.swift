//
//  ResourceCollection.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A resource collection is an entity that unites a group of paragraph resources into one book-specific resource
final class ResourceCollection : Storable
{
	// ATTRIBUTES	------------
	
	static let type = "resource"
	
	let uid: String
	let languageId: String
	let bookId: String
	let category: ResourceCategory
	
	var name: String
	
	
	// COMP. PROPERTIES	--------
	
	static var idIndexMap: [String : IdIndex] { return ["resource_uid" : IdIndex(0)] }
	
	var idProperties: [Any] { return [uid] }
	
	var properties: [String : PropertyValue] { return ["language" : PropertyValue(languageId), "book" : PropertyValue(bookId), "category" : PropertyValue(category.rawValue), "name" : PropertyValue(name)] }
	
	
	// INIT	-------------------
	
	init(languageId: String, bookId: String, category: ResourceCategory, name: String, uid: String = UUID().uuidString.lowercased())
	{
		self.uid = uid
		self.languageId = languageId
		self.bookId = bookId
		self.category = category
		self.name = name
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> ResourceCollection
	{
		return ResourceCollection(languageId: properties["language"].string(), bookId: properties["book"].string(), category: ResourceCategory(rawValue: properties["category"].int()).or(.other), name: properties["name"].string(), uid: id["resource_uid"].string())
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func update(with properties: PropertySet)
	{
		if let name = properties["name"].string
		{
			self.name = name
		}
	}
}
