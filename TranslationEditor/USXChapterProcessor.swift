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
	
	private var index: Int
	
	
	// INIT	-----------------
	
	init(index: Int)
	{
		self.index = index
	}
	
	// Creates a new USX parser for chapter contents
	// The parser should start after a chapter element
	// the parser will stop at the next chapter element (or at next book / end of usx)
	static func createChapterParser(caller: XMLParserDelegate, index: Int, targetPointer: UnsafeMutablePointer<[Chapter]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Chapter, Section>
	{
		let parser = USXContentParser<Chapter, Section>(caller: caller, containingElement: .usx, lowestBreakMarker: .chapter, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXChapterProcessor(index: index))
		
		return parser
	}
	
	
	// USX PARSING	---------
	
	func getParser(_ caller: USXContentParser<Chapter, Section>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Section]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// Delegates all para element parsing to section parsers
		if elementName == USXContainerElement.para.rawValue
		{
			return (USXSectionProcessor.createSectionParser(caller: caller, targetPointer: targetPointer, using: errorHandler), true)
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
		// Wraps the collected sections into a character
		return Chapter(index: index, content: content)
	}
}
