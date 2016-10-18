//
//  USXParaParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

class USXParaProcessor: USXContentProcessor
{
	// TYPES	-----------
	
	typealias Generated = Para
	typealias Processed = Verse
	
	
	// ATTRIBUTES	-------
	
	private static var _verseRegex: NSRegularExpression?
	private static var verseRegex: NSRegularExpression
	{
		if _verseRegex == nil
		{
			do
			{
				_verseRegex = try NSRegularExpression(pattern: "\\-\\,", options: [])
			}
			catch
			{
				fatalError("Couldn't create regular expression")
			}
		}
		
		return _verseRegex!
	}
	
	private let style: ParaStyle
	private var initialCharData = [CharData]()
	
	
	// INIT	---------------
	
	init(style: ParaStyle)
	{
		self.style = style
	}
	
	// Creates a new para parser using an instance of USXParaProcessor. The parser should be used at or after the start of a para element.
	// It will stop parsing at the end of the para element
	static func createParaParser(caller: XMLParserDelegate, style: ParaStyle, targetPointer: UnsafeMutablePointer<[Para]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Para, Verse>
	{
		let parser = USXContentParser<Para, Verse>(caller: caller, containingElement: .para, lowestBreakMarker: .chapter, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXParaProcessor(style: style))
		return parser
	}
	
	
	// USX PARSING	-------
	
	func getParser(_ caller: USXContentParser<Para, Verse>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Verse]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// Contents after verse markers are deleagted to verse parsers
		if elementName == USXMarkerElement.verse.rawValue
		{
			// Parses the verse range from the number attribute
			var range: VerseRange?
			if let numberAttribute = attributes["number"]
			{
				let parts = numberAttribute.components(separatedBy: USXParaProcessor.verseRegex, trim: true)
				
				if parts.count == 1
				{
					if let index = Int(parts[0])
					{
						range = VerseRange(VerseIndex(index), VerseIndex(index + 1))
					}
					else
					{
						errorHandler(USXParseError.verseIndexParsingFailed(indexAttribute: numberAttribute))
						return nil
					}
				}
				else
				{
					if let startIndex = Int(parts[0]), let endIndex = Int(parts[1])
					{
						range = VerseRange(VerseIndex(startIndex), VerseIndex(endIndex + 1))
					}
					else
					{
						errorHandler(USXParseError.verseIndexParsingFailed(indexAttribute: numberAttribute))
						return nil
					}
				}
			}
			else
			{
				errorHandler(USXParseError.verseIndexNotFound)
				return nil
			}
			
			if let range = range
			{
				return (USXVerseProcessor.createVerseParser(caller: caller, range: range, targetPointer: targetPointer, using: errorHandler), false)
			}
			else
			{
				errorHandler(USXParseError.verseRangeParsingFailed)
				return nil
			}
		}
		// Other content is delegated to separate character parser
		else
		{
			return (USXCharParser(caller: caller, targetData: &initialCharData), true)
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<Para, Verse>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Verse]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// character parsing is delegated to separate char parser
		return USXCharParser(caller: caller, targetData: &initialCharData)
	}
	
	func generate(from content: [Verse], using errorHandler: @escaping ErrorHandler) -> Para?
	{
		// The para is generated differently if verses have or haven't been parsed
		if content.isEmpty
		{
			return Para(content: initialCharData, style: style)
		}
		else
		{
			var allVerses = content
			
			// if there is some initial data, appends it before the first verse
			if !initialCharData.isEmpty
			{
				let endIndex = content.first!.range.start
				let startIndex = VerseIndex(endIndex.index - 1, midVerse: true)
				
				allVerses.insert(Verse(range: VerseRange(startIndex, endIndex), content: initialCharData), at: 0)
			}
			
			// Decreases the last verse's range to midverse (unless already)
			let lastVerse = allVerses.last!
			if !lastVerse.range.end.midVerse
			{
				lastVerse.range = VerseRange(lastVerse.range.start, VerseIndex(lastVerse.range.end.index - 1, midVerse: true))
			}
			
			return Para(content: allVerses, style: style)
		}
	}
}

/*
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
	static func createParaParser(caller: XMLParserDelegate, style: ParaStyle, targetPointer: UnsafeMutablePointer<[Para]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Para, CharData>
	{
		let parser = USXContentParser<Para, CharData>(caller: caller, containingElement: .para, lowestBreakMarker: .chapter, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXParaProcessor(style: style))
		return parser
	}
	
	
	// USX PROCESSING	-----
	
	func getParser(_ caller: USXContentParser<Para, CharData>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[CharData]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
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
	
	func generate(from content: [CharData], using errorHandler: @escaping ErrorHandler) -> Para?
	{
		// When the end is reached, finalises the collected data
		// The last verse is closed
		if let lastVerseIndex = currentVerseIndex
		{
			// The end index must be calculated based on the last index marker
			closeCurrentVerse(endIndex: VerseIndex(lastVerseIndex.index, midVerse: true))
		}
		
		var parsedPara: Para?
		
		// Parses the initial character data into a verse, if possible
		if let firstVerse = parsedVerses.first
		{
			if !content.isEmpty
			{
				let firstVerseIndex = firstVerse.range.start
				parsedVerses.insert(Verse(range: VerseRange(VerseIndex(firstVerseIndex.index - 1, midVerse: true), firstVerseIndex), content: content), at: 0)
			}
			
			parsedPara = Para(content: parsedVerses, style: style)
		}
		// If there were no verses, records content as it is
		else
		{
			parsedPara = Para(content: content, style: style)
		}
		
		// Clears the memory so that the processor may be reused
		parsedVerses = []
		currentVerseIndex = nil
		currentVerseData = []
		
		return parsedPara
	}
	
	func getCharacterParser(_ caller: USXContentParser<Para, CharData>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[CharData]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
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
}*/
