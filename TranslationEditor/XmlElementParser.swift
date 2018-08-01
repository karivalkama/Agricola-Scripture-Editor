//
//  XmlElementParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 1.8.2018.
//  Copyright © 2018 Mikko Hilpinen. All rights reserved.
//

import Foundation

class XmlElementParser
{
	// Uses an xml parser to parse the root element. Asynchronous
	static func parseAsync(makeParser: @escaping () throws -> XMLParser) -> Promise<XmlElement>
	{
		// Creates the delegate
		let delegate = MainParsingDelegate()
		
		// Starts xml parsing in another thread
		DispatchQueue.global().async
			{
				do
				{
					let parser = try makeParser()
					parser.delegate = delegate
					parser.parse()
				}
				catch
				{
					delegate.result.fail(with: error)
				}
		}
		
		return delegate.result
	}
	
	// Uses an xml parser to parse the root element. Synchronous
	static func parseSync(makeParser: () throws -> XMLParser) -> Try<XmlElement>
	{
		do
		{
			let parser = try makeParser()
			let delegate = MainParsingDelegate()
			parser.delegate = delegate
			parser.parse()
			
			return delegate.result.currentItem!
		}
		catch
		{
			return Try<XmlElement>.failure(error)
		}
	}
}

class XmlElementParserDelegate: NSObject, XMLParserDelegate
{
	// ATTRIBUTES	------------------
	
	let result = Promise<XmlElement>()
	
	private let returner: XMLParsingReturner?
	private let elementName: String
	private let attributes: [String: String]
	
	private var text = ""
	private var children: [XmlElement] = []
	
	private var currentChildParser: XMLParserDelegate?
	
	
	// INIT	--------------------------
	
	init(caller: XMLParserDelegate?, elementName: String, attributes: [String: String])
	{
		self.returner = caller.map { XMLParsingReturner(originalDelegate: $0) }
		self.elementName = elementName
		self.attributes = attributes
	}
	
	
	// IMPLEMENTED	-------------------
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:])
	{
		// When a new element is found, delegates the parsing to another element parser
		let childParser = XmlElementParserDelegate(caller: self, elementName: elementName, attributes: attributeDict)
		currentChildParser = childParser
		parser.delegate = childParser
		
		// Adds the parsed element as a child when it is available
		childParser.result.handle(onSuccess: { self.children.add($0) }, onFailure: { self.result.fail(with: $0) })
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
	{
		// When the element is finished, succeeds and stops parsing
		result.succeed(with: XmlElement(name: elementName, text: text, attributes: attributes, children: children))
		returner?.endParsing(parser: parser)
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String)
	{
		// When character data is found, appends it to text
		text += string
	}
	
	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error)
	{
		// Parsing fails on any error, original delegate is returned
		// Doesn't fail a second time, however
		if result.isEmpty
		{
			result.fail(with: parseError)
		}
		returner?.endParsingOnError(parser: parser, error: parseError)
	}
}

fileprivate class MainParsingDelegate: NSObject, XMLParserDelegate
{
	// ATTRIBUTES	----------------
	
	let result = Promise<XmlElement>()
	
	private var currentDelegate: XmlElementParserDelegate?
	
	
	// INIT	------------------------
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:])
	{
		// Delegates parsing to xml element parser
		let delegate = XmlElementParserDelegate(caller: self, elementName: elementName, attributes: attributeDict)
		currentDelegate = delegate
		parser.delegate = delegate
		
		delegate.result.handle(onSuccess: { self.result.succeed(with: $0) }, onFailure: { self.result.fail(with: $0) })
	}
	
	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error)
	{
		if result.isEmpty
		{
			result.fail(with: parseError)
		}
	}
}
