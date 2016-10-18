//
//  USXVerseProcessor.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This usx processor is able to parse the contents of a single verse (range)
class USXVerseProcessor: USXContentProcessor
{
	// TYPES	-------------
	
	typealias Generated = Verse
	typealias Processed = CharData
	
	
	// ATTRIBUTES	---------
	
	private let range: VerseRange
	
	
	// INIT	-----------------
	
	init(range: VerseRange)
	{
		self.range = range
	}
	
	// Creates a new parser for usx verse contents
	// The parser should start after a verse marker
	// The parser will stop at the start of the next verse marker or at the end of the para element
	static func createVerseParser(caller: XMLParserDelegate, range: VerseRange, targetPointer: UnsafeMutablePointer<[Verse]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Verse, CharData>
	{
		let parser = USXContentParser<Verse, CharData>(caller: caller, containingElement: .para, lowestBreakMarker: .verse, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXVerseProcessor(range: range))
		
		return parser
	}
	
	
	// USX Parsing	---------
	
	func getParser(_ caller: USXContentParser<Verse, CharData>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[CharData]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// Delegates all parsing to chardata parsers
		return (USXCharParser(caller: caller, targetData: targetPointer), true)
	}
	
	func getCharacterParser(_ caller: USXContentParser<Verse, CharData>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[CharData]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// Delegates character parsing as well
		return USXCharParser(caller: caller, targetData: targetPointer)
	}
	
	func generate(from content: [CharData], using errorHandler: @escaping ErrorHandler) -> Verse?
	{
		// Parses the char data into a verse
		return Verse(range: range, content: content)
	}
}
