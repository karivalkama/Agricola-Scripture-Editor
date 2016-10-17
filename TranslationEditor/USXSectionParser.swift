//
//  USXSectionParser.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 10.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This temporary xml parser parses the contents of a single section based on USX data.
// The parser should be started at the start of a para element or right AFTER the start of a chapter element
// The parser will return either: a) at the start of a section heading element or b) at the start of a new chapter element
class USXSectionParser: TemporaryXMLParser
{
	// ATTRIBUTES	--------
	
	private let errorHandler: (USXParseError) -> ()
	private let targetPointer: UnsafeMutablePointer<[Section]>
	
	private var contentParser: XMLParserDelegate?
	private var parsedContent = [Paragraph]()
	
	private var sectionHeadingFound = false
	
	
	// INIT	----------------
	
	init(caller: XMLParserDelegate, targetPointer: UnsafeMutablePointer<[Section]>, using errorHandler: @escaping (USXParseError) -> ())
	{
		self.errorHandler = errorHandler
		self.targetPointer = targetPointer
		
		super.init(caller: caller)
	}
	
	
	// XML PARSING	--------
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		if elementName == "para"
		{
			var parseContents = true
			
			// Section heading elements are checked separately
			if let styleAttribute = attributeDict["style"]
			{
				let style = ParaStyle.value(of: styleAttribute)
				if style.isSectionHeadingStyle()
				{
					// Only a single section heading can be fit into a section
					if sectionHeadingFound
					{
						closeSection()
						endParsingOnStartElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
						parseContents = false
					}
					else
					{
						sectionHeadingFound = true
					}
				}
			}
			
			if parseContents
			{
				contentParser = USXParagraphProcessor.createParagraphParser(caller: self, targetPointer: &parsedContent, using: errorHandler)
				parser.delegate = contentParser
				
				// Informs the paragraph parser about the first element
				contentParser?.parser?(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
			}
		}
		if elementName == "chapter"
		{
			closeSection()
			endParsingOnStartElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
		}
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
	{
		if elementName == "usx"
		{
			closeSection()
			endParsingOnEndElement(parser: parser, elementName: elementName, namespaceURI: namespaceURI, qualifiedName: qName)
		}
	}
	
	
	// OTHER	---------
	
	private func closeSection()
	{
		targetPointer[0].append(Section(content: parsedContent))
		
		parsedContent = []
		sectionHeadingFound = false
	}
}
