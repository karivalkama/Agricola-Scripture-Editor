//
//  Chapter.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A Chapter represents a single chapter in a book
// Chapters are used for indexing / combining ranges of paragraphs together
final class Chapter: Storable
{
	// ATTRIBUTES	-------
	
	let bookId: String
	let index: Int
	
	static let TYPE = "chapter"
	static let PROPERTY_BOOK_ID = "bookId"
	static let PROPERTY_CHAPTER_INDEX = "chapterIndex"
	
	
	// COMP. PROPERTIES	---
	
	var idProperties: [Any] {return [bookId, index]}
	
	var properties: [String : PropertyValue] {return [PROPERTY_TYPE : PropertyValue(Chapter.TYPE)]}
	
	static var idIndexMap: [String : IdIndex] {return Book.idIndexMap + [PROPERTY_BOOK_ID : IdIndex(0, 2), PROPERTY_CHAPTER_INDEX : IdIndex(2)]}
	
	
	// INIT	---------------
	
	// Creates a new chapter for the provided book
	init(bookId: String, index: Int)
	{
		self.bookId = bookId
		self.index = index
		
		// TODO: Again, one can add exceptions
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> Chapter
	{
		// Doesn't actually store any properties
		// Parses id properties anyhow
		return Chapter(bookId: id[PROPERTY_BOOK_ID].string(), index: id[PROPERTY_CHAPTER_INDEX].int())
	}
	
	
	// OTHER METHODS	----
	
	func update(with properties: PropertySet)
	{
		// No mutable properties to update at this time
	}
	
	// Finds the chapter index from a chapter id string
	static func chapterIndex(fromId chapterIdString: String) -> Int
	{
		return createId(from: chapterIdString)[PROPERTY_CHAPTER_INDEX].int()
	}
	
	// Finds the book id from a chapter id string
	static func bookId(fromId chapterIdString: String) -> String
	{
		return createId(from: chapterIdString)[PROPERTY_BOOK_ID].string()
	}
}
