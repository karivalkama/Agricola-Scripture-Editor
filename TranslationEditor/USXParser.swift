//
//  USXParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// USXContentProcessor is used in USXContentParser to handle lower level data
protocol USXContentProcessor
{
	// The type of object generated trhough this processor
	associatedtype Generated
	// The type of object collected by this processor (from which the generated resource is combined)
	associatedtype Processed
	
	// Finds a suitable element parser for the provided element. 
	// Also returns whether the provided element should be relayed to the parser
	// Returns nil if no parser should be used for the element at this time
	func getParser(_ caller: USXContentParser<Generated, Processed>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: (USXParseError) -> ()) -> (XMLParserDelegate, Bool)?
	
	// Generates a piece of content based on the collected data
	func generate(from content: [Processed], using errorHandler: (USXParseError) -> ()) -> Generated?
	
	// Finds a suitable element parser for found character data. The provided parser will be called based on the data after it has been provided.
	func getCharacterParser(_ caller: USXContentParser<Generated, Processed>, into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: (USXParseError) -> ()) -> XMLParserDelegate?
}

// This is a type erasure implementation for protocol: USXContentProcessor
class AnyUSXContentProcessor<G, P>: USXContentProcessor
{
	typealias Generated = G
	typealias Processed = P
	
	private let _generate: ([P], (USXParseError) -> ()) -> G?
	private let _getParser: (USXContentParser<G, P>, String, [String : String], UnsafeMutablePointer<[P]>, (USXParseError) -> ()) -> (XMLParserDelegate, Bool)?
	private let _getCharacterParser: (USXContentParser<G, P>, UnsafeMutablePointer<[P]>, (USXParseError) -> ()) -> XMLParserDelegate?
	
	required init<A: USXContentProcessor>(_ processor: A) where A.Generated == G, A.Processed == P
	{
		self._generate = processor.generate
		self._getParser = processor.getParser
		self._getCharacterParser = processor.getCharacterParser
	}
	
	func generate(from content: [P], using errorHandler: (USXParseError) -> ()) -> G?
	{
		return _generate(content, errorHandler)
	}
	
	func getParser(_ caller: USXContentParser<G, P>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[P]>, using errorHandler: (USXParseError) -> ()) -> (XMLParserDelegate, Bool)?
	{
		return _getParser(caller, elementName, attributes, targetPointer, errorHandler)
	}
	
	func getCharacterParser(_ caller: USXContentParser<G, P>, into targetPointer: UnsafeMutablePointer<[P]>, using errorHandler: (USXParseError) -> ()) -> XMLParserDelegate?
	{
		return _getCharacterParser(caller, targetPointer, errorHandler)
	}
}

// USX Content parsers are used for parsing through most of the USX content.
// A USX Content parser needs a USX Content processor in order to generate content
class USXContentParser<Generated, Contained>: TemporaryXMLParser
{
	// ATTRIBUTES	---------
	
	private let errorHandler: (USXParseError) -> ()
	private let targetPointer: UnsafeMutablePointer<[Generated]>
	
	private let containingElement: USXContainerElement
	private let lowestBreakMarker: USXMarkerElement
	
	private var parsedContent = [Contained]()
	private var contentParser: XMLParserDelegate?
	
	var processor: AnyUSXContentProcessor<Generated, Contained>?
	
	
	// INIT	-----------------
	
	init(caller: XMLParserDelegate, containingElement: USXContainerElement, lowestBreakMarker: USXMarkerElement, targetPointer: UnsafeMutablePointer<[Generated]>,using errorHandler: @escaping (USXParseError) -> ())
	{
		self.errorHandler = errorHandler
		self.targetPointer = targetPointer
		
		self.containingElement = containingElement
		self.lowestBreakMarker = lowestBreakMarker
		
		super.init(caller: caller)
	}
	
	
	// XML PARSING	---------
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		// Ends parsing when finding a higher level 'marker' element
		if let marker = USXMarkerElement(rawValue: elementName), marker >= lowestBreakMarker
		{
			closeCurrentElement()
			endParsingOnStartElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
		}
		// Otherwise delegates parsing to another temporary parser (processor's decision)
		else
		{
			if let (delegateParser, shouldCallElement) = processor?.getParser(self, forElement: elementName, attributes: attributeDict, into: &parsedContent, using: errorHandler)
			{
				self.contentParser = delegateParser
				parser.delegate = delegateParser
				if shouldCallElement
				{
					delegateParser.parser?(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
				}
			}
		}
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
	{
		// Ends parsing at the end of the containing element
		if let element = USXContainerElement(rawValue: elementName), element == containingElement
		{
			closeCurrentElement()
			endParsingOnEndElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
		}
	}
	
	
	// OTHER	-------------
	
	private func closeCurrentElement()
	{
		if let generated = processor?.generate(from: parsedContent, using: errorHandler)
		{
			targetPointer[0].append(generated)
			
			// Empties collected data
			parsedContent = []
			contentParser = nil
		}
	}
}
