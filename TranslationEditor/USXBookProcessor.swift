//
//  USXBookProcessor.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.10.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// Some utility functions

// Saves paragraph information by overwriting an old version
@available(*, deprecated)
fileprivate func handleSingleMatch(existing: Paragraph, newVersion: Paragraph) throws
{
	// TODO: Only commit if the paragraphs contain changes
	// Creates a new commit over the existing paragraph version
	_ = try existing.commit(userId: newVersion.creatorId, sectionIndex: newVersion.sectionIndex, paragraphIndex: newVersion.index, content: newVersion.content)
}

// Saves a bunch of single paragraph matches to the database
@available(*, deprecated)
fileprivate func handleSingleMatches(_ matches: [(Paragraph, Paragraph)]) throws
{
	try matches.forEach{ (arg) in let (existing, newVersion) = arg; try handleSingleMatch(existing: existing, newVersion: newVersion) }
}

@available(*, deprecated)
fileprivate func paragraphsHaveEqualRange(_ first: Paragraph, _ second: Paragraph) -> Bool
{
	if let range1 = first.range, let range2 = second.range
	{
		return range1 == range2
	}
	else
	{
		return false
	}
}

// This USX processor is able to parse contents of a single book based on USX data
class USXBookProcessor: USXContentProcessor
{
	typealias Generated = BookData
	typealias Processed = Chapter
	
	
	// ATTRIBUTES	-------
	
	private let userId: String
	
	private var introductionParas = [Para]()
	private var identifier = ""
	
	private let book: Book
	
	
	// INIT	---------------
	
	init(projectId: String, userId: String, languageId: String, code: BookCode)
	{
		self.userId = userId
		self.book = Book(projectId: projectId, code: code, identifier: "", languageId: languageId)
	}
	
	// Creates a new USX parser for book data
	// The parser should be set to start after a book element start
	// The parser will stop at the next book element start or at the end of usx
	static func createBookParser(caller: XMLParserDelegate, projectId: String, userId: String, languageId: String, bookCode: BookCode, targetPointer: UnsafeMutablePointer<[Generated]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Generated, Processed>
	{
		let parser = USXContentParser<Generated, Processed>(caller: caller, containingElement: .usx, lowestBreakMarker: .book, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXBookProcessor(projectId: projectId, userId: userId, languageId: languageId, code: bookCode))
		
		return parser
	}
	
	
	// USX PARSING	-------
	
	func getParser(_ caller: USXContentParser<Generated, Processed>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// print("STATUS: \(elementName)")
		
		// On chapter elements, parses using a chapter parser
		if elementName == USXMarkerElement.chapter.rawValue
		{
			// Parses the chapter index from an attribute
			if let numberAttribute = attributes["number"], let index = Int(numberAttribute)
			{
				return (USXChapterProcessor.createChapterParser(caller: caller, userId: userId, bookId: book.idString, index: index, targetPointer: targetPointer, using: errorHandler), false)
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
			var style = ParaStyle.normal
			if let styleAttribute = attributes["style"]
			{
				style = ParaStyle.value(of: styleAttribute)
			}
			
			return (USXParaProcessor.createParaParser(caller: caller, style: style, targetPointer: &introductionParas, using: errorHandler), true)
		}
		else
		{
			print("ERROR: USXBookProcessor received element of type '\(elementName)'")
			return nil
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<Generated, Processed>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// Only character data found by this parser is the book name inside the book element
		// this information is parsed here and not delegated
		identifier += string
		return nil
	}
	
	func generate(from content: [Processed], using errorHandler: @escaping ErrorHandler) -> Generated?
	{
		// Finalises book data
		book.identifier = identifier
		book.introduction = introductionParas
		
		// Wraps the collected data into a book data
		let paragraphs = content.flatMap { chapter in return chapter.flatMap { $0 } }
		let bookData = BookData(book: book, paragraphs: paragraphs)
		
		//print("STATUS: Parsed book \(book.identifier) with \(content.count) chapters")
		
		// Resets status for reuse
		introductionParas = []
		identifier = ""
		
		return bookData
	}
}
