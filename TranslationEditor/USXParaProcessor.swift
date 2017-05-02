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
	private var initialTextData = [TextWithFootnotes]()
	
	
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
		// Other content is delegated to separate Text / Note parser
		else
		{
			return (USXTextAndNoteProcessor.createParser(caller: caller, targetPointer: &initialTextData, using: errorHandler), true)
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<Para, Verse>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Verse]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// character parsing is delegated to separate text / note parser
		return USXTextAndNoteProcessor.createParser(caller: caller, targetPointer: &initialTextData, using: errorHandler)
	}
	
	func generate(from content: [Verse], using errorHandler: @escaping ErrorHandler) -> Para?
	{
		// The para is generated differently if verses haven't been parsed
		if content.isEmpty
		{
			if initialTextData.isEmpty
			{
				return Para(content: TextWithFootnotes(), style: style)
			}
			else
			{
				return Para(content: initialTextData.dropFirst().reduce(initialTextData.first!, + ), style: style)
			}
		}
		else
		{
			var allVerses = content
			
			// if there is some initial data, appends it before the first verse
			if !initialTextData.isEmpty
			{
				let endIndex = content.first!.range.start
				let startIndex = VerseIndex(endIndex.index - 1, midVerse: true)
				
				allVerses.insert(Verse(range: VerseRange(startIndex, endIndex), content: initialTextData.dropFirst().reduce(initialTextData.first!, + )), at: 0)
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
