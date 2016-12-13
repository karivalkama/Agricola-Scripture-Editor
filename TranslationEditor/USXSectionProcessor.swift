//
//  USXSectionParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 10.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This USX Content processor is able to parse sections from USX data
class USXSectionProcessor: USXContentProcessor
{
	typealias Generated = Section
	typealias Processed = Paragraph
	
	
	// ATTRIBUTES	---------
	
	private let userId: String
	private let bookId: String
	private let chapterIndex: Int
	private let sectionIndex: Int
	
	private var contentParsed = false
	var paragraphIndex = 0
	
	
	// INIT	-----------------
	
	init(userId: String, bookId: String, chapterIndex: Int, sectionIndex: Int)
	{
		self.userId = userId
		self.bookId = bookId
		self.chapterIndex = chapterIndex
		self.sectionIndex = sectionIndex
	}
	
	static func createSectionParser(caller: XMLParserDelegate, processor: USXSectionProcessor, targetPointer: UnsafeMutablePointer<[Section]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Section, Paragraph>
	{
		let parser = USXContentParser<Section, Paragraph>(caller: caller, containingElement: .usx, lowestBreakMarker: .chapter, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(processor)
		return parser
	}
	
	// Creates a new USX parser for section data
	// The parser should start right after a chapter element or at the start of a section heading para element
	// The parser will stop parsing at the start of the next chapter or section heading para element (or at the end of the usx element)
	static func createSectionParser(caller: XMLParserDelegate, userId: String, bookId: String, chapterIndex: Int, sectionIndex: Int, targetPointer: UnsafeMutablePointer<[Section]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Section, Paragraph>
	{
		let processor = USXSectionProcessor(userId: userId, bookId: bookId, chapterIndex: chapterIndex, sectionIndex: sectionIndex)
		return createSectionParser(caller: caller, processor: processor, targetPointer: targetPointer, using: errorHandler)
	}
	
	
	// USX PARSING	---------
	
	func getParser(_ caller: USXContentParser<Section, Paragraph>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Paragraph]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		if elementName == USXContainerElement.para.rawValue
		{
			// Parses the para style in order to check when section headers are found
			var sectionHeadingFound = false
			if let styleAttribute = attributes["style"]
			{
				if ParaStyle.value(of: styleAttribute).isSectionHeadingStyle()
				{
					sectionHeadingFound = true
				}
			}
			
			// Section headers are used as markers between sections
			if sectionHeadingFound && contentParsed
			{
				caller.stopsAfterCurrentParse = true
				return nil
			}
			else
			{
				// Para content parsing is delegated to paragraph parser
				contentParsed = true
				paragraphIndex += 1
				return (USXParagraphProcessor.createParagraphParser(caller: caller, userId: userId, bookId: bookId, chapterIndex: chapterIndex, sectionIndex: sectionIndex, paragraphIndex: paragraphIndex, targetPointer: targetPointer, using: errorHandler), true)
			}
		}
		else
		{
			return nil
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<Section, Paragraph>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Paragraph]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// Character data is ignored. All character data should be inside para elements
		return nil
	}
	
	func generate(from content: [Paragraph], using errorHandler: @escaping ErrorHandler) -> Section?
	{
		// Resets status for reuse
		contentParsed = false
		paragraphIndex = 0
		
		// Wraps the paragraphs into a section
		return content
	}
}
