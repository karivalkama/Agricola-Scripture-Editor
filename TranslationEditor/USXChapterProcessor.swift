//
//  USXChapterProcessor.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

class USXChapterProcessor: USXContentProcessor
{
	typealias Generated = Chapter
	typealias Processed = Section
	
	
	// ATTRIBUTES	---------
	
	private let bookId: String
	private let chapterIndex: Int
	
	private var sectionIndex = 0
	private var paragraphIndex = 0
	
	private var sectionProcessor: USXSectionProcessor?
	
	
	// INIT	-----------------
	
	init(bookId: String, index: Int)
	{
		self.bookId = bookId
		self.chapterIndex = index
	}
	
	// Creates a new USX parser for chapter contents
	// The parser should start after a chapter element
	// the parser will stop at the next chapter element (or at next book / end of usx)
	static func createChapterParser(caller: XMLParserDelegate, bookId: String, index: Int, targetPointer: UnsafeMutablePointer<[Chapter]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Chapter, Section>
	{
		let parser = USXContentParser<Chapter, Section>(caller: caller, containingElement: .usx, lowestBreakMarker: .chapter, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXChapterProcessor(bookId: bookId, index: index))
		
		return parser
	}
	
	
	// USX PARSING	---------
	
	func getParser(_ caller: USXContentParser<Chapter, Section>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Section]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// Delegates all para element parsing to section parsers
		if elementName == USXContainerElement.para.rawValue
		{
			// Counts the paragraphs parsed by the last processor
			if let lastProcessor = sectionProcessor
			{
				paragraphIndex = lastProcessor.paragraphIndex
			}
			
			sectionIndex += 1
			
			// Creates the new processor and parser
			sectionProcessor = USXSectionProcessor(bookId: bookId, chapterIndex: chapterIndex, sectionIndex: sectionIndex, lastParagraphIndex: paragraphIndex)
			return (USXSectionProcessor.createSectionParser(caller: caller, processor: sectionProcessor!, targetPointer: targetPointer, using: errorHandler), true)
		}
		else
		{
			return nil
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<Chapter, Section>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Section]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// Character parsing is only handled below para level
		return nil
	}
	
	func generate(from content: [Section], using errorHandler: @escaping ErrorHandler) -> Chapter?
	{
		// Resets status for reuse
		sectionIndex = 0
		
		return content
	}
}
