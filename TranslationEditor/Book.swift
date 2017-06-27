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
	static let PROPERTY_PROJECT = "project"
	static let PROPERTY_CODE = "code"
	
	static let idIndexMap: IdIndexMap = [PROPERTY_PROJECT, PROPERTY_CODE, "book_uid"]
	
	private(set) var uid: String
	private(set) var code: BookCode
	private(set) var projectId: String
	
	var identifier: String
	var languageId: String
	var introduction: [Para]
	
	
	// COMP. PROPERTIES	----
	
	var idProperties: [Any] {return [projectId, code.code.lowercased(), uid]}
	
	var properties: [String : PropertyValue]
	{
		return ["identifier" : identifier.value, "language" : languageId.value, "introduction": introduction.value]
	}
	
	
	// INIT	----------------
	
	init(projectId: String, code: BookCode, identifier: String, languageId: String, introduction: [Para] = [], uid: String = UUID().uuidString.lowercased())
	{
		self.projectId = projectId
		self.code = code
		self.identifier = identifier
		self.languageId = languageId
		self.uid = uid
		self.introduction = introduction
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> Book
	{
		return Book(projectId: id[PROPERTY_PROJECT].string(), code: BookCode.of(code: id[PROPERTY_CODE].string()), identifier: properties["identifier"].string(), languageId: properties["language"].string(), introduction: try Para.parseArray(from: properties["introduction"].array(), using: Para.parse), uid: id["book_uid"].string())
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func update(with properties: PropertySet) throws
	{
		if let identifier = properties["identifier"].string
		{
			self.identifier = identifier
		}
		if let language = properties["language"].string
		{
			self.languageId = language
		}
		if let introductionData = properties["introduction"].array
		{
			self.introduction = try Para.parseArray(from: introductionData, using: Para.parse)
		}
	}
	
	
	// OTHER METHODS	--------
	
	func setId(_ idString: String)
	{
		code = Book.code(fromId: idString)
		projectId = Book.projectId(fromId: idString)
		uid = Book.property(withName: "book_uid", fromId: idString).string()
	}
	
	// Creates a copy of this book that contains the same paragraph formatting but none of the original content
	// The resulting book data is saved into database as part of this operation
	// Also creates a binding for the new book, as well as notes
	func makeEmptyCopy(projectId: String, identifier: String, languageId: String, userId: String, resourceName: String) throws -> BookData
	{
		// Creates the new book instance
		let newBook = Book(projectId: projectId, code: self.code, identifier: identifier, languageId: languageId, introduction: introduction.map { $0.copy() })
		
		// Finds the existing paragraphs
		let existingParagraphs = try ParagraphView.instance.latestParagraphQuery(bookId: idString).resultObjects()
		
		// Creates a copy of each paragraph with no existing content
		let newParagraphs = existingParagraphs.map { $0.emptyCopy(forBook: newBook.idString, creatorId: userId) }
		
		// Saves the newly generated data into the database
		try DATABASE.tryTransaction
		{
			try newBook.push()
			try newParagraphs.forEach { try $0.push() }
		}
		
		// Creates a binding too
		var bindings = [(String, String)]()
		for i in 0 ..< existingParagraphs.count
		{
			bindings.append((existingParagraphs[i].idString, newParagraphs[i].idString))
		}
		
		// Creates a new resource for the binding
		let bindingResource = ResourceCollection(languageId: self.languageId, bookId: newBook.idString, category: .sourceTranslation, name: resourceName)
		let binding = ParagraphBinding(resourceCollectionId: bindingResource.idString, sourceBookId: idString, targetBookId: newBook.idString, bindings: bindings, creatorId: userId)
		
		// Creates a set of notes for the new translation too
		let notesResource = ResourceCollection(languageId: self.languageId, bookId: newBook.idString, category: .notes, name: "Notes")
		let notes = newParagraphs.map { ParagraphNotes(collectionId: notesResource.idString, chapterIndex: $0.chapterIndex, pathId: $0.pathId) }
		
		// Saves the resource data to the database
		try DATABASE.tryTransaction
		{
			try bindingResource.push()
			try binding.push()
			
			try notesResource.push()
			try notes.forEach { try $0.push() }
		}
		
		return BookData(book: newBook, paragraphs: newParagraphs)
	}
	
	// Parses a project id out of a book id string
	static func projectId(fromId bookIdString: String) -> String
	{
		return property(withName: PROPERTY_PROJECT, fromId: bookIdString).string()
	}
	
	// Parses the book code out of a book id string
	static func code(fromId bookIdString: String) -> BookCode
	{
		return BookCode.of(code: createId(from: bookIdString)[PROPERTY_CODE].string())
	}
}
