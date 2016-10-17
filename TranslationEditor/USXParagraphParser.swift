//
//  USXParagraphParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 10.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

class USXParagraphProcessor: USXContentProcessor
{
	typealias Generated = Paragraph
	typealias Processed = Para
	
	
	// ATTRIBUTES	------------
	
	private var paragraphStyleFound = false
	private var sectionHeadingFound = false
	
	
	// USX PROCESSING	--------
	
	func getParser(_ caller: USXContentParser<Generated, Processed>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: (USXParseError) -> ()) -> (XMLParserDelegate, Bool)?
	{
		return nil
	}
	
	func generate(from content: [Processed], using errorHandler: (USXParseError) -> ()) -> Generated?
	{
		return nil
	}
	
	func getCharacterParser(_ caller: USXContentParser<Generated, Processed>, into targetPointer: UnsafeMutablePointer<[Processed]>, using errorHandler: (USXParseError) -> ()) -> XMLParserDelegate?
	{
		return nil
	}
}

// This USX parser parses the contents of a single paragraph. A paragraph may contain multple para elements.
// The starting point should be on a para element start.
// Always returns on a start of a para element, except in the case where a chapter element ends and there is no new para element to start
// Reusable inside a section
class USXParagraphParser: TemporaryXMLParser
{
	// ATTRIBUTES	-----------
	
	private let errorHandler: (USXParseError) -> ()
	private let targetPointer: UnsafeMutablePointer<[Paragraph]>
	
	private var currentParas = [Para]()
	private var contentParser: XMLParserDelegate?
	
	private var paragraphStyleFound = false
	private var sectionHeadingFound = false
	
	
	// INIT	------------
	
	init(caller: XMLParserDelegate, targetPointer: UnsafeMutablePointer<[Paragraph]>, using errorHandler: @escaping (USXParseError) -> ())
	{
		self.errorHandler = errorHandler
		self.targetPointer = targetPointer
		
		super.init(caller: caller)
	}
	
	
	// XML PARSER	--------
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		if elementName == "para"
		{
			var parseContents = true
			
			var style = ParaStyle.normal
			if let styleAttribute = attributeDict["style"]
			{
				style = ParaStyle.value(of: styleAttribute)
			}
			
			// Records when certain styles are found
			if style.isSectionHeadingStyle()
			{
				sectionHeadingFound = true
			}
			
			// Parsing is ended if a section heading is found after some content has already been parsed
			if sectionHeadingFound && !currentParas.isEmpty
			{
				closeParagraph()
				endParsingOnStartElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
				parseContents = false
			}
			// The paragraph may contain only a single "paragraph style" para element
			else if style.isParagraphStyle() || style.isHeaderStyle()
			{
				if paragraphStyleFound
				{
					parseContents = false
					closeParagraph()
					endParsingOnStartElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
				}
				else
				{
					paragraphStyleFound = true
				}
			}
			
			// Parses the contents of the para element
			if parseContents
			{
				contentParser = USXParaProcessor.createParaParser(caller: self, style: style, targetPointer: &currentParas, using: errorHandler)
				parser.delegate = contentParser
			}
		}
		// Always stops at the start of a new chapter
		else if elementName == "chapter"
		{
			closeParagraph()
			endParsingOnStartElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
		}
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
	{
		// Parsing may end after a section heading para element or at the end of the chapter
		if elementName == "para" && sectionHeadingFound
		{
			closeParagraph()
			endParsingOnEndElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
		}
		else if elementName == "usx"
		{
			closeParagraph()
			endParsingOnEndElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
		}
	}
	
	
	// OTHER	-----------
	
	private func closeParagraph()
	{
		targetPointer[0].append(Paragraph(content: currentParas))
		
		// Also resets settings
		currentParas = []
		paragraphStyleFound = false
		sectionHeadingFound = false
	}
}
