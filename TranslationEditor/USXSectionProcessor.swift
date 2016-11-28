//
//  USXSectionParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 10.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This USX Content processor is able to parse sections from USX data
@available (*, deprecated)
class USXSectionProcessor: USXContentProcessor
{
	typealias Generated = SectionPrev
	typealias Processed = ParagraphPrev
	
	
	// ATTRIBUTES	---------
	
	private var contentParsed = false
	
	
	// INIT	-----------------
	
	// Creates a new USX parser for section data
	// The parser should start right after a chapter element or at the start of a section heading para element
	// The parser will stop parsing at the start of the next chapter or section heading para element (or at the end of the usx element)
	static func createSectionParser(caller: XMLParserDelegate, targetPointer: UnsafeMutablePointer<[SectionPrev]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<SectionPrev, ParagraphPrev>
	{
		let parser = USXContentParser<SectionPrev, ParagraphPrev>(caller: caller, containingElement: .usx, lowestBreakMarker: .chapter, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXSectionProcessor())
		
		return parser
	}
	
	
	// USX PARSING	---------
	
	func getParser(_ caller: USXContentParser<SectionPrev, ParagraphPrev>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[ParagraphPrev]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		if elementName == USXContainerElement.para.rawValue
		{
			// Parses the para style in order to check when section headers are found
			var sectionHeadingFound = false
			if let styleAttribute = attributes["style"]
			{
				if ParaStyle.value(of: styleAttribute).isSectionHeadingStyle()
				{
					print("Section heading found")
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
				return (USXParagraphProcessor.createParagraphParser(caller: caller, targetPointer: targetPointer, using: errorHandler), true)
			}
		}
		else
		{
			return nil
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<SectionPrev, ParagraphPrev>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[ParagraphPrev]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// Character data is ignored. All character data should be inside para elements
		return nil
	}
	
	func generate(from content: [ParagraphPrev], using errorHandler: @escaping ErrorHandler) -> SectionPrev?
	{
		// Resets status for reuse
		contentParsed = false
		
		// Wraps the paragraphs into a section
		return SectionPrev(content: content)
	}
}
