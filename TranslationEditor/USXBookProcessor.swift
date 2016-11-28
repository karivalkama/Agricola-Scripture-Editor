//
//  USXBookProcessor.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This USX processor is able to parse contents of a single book based on USX data
@available (*, deprecated)
class USXBookProcessor: USXContentProcessor
{
	typealias Generated = BookPrev
	typealias Processed = ChapterPrev
	
	
	// ATTRIBUTES	-------
	
	private var introductionParas = [Para]()
	private var bookName: String?
	
	private var code: String
	
	
	// INIT	---------------
	
	init(code: String)
	{
		self.code = code
	}
	
	// Creates a new USX parser for book data
	// The parser should be set to start after a book element start
	// The parser will stop at the next book element start or at the end of usx
	static func createBookParser(caller: XMLParserDelegate, bookCode: String, targetPointer: UnsafeMutablePointer<[BookPrev]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<BookPrev, ChapterPrev>
	{
		let parser = USXContentParser<BookPrev, ChapterPrev>(caller: caller, containingElement: .usx, lowestBreakMarker: .book, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXBookProcessor(code: bookCode))
		
		return parser
	}
	
	
	// USX PARSING	-------
	
	func getParser(_ caller: USXContentParser<BookPrev, ChapterPrev>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[ChapterPrev]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// On chapter elements, parses using a chapter parser
		if elementName == USXMarkerElement.chapter.rawValue
		{
			// Parses the chapter index from an attribute
			if let numberAttribute = attributes["number"], let index = Int(numberAttribute)
			{
				return (USXChapterProcessor.createChapterParser(caller: caller, index: index, targetPointer: targetPointer, using: errorHandler), false)
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
	
	func getCharacterParser(_ caller: USXContentParser<BookPrev, ChapterPrev>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[ChapterPrev]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// Only character data found by this parser is the book name inside the book element
		// this information is parsed here and not delegated
		bookName = string
		return nil
	}
	
	func generate(from content: [ChapterPrev], using errorHandler: @escaping ErrorHandler) -> BookPrev?
	{
		// Creates the introduction paragraph
		let introduction = ParagraphPrev(content: introductionParas)
		// Creates the book
		var book: BookPrev?
		if let bookName = bookName
		{
			book = BookPrev(code: code, name: bookName, content: content, introduction: introduction)
		}
		else
		{
			errorHandler(USXParseError.bookNameNotSpecified)
		}
		
		// Clears status for reuse
		introductionParas = []
		bookName = nil
		
		return book
	}
}
