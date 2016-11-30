//
//  USXBookProcessor.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This USX processor is able to parse contents of a single book based on USX data
class USXBookProcessor: USXContentProcessor
{
	typealias Generated = Book
	typealias Processed = Chapter
	
	
	// ATTRIBUTES	-------
	
	private let code: String
	private let languageId: String
	
	// Language + code + identifier -> Book to overwrite
	private let findReplacedBook: (String, String, String) -> (Book?)
	
	private var introductionParas = [Para]()
	private var identifier: String?
	private var _book: Book?
	
	
	// INIT	---------------
	
	init(languageId: String, code: String, findReplacedBook: @escaping (String, String, String) -> (Book?))
	{
		self.languageId = languageId
		self.code = code
		self.findReplacedBook = findReplacedBook
	}
	
	// Creates a new USX parser for book data
	// The parser should be set to start after a book element start
	// The parser will stop at the next book element start or at the end of usx
	static func createBookParser(caller: XMLParserDelegate, languageId: String, bookCode: String, findReplacedBook: @escaping (String, String, String) -> (Book?), targetPointer: UnsafeMutablePointer<[Book]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Book, Chapter>
	{
		let parser = USXContentParser<Book, Chapter>(caller: caller, containingElement: .usx, lowestBreakMarker: .book, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXBookProcessor(languageId: languageId, code: bookCode, findReplacedBook: findReplacedBook))
		
		return parser
	}
	
	
	// USX PARSING	-------
	
	func getParser(_ caller: USXContentParser<Book, Chapter>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Chapter]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// On chapter elements, parses using a chapter parser
		if elementName == USXMarkerElement.chapter.rawValue
		{
			// Parses the chapter index from an attribute
			if let numberAttribute = attributes["number"], let index = Int(numberAttribute)
			{
				do
				{
					let book = try getBook()
					return (USXChapterProcessor.createChapterParser(caller: caller, bookId: book.idString, index: index, targetPointer: targetPointer, using: errorHandler), false)
				}
				catch
				{
					errorHandler(error)
					return nil
				}
			}
			else
			{
				errorHandler(USXParseError.chapterIndexNotFound)
				return nil
			}
		}
		// The introduction is parsed using a para parser
		else if elementName == USXContainerElement.para.rawValue
		{
			// TODO: WET WET
			var style = ParaStyle.normal
			if let styleAttribute = attributes["style"]
			{
				style = ParaStyle.value(of: styleAttribute)
			}
			
			return (USXParaProcessor.createParaParser(caller: caller, style: style, targetPointer: &introductionParas, using: errorHandler), true)
		}
		else
		{
			return nil
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<Book, Chapter>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Chapter]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// Only character data found by this parser is the book name inside the book element
		// this information is parsed here and not delegated
		identifier = string
		return nil
	}
	
	func generate(from content: [Chapter], using errorHandler: @escaping ErrorHandler) -> Book?
	{
		// Creates the introduction paragraphs (TODO: Removed in the current version)
		//let introduction = ParagraphPrev(content: introductionParas)
		
		do
		{
			// Creates the book
			let book = try getBook()
			
			// Clears status for reuse
			introductionParas = []
			identifier = nil
			_book = nil
			
			return book
		}
		catch
		{
			errorHandler(error)
			return nil
		}
	}
	
	
	// OTHER METHODS	---------
	
	// Function used because computed properties can't throw at this time
	private func getBook() throws -> Book
	{
		if _book == nil
		{
			if let identifier = identifier
			{
				if let existingBook = findReplacedBook(languageId, code, identifier)
				{
					existingBook.identifier = identifier
					existingBook.languageId = languageId
					_book = existingBook
				}
				else
				{
					_book = Book(code: code, identifier: identifier, languageId: languageId)
				}
			}
			else
			{
				throw USXParseError.bookNameNotSpecified
			}
		}
		
		return _book!
	}
}
