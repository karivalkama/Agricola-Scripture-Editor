//
//  Book.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Books contain multiple chapters and paragraphs. A book is limited to a certain 
// Language and project context
final class Book: Storable
{
	// ATTRIBUTES	--------
	
	// The type attribute value for all book instances
	static let TYPE = "book"
	static let PROPERTY_CODE = "code"
	
	private let _id: String
	let code: String
	
	var identifier: String
	var language: String
	
	
	// COMP. PROPERTIES	----
	
	var idProperties: [Any] {return [code, _id]}
	
	var properties: [String : PropertyValue]
	{
		return [PROPERTY_TYPE : PropertyValue(Book.TYPE), "identifier" : PropertyValue(identifier), "language" : PropertyValue(language)]
	}
	
	static var idIndexMap: [String : IdIndex] {return [PROPERTY_CODE : IdIndex(0)]}
	
	
	// INIT	----------------
	
	init(code: String, identifier: String, language: String, id: String = UUID().uuidString)
	{
		self.code = code
		self.identifier = identifier
		self.language = language
		self._id = id
		
		// TODO: It would be possible to throw an error for invalid parameters
	}
	
	static func create(from properties: PropertySet, withId id: [PropertyValue]) throws -> Book
	{
		if id.count < 2
		{
			throw JSONParseError(data: properties, message: "2 part id required, \(id) provided")
		}
		
		return Book(code: id[0].string(), identifier: properties["identifier"].string(), language: properties["language"].string(), id: id[1].string())
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func update(with properties: PropertySet)
	{
		if let identifier = properties["identifier"].string
		{
			self.identifier = identifier
		}
		if let language = properties["language"].string
		{
			self.language = language
		}
	}
}
