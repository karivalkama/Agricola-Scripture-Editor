//
//  USXParaParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This processor is used when parsing para element contents
class USXParaProcessor: USXContentProcessor
{
	typealias Generated = Para
	typealias Processed = CharData
	
	
	// ATTRIBUTES	--------
	
	private let style: ParaStyle
	
	private var parsedVerses = [Verse]()
	
	private var currentVerseIndex: VerseIndex?
	private var currentVerseData = [CharData]()
	
	
	// INIT	------
	
	init(style: ParaStyle)
	{
		self.style = style
	}
	
	// Creates a new para parser using an instance of USXParaProcessor. The parser should be used at or after the start of a para element. 
	// It will stop parsing at the end of the para element
	static func createParaParser(caller: XMLParserDelegate, style: ParaStyle, targetPointer: UnsafeMutablePointer<[Para]>, using errorHandler: @escaping (USXParseError) -> ()) -> USXContentParser<Para, CharData>
	{
		let parser = USXContentParser<Para, CharData>(caller: caller, containingElement: .para, lowestBreakMarker: .chapter, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXParaProcessor(style: style))
		return parser
	}
	
	
	// USX PROCESSING	-----
	
	func getParser(_ caller: USXContentParser<Generated, Processed>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: (USXParseError) -> ()) -> (XMLParserDelegate, Bool)?
	{
		// On a new verse marker, starts reading verse data
		if elementName == USXMarkerElement.verse.rawValue
		{
			if let verseIndexAttribute = attributes["number"], let index = Int(verseIndexAttribute)
			{
				// Closes the existing verse and starts a new one
				closeCurrentVerse(endIndex: VerseIndex(index))
				
				// The contents are read using a char parser
				// The data is not directly read to the provided pointer but to a separate array since it has to be processed into verses first
				return (USXCharParser(caller: caller, targetData: &currentVerseData), false)
			}
			else
			{
				errorHandler(USXParseError.verseIndexNotFound)
				return nil
			}
		}
		// Character data may be the first opened element -> moved to a charData parser
		else if elementName == USXContainerElement.char.rawValue
		{
			return (USXCharParser(caller: caller, targetData: targetPointer), true)
		}
		else
		{
			return nil
		}
	}
	
	func generate(from content: [Processed], using errorHandler: (USXParseError) -> ()) -> Generated?
	{
		// When the end is reached, finalises the collected data
		// The last verse is closed
		if let lastVerseIndex = currentVerseIndex
		{
			// The end index must be calculated based on the last index marker
			closeCurrentVerse(endIndex: VerseIndex(lastVerseIndex.index, midVerse: true))
		}
		
		// Parses the initial character data into a verse, if possible
		if let firstVerse = parsedVerses.first
		{
			if !content.isEmpty
			{
				let firstVerseIndex = firstVerse.range.start
				parsedVerses.insert(Verse(range: VerseRange(VerseIndex(firstVerseIndex.index - 1, midVerse: true), firstVerseIndex), content: content), at: 0)
			}
			
			return Para(content: parsedVerses, style: style)
		}
		// If there were no verses, records content as it is
		else
		{
			return Para(content: content, style: style)
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<Generated, Processed>, into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: (USXParseError) -> ()) -> XMLParserDelegate?
	{
		return USXCharParser(caller: caller, targetData: targetPointer)
	}
	
	
	// OTHER	--------
	
	private func closeCurrentVerse(endIndex: VerseIndex)
	{
		if let index = currentVerseIndex
		{
			// If there was no character data parsed, tries to append the range of the previous verse instead of creating a new one
			if let lastVerse = parsedVerses.last, currentVerseData.isEmpty
			{
				lastVerse.range = lastVerse.range.extended(to: endIndex)
			}
			else
			{
				parsedVerses.append(Verse(range: VerseRange(index, endIndex), content: currentVerseData))
			}
		}
		
		currentVerseIndex = endIndex
		currentVerseData = []
	}
}
