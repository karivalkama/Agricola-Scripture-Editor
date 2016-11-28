//
//  USXParagraphParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 10.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

@available (*, deprecated)
class USXParagraphProcessor: USXContentProcessor
{
	typealias Generated = ParagraphPrev
	typealias Processed = Para
	
	
	// ATTRIBUTES	------------
	
	private var paragraphStyleFound = false
	private var contentParsed = false
	
	
	// INIT	--------------------
	
	// Creates a new xml parser that is used for parsing the contents of a single paragraph.
	// The starting point for the parser should be at a para element.
	// The parser will stop at the new chapter marker or before that, once a paragraph has been parsed
	static func createParagraphParser(caller: XMLParserDelegate, targetPointer: UnsafeMutablePointer<[ParagraphPrev]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<ParagraphPrev, Para>
	{
		let parser = USXContentParser<ParagraphPrev, Para>(caller: caller, containingElement: .usx, lowestBreakMarker: .chapter, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXParagraphProcessor())
		
		return parser
	}
	
	
	// USX PROCESSING	--------
	
	func getParser(_ caller: USXContentParser<ParagraphPrev, Para>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Para]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		if elementName == USXContainerElement.para.rawValue
		{
			// Parses the para style
			var style = ParaStyle.normal
			if let styleAttribute = attributes["style"]
			{
				style = ParaStyle.value(of: styleAttribute)
			}
			
			// A section heading para is the last thing parsed by this parser (section heading paragraph can contain only that singe para)
			if style.isSectionHeadingStyle()
			{
				print("Section heading found -> stops parsing after this para")
				caller.nextStopContainer = .para
			}
			
			// If some content was parsed previously and a section heading is found
			// OR if multiple paragraph style paras would be included, stops parsing right there
			if (contentParsed && style.isSectionHeadingStyle()) || (paragraphStyleFound && style.isParagraphStyle())
			{
				caller.stopsAfterCurrentParse = true
				return nil
			}
			// Otherwise parses normally uning a para parser
			else
			{
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
			return nil
		}
	}
	
	func generate(from content: [Para], using errorHandler: @escaping ErrorHandler) -> ParagraphPrev?
	{
		// Clears the status for reuse
		contentParsed = false
		paragraphStyleFound = false
		
		// Wraps the para content into a paragraph
		return ParagraphPrev(content: content)
	}
	
	func getCharacterParser(_ caller: USXContentParser<ParagraphPrev, Para>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Para]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// This parser doesn't handle character data. All character data should be inside para elements.
		return nil
	}
}
