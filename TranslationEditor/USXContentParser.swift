//
//  USXParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// ErrorHandling type is named
typealias ErrorHandler = (Error) -> ()

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
	func getParser(_ caller: USXContentParser<Generated, Processed>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	
	// Generates a piece of content based on the collected data
	func generate(from content: [Processed], using errorHandler: @escaping ErrorHandler) -> Generated?
	
	// Finds a suitable element parser for found character data. The provided parser will be called based on the data after it has been provided.
	func getCharacterParser(_ caller: USXContentParser<Generated, Processed>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
}

// This is a type erasure implementation for protocol: USXContentProcessor
class AnyUSXContentProcessor<G, P>: USXContentProcessor
{
	typealias Generated = G
	typealias Processed = P
	
	private let _generate: ([P], @escaping ErrorHandler) -> G?
	private let _getParser: (USXContentParser<G, P>, String, [String : String], UnsafeMutablePointer<[P]>, @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	private let _getCharacterParser: (USXContentParser<G, P>, String, UnsafeMutablePointer<[P]>, @escaping ErrorHandler) -> XMLParserDelegate?
	
	required init<A: USXContentProcessor>(_ processor: A) where A.Generated == G, A.Processed == P
	{
		self._generate = processor.generate
		self._getParser = processor.getParser
		self._getCharacterParser = processor.getCharacterParser
	}
	
	func generate(from content: [P], using errorHandler: @escaping ErrorHandler) -> G?
	{
		//print("STATUS: GENERATE CALLED")
		return _generate(content, errorHandler)
	}
	
	func getParser(_ caller: USXContentParser<G, P>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[P]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		//print("STATUS: GET PARSER CALLED")
		return _getParser(caller, elementName, attributes, targetPointer, errorHandler)
	}
	
	func getCharacterParser(_ caller: USXContentParser<G, P>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[P]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		//print("STATUS: GET CHAR PARSER CALLED")
		return _getCharacterParser(caller, string, targetPointer, errorHandler)
	}
}

// USX Content parsers are used for parsing through most of the USX content.
// A USX Content parser needs a USX Content processor in order to generate content
class USXContentParser<Generated, Contained>: NSObject, XMLParserDelegate // If extends temporary xml parser, no delegate methods get called
{
	// ATTRIBUTES	---------
	
	private let returner: XMLParsingReturner
	
	private let errorHandler: ErrorHandler
	private let targetPointer: UnsafeMutablePointer<[Generated]>
	
	private let containingElement: USXContainerElement
	private let lowestBreakMarker: USXMarkerElement
	
	private var parsedContent = [Contained]()
	private var contentParser: XMLParserDelegate?
	
	// This flag can be used for setting the parser to stop parsing once a specific marker is found
	var nextStopMarker: USXMarkerElement?
	// This flag can be used for setting the parser to stop parsing once the end of a certain container element is reached
	var nextStopContainer: USXContainerElement?
	// This flag can be used for forcing the parser to stop parsing as soon as possible
	var stopsAfterCurrentParse = false
	
	var processor: AnyUSXContentProcessor<Generated, Contained>?
	
	
	// INIT	-----------------
	
	init(caller: XMLParserDelegate, containingElement: USXContainerElement, lowestBreakMarker: USXMarkerElement, targetPointer: UnsafeMutablePointer<[Generated]>,using errorHandler: @escaping ErrorHandler)
	{
		//print("STATUS: Instantiated new USX content parser")
		
		self.errorHandler = errorHandler
		self.targetPointer = targetPointer
		
		self.containingElement = containingElement
		self.lowestBreakMarker = lowestBreakMarker
		
		self.returner = XMLParsingReturner(originalDelegate: caller)
	}
	
	
	// XML PARSING	---------
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		//print("STATUS: New element: '\(elementName)'")
		
		// The parser may be set to stop parsing at a start of a certain marker
		// Also ends parsing when finding a higher level 'marker' element
		if let marker = USXMarkerElement(rawValue: elementName), marker >= lowestBreakMarker || marker == nextStopMarker
		{
			closeCurrentElement()
			returner.endParsingOnStartElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
		}
		// Otherwise delegates parsing to another temporary parser (processor's decision)
		else
		{
			if let (delegateParser, shouldCallElement) = processor?.getParser(self, forElement: elementName, attributes: attributeDict, into: &parsedContent, using: handleErrorAndStop)
			{
				delegateParsing(of: parser, to: delegateParser)
				if shouldCallElement
				{
					delegateParser.parser?(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
				}
			}
			
			// Stops after parsing if a flag was set during parsing
			if stopsAfterCurrentParse
			{
				// TODO: there's a risk of stackoverflow here since calling super parser start element may lead to calling this parser again. At least a single element should always be parsed before setting the flag.
				closeCurrentElement()
				returner.endParsingOnStartElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
			}
		}
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
	{
		//print("STATUS: END ELEMENT \(elementName)")
		
		// Ends parsing at the end of the containing element
		// Also may be set to end parsing at the end of a certain container element
		if let element = USXContainerElement(rawValue: elementName), element == containingElement || element == nextStopContainer
		{
			closeCurrentElement()
			returner.endParsingOnEndElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
		}
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String)
	{
		//print("STATUS: CHARACTERS")
		
		// Ignores characters which consist only of whitespace
		if !string.trimmingCharacters(in: CharacterSet(charactersIn: " \t\n\r")).isEmpty
		{
			// When character data is found, may assign a new deleage to handle the parsing
			if let delegateParser = processor?.getCharacterParser(self, forCharacters: string, into: &parsedContent, using: handleErrorAndStop)
			{
				delegateParsing(of: parser, to: delegateParser)
				delegateParser.parser?(parser, foundCharacters: string)
			}
			
			// Stops after parsing if a flag was set
			if stopsAfterCurrentParse
			{
				closeCurrentElement()
				returner.endParsingOnCharacters(parser: parser, characters: string)
			}
		}
	}
	
	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error)
	{
		//print("ERROR: Parse error occurred. \(parseError)")
		errorHandler(parseError)
	}
	
	
	// OTHER	-------------
	
	private func handleErrorAndStop(error: Error)
	{
		// Immediately stops parsing
		stopsAfterCurrentParse = true
		// Informs the original error handler
		errorHandler(error)
	}
	
	private func delegateParsing(of parser: XMLParser, to delegate: XMLParserDelegate)
	{
		// Assigns the new parser
		self.contentParser = delegate
		parser.delegate = delegate
	}
	
	private func closeCurrentElement()
	{
		if let generated = processor?.generate(from: parsedContent, using: errorHandler)
		{
			targetPointer[0].append(generated)
			
			// Empties collected data
			parsedContent = []
			contentParser = nil
			nextStopMarker = nil
			nextStopContainer = nil
			stopsAfterCurrentParse = false
		}
	}
}
