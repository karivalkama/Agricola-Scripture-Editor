//
//  USXParaParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This temporary XML parser parses the contents of a single para element. Should be used only inside para elements
class USXParaParser: TemporaryXMLParser
{
	// ATTRIBUTES	--------
	
	private let style: ParaStyle
	private let paraPointer: UnsafeMutablePointer<Para>
	private let errorHandler: (USXParseError) -> ()
	
	private var initialCharData = [CharData]()
	private var parsedVerses = [Verse]()
	
	private var currentVerseIndex: VerseIndex?
	private var currentVerseData = [CharData]()
	
	private var contentParser: USXCharParser?
	
	
	// INIT	------
	
	init(caller: XMLParserDelegate, style: ParaStyle, targetPointer: UnsafeMutablePointer<Para>, using errorHandler: @escaping (USXParseError) -> ())
	{
		self.style = style
		self.paraPointer = targetPointer
		self.errorHandler = errorHandler
		
		super.init(caller: caller)
	}
	
	
	// XML PARSING	----
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		switch elementName
		{
		case "verse":
			// On a new verse marker, starts reading verse data
			if let verseIndexAttribute = attributeDict["number"], let index = Int(verseIndexAttribute)
			{
				// Closes the existing verse and starts a new one
				closeCurrentVerse(endIndex: VerseIndex(index))
				
				// The contents are read using a char parser
				contentParser = USXCharParser(caller: self, targetData: &currentVerseData)
				parser.delegate = contentParser
			}
			else
			{
				errorHandler(USXParseError.verseIndexNotFound)
			}
		case "char":
			// Character data may be the first opened element -> moved to a charData parser
			contentParser = USXCharParser(caller: self, targetData: &initialCharData)
			parser.delegate = contentParser
			contentParser?.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
		default: break
		}
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
	{
		if elementName == "para"
		{
			// When the end of the para element is reached, returns back to the original delegate
			// Also saves the collected data
			if let lastVerseIndex = currentVerseIndex
			{
				// The end index must be calculated based on the last index marker
				closeCurrentVerse(endIndex: VerseIndex(lastVerseIndex.index, midVerse: true))
			}
			
			// Parses the initial character data into a verse, if possible
			if let firstVerse = parsedVerses.first
			{
				if !initialCharData.isEmpty
				{
					let firstVerseIndex = firstVerse.range.start
					parsedVerses.insert(Verse(range: VerseRange(VerseIndex(firstVerseIndex.index - 1, midVerse: true), firstVerseIndex), content: initialCharData), at: 0)
				}
				
				paraPointer[0] = Para(content: parsedVerses, style: style)
			}
				// If there were no verses, records content as it is
			else
			{
				paraPointer[0] = Para(content: initialCharData, style: style)
			}
			
			endParsingOnEndElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
		}
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String)
	{
		// If character data is found, it is given to a separate parser
		contentParser = USXCharParser(caller: self, targetData: &initialCharData)
		parser.delegate = contentParser
		contentParser?.parser(parser, foundCharacters: string)
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
