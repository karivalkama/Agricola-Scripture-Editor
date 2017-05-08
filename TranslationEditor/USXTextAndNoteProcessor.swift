//
//  USXTextElementProcessor.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

class USXTextAndNoteProcessor: USXContentProcessor
{
	// TYPES	-----------------
	
	typealias Generated = TextWithNotes
	typealias Processed = FootNote
	
	
	// ATTRIBUTES	-------------
	
	private var textElements = [TextElement]()
	private var lastCharData = [CharData]()
	private var crossReferences = [CrossReference]()
	
	
	// INIT	---------------------
	
	// Creates a new parser
	// The parser should start *after* verse or para element start
	// The parser will stop at the next verse marker or at the end of the para element
	static func createParser(caller: XMLParserDelegate, targetPointer: UnsafeMutablePointer<[Generated]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Generated, Processed>
	{
		let parser = USXContentParser<Generated, Processed>(caller: caller, containingElement: .para, lowestBreakMarker: .verse, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXTextAndNoteProcessor())
		
		return parser
	}
	
	
	// IMPLEMENTED METHODS	-----
	
	func getParser(_ caller: USXContentParser<TextWithNotes, FootNote>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[FootNote]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// In case of a note element, delegates the parsing to a footnote processor (cross reference notes are skipped at this time)
		if elementName == USXContainerElement.note.rawValue
		{
			if let styleString = attributes["style"], let callerAttribute = attributes["caller"]
			{
				if let style = FootNoteStyle(rawValue: styleString)
				{
					// A text element will always be inserted before a footnote
					textElements.add(TextElement(charData: lastCharData))
					lastCharData = []
					
					print("STATUS: Delegating '\(elementName)' to a FootNoteProcessor")
					return (USXFootNoteProcessor.createParser(caller: caller, callerAttValue: callerAttribute, style: style, targetPointer: targetPointer, using: errorHandler), false)
				}
				else if let style = CrossReferenceStyle(rawValue: styleString)
				{
					// Cross references are parsed separately from other data
					return (USXCrossReferenceProcessor.createParser(caller: caller, callerAttValue: callerAttribute, style: style, targetPointer: &crossReferences, using: errorHandler), false)
				}
				else
				{
					errorHandler(USXParseError.unknownNoteStyle(style: styleString))
					return nil
				}
			}
			else
			{
				errorHandler(USXParseError.attributeMissing(requiredAttributeName: attributes["style"] == nil ? "style" : "caller"))
				return nil
			}
		}
		// Char elements are parsed and prepared for the next text element
		else if elementName == USXContainerElement.char.rawValue
		{
			return (USXCharParser(caller: caller, targetData: &lastCharData), true)
		}
		else
		{
			print("ERROR: Unknown element '\(elementName)' received by USXTextAndNoteProcessor")
			return nil
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<Generated, Processed>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		return USXCharParser(caller: caller, targetData: &lastCharData)
	}
	
	func generate(from content: [Processed], using errorHandler: @escaping ErrorHandler) -> Generated?
	{
		// Parses the last text element
		textElements.add(TextElement(charData: lastCharData))
		lastCharData = []
		
		// TODO: Include cross references too
		let result = TextWithNotes(textElements: textElements, footNotes: content)
		textElements = []
		
		return result
	}
}
