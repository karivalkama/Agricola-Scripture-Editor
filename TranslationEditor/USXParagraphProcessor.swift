//
//  USXParagraphParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 10.10.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

class USXParagraphProcessor: USXContentProcessor
{
	typealias Generated = Paragraph
	typealias Processed = Para
	
	
	// ATTRIBUTES	------------
	
	private let bookId: String
	private let chapterIndex: Int
	private let sectionIndex: Int
	private let paragraphIndex: Int
	private let userId: String
	
	private var paragraphStyleFound = false
	private var sectionHeadingFound = false
	private var contentParsed = false
	
	
	// INIT	--------------------
	
	init(userId: String, bookId: String, chapterIndex: Int, sectionIndex: Int, paragraphIndex: Int)
	{
		self.userId = userId
		self.bookId = bookId
		self.chapterIndex = chapterIndex
		self.sectionIndex = sectionIndex
		self.paragraphIndex = paragraphIndex
	}
	
	// Creates a new xml parser that is used for parsing the contents of a single paragraph.
	// The starting point for the parser should be at a para element.
	// The parser will stop at the new chapter marker or before that, once a paragraph has been parsed
	static func createParagraphParser(caller: XMLParserDelegate, userId: String, bookId: String, chapterIndex: Int, sectionIndex: Int, paragraphIndex: Int, targetPointer: UnsafeMutablePointer<[Paragraph]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Paragraph, Para>
	{
		let parser = USXContentParser<Paragraph, Para>(caller: caller, containingElement: .usx, lowestBreakMarker: .chapter, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXParagraphProcessor(userId: userId, bookId: bookId, chapterIndex: chapterIndex, sectionIndex: sectionIndex, paragraphIndex: paragraphIndex))
		
		return parser
	}
	
	
	// USX PROCESSING	--------
	
	func getParser(_ caller: USXContentParser<Paragraph, Para>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Para]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		if elementName == USXContainerElement.para.rawValue
		{
			// Parses the para style
			var style = ParaStyle.normal
			if let styleAttribute = attributes["style"]
			{
				style = ParaStyle.value(of: styleAttribute)
			}
			
			// Stops parsing if
			// a) Section heading was found previously and receives something other than a heading description
			// b) Paragraph style was found previously and receives another pararaph style
			// c) Some content was read and receives a section header
			if (sectionHeadingFound && !style.isHeaderDescriptionStyle()) || (paragraphStyleFound && style.isParagraphStyle()) || (contentParsed && style.isSectionHeadingStyle())
			{
				caller.stopsAfterCurrentParse = true
				return nil
			}
			// Otherwise parses normally uning a para parser
			else
			{
				if style.isSectionHeadingStyle()
				{
					sectionHeadingFound = true
				}
				
				if style.isParagraphStyle()
				{
					paragraphStyleFound = true
				}
				
				contentParsed = true
				
				return (USXParaProcessor.createParaParser(caller: caller, style: style, targetPointer: targetPointer, using: errorHandler), false)
			}
		}
		else
		{
			print("ERROR: ParagraphProcessor received element '\(elementName)'")
			return nil
		}
	}
	
	func generate(from content: [Para], using errorHandler: @escaping ErrorHandler) -> Paragraph?
	{
		/*
		for para in content
		{
			print("USX: \((para.range?.description).or("no range")) --- \(para.verses.map { $0.range }))")
		}*/
		
		// Clears the status for reuse
		contentParsed = false
		paragraphStyleFound = false
		
		// Wraps the para content into a paragraph
		return Paragraph(bookId: bookId, chapterIndex: chapterIndex, sectionIndex: sectionIndex, index: paragraphIndex, content: content, creatorId: userId)
	}
	
	func getCharacterParser(_ caller: USXContentParser<Paragraph, Para>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Para]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// This parser doesn't handle character data. All character data should be inside para elements.
		return nil
	}
}
