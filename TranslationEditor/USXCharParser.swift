//
//  USXCharParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This parser collects character data. Functions properly only within para elements
class USXCharParser: TemporaryXMLParser
{
	// ATTRIBUTES	---------
	
	private let charDataPointer: UnsafeMutablePointer<[CharData]>
	private var skipNoteParser: TemporaryXMLParser!
	
	private var currentText = ""
	private var currentStyle: CharStyle?
	
	
	// INIT	----------
	
	init(caller: XMLParserDelegate, targetData: UnsafeMutablePointer<[CharData]>)
	{
		self.charDataPointer = targetData
		
		super.init(caller: caller)
		
		self.skipNoteParser = SkipOverElementParser(elementName: "note", caller: self)
	}
	
	
	// XML DELEGATE	-----
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		switch elementName
		{
		case "verse":
			// When a new verse starts, ends parsing
			closeCurrentChar()
			endParsingOnStartElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
		case "char":
			// When a new char element starts, closes the previous one and starts a new one
			closeCurrentChar()
			if let newStyleAttribute = attributeDict["style"]
			{
				currentStyle = CharStyle(rawValue: newStyleAttribute)
			}
		case "note":
			// When a note element is found, skips it
			// TODO: Add parsing for notes as well
			parser.delegate = skipNoteParser
		default: break
		}
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
	{
		switch elementName
		{
		case "char":
			// When a char element ends it is recorded
			closeCurrentChar()
		case "para":
			// When a para element ends, quits parsing
			closeCurrentChar()
			endParsingOnEndElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
		default: break
		}
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String)
	{
		// Whenever text data is found, it is appended to the character data
		currentText.append(string)
	}
	
	
	// OTHER	--------
	
	private func closeCurrentChar()
	{
		if !currentText.isEmpty
		{
			if let lastData = charDataPointer[0].last, lastData.style == currentStyle
			{
				charDataPointer[0][charDataPointer[0].count - 1] = lastData.appended(currentText)
			}
			else
			{
				charDataPointer[0].append(CharData(text: currentText, style: currentStyle))
			}
			
			currentText = ""
			currentStyle = nil
		}
	}
}
