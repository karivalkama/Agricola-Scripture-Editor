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
	static let type = "book"
	static let PROPERTY_CODE = "code"
	
	let uid: String
	let code: String
	
	var identifier: String
	var languageId: String
	
	
	// COMP. PROPERTIES	----
	
	var idProperties: [Any] {return [code, uid]}
	
	var properties: [String : PropertyValue]
	{
		return ["identifier" : PropertyValue(identifier), "language" : PropertyValue(languageId)]
	}
	
	static var idIndexMap: [String : IdIndex] {return [PROPERTY_CODE : IdIndex(0), "book_uid" : IdIndex(1)]}
	
	
	// INIT	----------------
	
	init(code: String, identifier: String, languageId: String, uid: String = UUID().uuidString.lowercased())
	{
		self.code = code.lowercased()
		self.identifier = identifier
		self.languageId = languageId
		self.uid = uid
		
		// TODO: It would be possible to throw an error for invalid parameters
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> Book
	{
		return Book(code: id[PROPERTY_CODE].string(), identifier: properties["identifier"].string(), languageId: properties["language"].string(), uid: id["book_uid"].string())
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
			self.languageId = language
		}
	}
	
	
	// OTHER METHODS	--------
	
	// Parses the book code out of a book id string
	static func code(fromId bookIdString: String) -> String
	{
		return createId(from: bookIdString)[PROPERTY_CODE].string()
	}
}
