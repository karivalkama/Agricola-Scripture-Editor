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
	
	private let _uid: String
	let code: String
	
	var identifier: String
	var language: String
	
	
	// COMP. PROPERTIES	----
	
	var idProperties: [Any] {return [code, _uid]}
	
	var properties: [String : PropertyValue]
	{
		return [PROPERTY_TYPE : PropertyValue(Book.TYPE), "identifier" : PropertyValue(identifier), "language" : PropertyValue(language)]
	}
	
	static var idIndexMap: [String : IdIndex] {return [PROPERTY_CODE : IdIndex(0), "uid" : IdIndex(1)]}
	
	
	// INIT	----------------
	
	init(code: String, identifier: String, language: String, uid: String = UUID().uuidString)
	{
		self.code = code
		self.identifier = identifier
		self.language = language
		self._uid = uid
		
		// TODO: It would be possible to throw an error for invalid parameters
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> Book
	{
		return Book(code: id[PROPERTY_CODE].string(), identifier: properties["identifier"].string(), language: properties["language"].string(), uid: id["uid"].string())
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
	
	
	// OTHER METHODS	--------
	
	// Parses the book code out of a book id string
	static func code(fromId bookIdString: String) -> String
	{
		return createId(from: bookIdString)[PROPERTY_CODE].string()
	}
}
