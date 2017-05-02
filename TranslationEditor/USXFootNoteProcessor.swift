//
//  USXFootNoteProcessor.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

class USXFootNoteProcessor: USXContentProcessor
{
	// TYPES	------------------------
	
	typealias Generated = FootNote
	typealias Processed = CharData
	
	
	// ATTRIBUTES	--------------------
	
	private let caller: String
	private let style: FootNoteStyle
	
	
	// INIT	----------------------------
	
	init(caller: String, style: FootNoteStyle)
	{
		self.caller = caller
		self.style = style
	}
	
	// Creates a new parser for a note element
	// The parser should start after the note element
	// The parser will stop at the end of the note element (or at the next verse marker, if the content is somehow malformed like that)
	static func createFootNoteParser(caller: XMLParserDelegate, callerAttValue: String, style: FootNoteStyle, targetPointer: UnsafeMutablePointer<[FootNote]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<FootNote, CharData>
	{
		let parser = USXContentParser<Generated, Processed>(caller: caller, containingElement: .note, lowestBreakMarker: .verse, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXFootNoteProcessor(caller: callerAttValue, style: style))
		
		return parser
	}
	
	
	// IMPLEMENTED METHODS	------------
	
	func getParser(_ caller: USXContentParser<FootNote, CharData>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[CharData]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// Delegates parsing to a char parser
		if elementName == USXContainerElement.char.rawValue
		{
			return (USXCharParser(caller: caller, targetData: targetPointer), true)
		}
		else
		{
			return nil
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<FootNote, CharData>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[CharData]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// Delegates all character data parsing to a char parser too
		return USXCharParser(caller: caller, targetData: targetPointer)
	}
	
	func generate(from content: [CharData], using errorHandler: @escaping ErrorHandler) -> FootNote?
	{
		// TODO: Handle fr (origin reference) after refactoring charTypes
		return FootNote(caller: caller, style: style, originReference: nil, charData: content)
	}
}
