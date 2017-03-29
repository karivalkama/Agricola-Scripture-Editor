//
//  Views.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A book view can be used for querying book data from the database
@available(*, deprecated)
final class BookView: View
{
	// TYPES	------------
	
	typealias Queried = Book
	
	
	// ATTRIBUTES	--------
	
	static let KEY_LANGUAGE = "languageid"
	static let KEY_BOOK_CODE = "code"
	static let KEY_BOOK_IDENTIFIER = "identifier"
	static let keyNames = [KEY_BOOK_CODE, KEY_LANGUAGE, KEY_BOOK_IDENTIFIER]
	
	static let instance = BookView()
	
	let view: CBLView
	
	
	// INIT	----------------
	
	private init()
	{
		view = DATABASE.viewNamed("books")
		view.setMapBlock(createMapBlock
		{
			(book, emit) in
			
			// Key = code + language id + identifier
			let key = [book.code, book.languageId, book.identifier]
			emit(key, nil)
			
		}, version: "2")
	}
	
	
	// OTHER METHODS	-----
	
	// Creates a new query for book data
	func booksQuery(code: String? = nil, languageId: String? = nil, identifier: String? = nil) -> Query<BookView>
	{
		let keys = [
			BookView.KEY_LANGUAGE : Key(languageId),
			BookView.KEY_BOOK_CODE : Key(code?.lowercased()),
			BookView.KEY_BOOK_IDENTIFIER : Key(identifier)
		]
		return Query<BookView>(range: keys)
	}
}
