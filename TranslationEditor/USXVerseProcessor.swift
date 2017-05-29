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
	typealias Processed = TextWithNotes
	
	
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
	static func createVerseParser(caller: XMLParserDelegate, range: VerseRange, targetPointer: UnsafeMutablePointer<[Generated]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Generated, Processed>
	{
		let parser = USXContentParser<Generated, Processed>(caller: caller, containingElement: .para, lowestBreakMarker: .verse, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXVerseProcessor(range: range))
		
		return parser
	}
	
	
	// USX Parsing	---------
	
	func getParser(_ caller: USXContentParser<Generated, Processed>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// Delegates all parsing to text & footnote parsers
		return (USXTextAndNoteProcessor.createParser(caller: caller, lastVerseIndex: range.start, targetPointer: targetPointer, using: errorHandler), elementName != USXMarkerElement.verse.rawValue)
	}
	
	func getCharacterParser(_ caller: USXContentParser<Generated, Processed>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		return USXTextAndNoteProcessor.createParser(caller: caller, lastVerseIndex: range.start, targetPointer: targetPointer, using: errorHandler)
	}
	
	func generate(from content: [Processed], using errorHandler: @escaping ErrorHandler) -> Verse?
	{
		// Produces verse content based on the collected data
		if content.isEmpty
		{
			return Verse(range: range)
		}
		else
		{
			return Verse(range: range, content: content.dropFirst().reduce(content.first!, + ))
		}
	}
}
