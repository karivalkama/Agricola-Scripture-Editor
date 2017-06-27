//
//  XmlParserUtil.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class used to be a super class until swift 4 and breakdown of pretty much everything
// Now this class offers utility methods that return the parsing to the original xml parser delegate
class XMLParsingReturner
{
	// ATTRIBUTES	--------
	
	// TODO: Reference should be weak?
	private weak var caller: XMLParserDelegate?
	
	
	// INIT	----------------
	
	init(originalDelegate: XMLParserDelegate)
	{
		self.caller = originalDelegate
	}
	
	
	// OTHER	------------
	
	// Moves the parsing responsibility back to the original delegate
	func endParsing(parser: XMLParser)
	{
		parser.delegate = caller
	}
	
	// Ends the temporary parser's responsibility and calls start element of the original parser delegate
	func endParsingOnStartElement(parser: XMLParser, elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		endParsing(parser: parser)
		caller?.parser?(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
	}
	
	// Ends the temporary parser's responsibility and calls end element of the original parser delegate
	func endParsingOnEndElement(parser: XMLParser, elementName: String, namespaceURI: String?, qualifiedName qName: String?)
	{
		endParsing(parser: parser)
		caller?.parser?(parser, didEndElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
	}
	
	func endParsingOnCharacters(parser: XMLParser, characters: String)
	{
		endParsing(parser: parser)
		caller?.parser?(parser, foundCharacters: characters)
	}
}


// This parser ignores all data until an element with a specific name is found, at which point the parsing is returned to the original delegate
class MoveToElementWithNameParser: NSObject, XMLParserDelegate
{
	// ATTRIBUTES	--------
	
	private let searchedName: String
	private let returner: XMLParsingReturner
	
	
	// INIT	----------------
	
	init(find elementName: String, caller: XMLParserDelegate)
	{
		self.searchedName = elementName
		returner = XMLParsingReturner(originalDelegate: caller)
	}
	
	
	// XML PARSING	--------
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		if elementName == searchedName
		{
			returner.endParsingOnStartElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
		}
	}
}

// This parser ignores all data until the end of the (current) element is reached. Afterwards the parsing is returned to the original delegate. Doesn't call the endElement method of the original delegate upon ending
class SkipOverElementParser: NSObject, XMLParserDelegate
{
	// ATTRIBUTES	-----
	
	private let returner: XMLParsingReturner
	private let elementName: String
	private var depth = 0
	
	
	// INIT	-------------
	
	init(elementName: String, caller: XMLParserDelegate)
	{
		self.elementName = elementName
		returner = XMLParsingReturner(originalDelegate: caller)
	}
	
	
	// XML PARSING	-----
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		if elementName == self.elementName
		{
			depth += 1
		}
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
	{
		if elementName == self.elementName
		{
			depth -= 1
			
			if depth < 0
			{
				returner.endParsing(parser: parser)
			}
		}
	}
}

class TestPrintXMLParseDelegate: NSObject, XMLParserDelegate
{
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		print("STATUS: Test parser found start element '\(elementName)'")
	}
}
