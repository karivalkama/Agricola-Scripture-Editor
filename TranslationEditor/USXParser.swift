//
//  USXProcessor.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class is able to parse through all of usx data, creating a set of books
class USXParser: NSObject, XMLParserDelegate
{
	// ATTRIBUTES	-----------
	
	private let projectId: String
	private let userId: String
	private let languageId: String
	private let findReplacedBook: FindBook
	private let matchParagraphs: MatchParagraphs
	
	private var _receivedError: Error?
	var error: Error? {return _receivedError}
	
	private var contentParser: XMLParserDelegate?
	
	// The books parsed from the processed USX content
	var parsedBooks = [Book]()
	
	var success: Bool {return self._receivedError == nil}
	
	
	// INIT	-------------------
	
	// Language id + code + identifier -> Book to replace / update
	init(projectId: String, userId: String, languageId: String, findReplacedBook: @escaping FindBook, matchParagraphs: @escaping MatchParagraphs)
	{
		self.projectId = projectId
		self.userId = userId
		self.languageId = languageId
		self.findReplacedBook = findReplacedBook
		self.matchParagraphs = matchParagraphs
	}
	
	
	// XML PARSING	-----------
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		// When a book element is found, parses the book code and starts parsing it
		// (as long as the parsing hasn't failed previously)
		if elementName == USXMarkerElement.book.rawValue && success
		{
			if let code = attributeDict["code"]
			{
				// Delegates parsing to book parser
				contentParser = USXBookProcessor.createBookParser(caller: self, projectId: projectId, userId: userId, languageId: languageId, bookCode: code, findReplacedBook: findReplacedBook, matchParagraphs: matchParagraphs, targetPointer: &parsedBooks, using: parsingFailed)
				parser.delegate = contentParser
			}
			else
			{
				parsingFailed(cause: USXParseError.bookCodeNotFound)
			}
		}
	}
	
	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error)
	{
		parsingFailed(cause: parseError)
	}
	
	func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error)
	{
		parsingFailed(cause: validationError)
	}
	
	
	// OTHER	---------------
	
	private func parsingFailed(cause error: Error)
	{
		_receivedError = error
	}
}
