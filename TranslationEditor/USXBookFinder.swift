//
//  USXBookFinder.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This parser finds and interprets the book elements from an usx document
class USXBookFinder: NSObject, XMLParserDelegate
{
	// ATTRIBUTES	----------------
	
	// Code + identifier
	private(set) var collectedBookInfo = [(String, String)]()
	
	private var openBookCode: String?
	private var collectedIdentifier = ""
	
	
	// IMPLEMENTED METHODS	--------
	
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
	{
		guard elementName.lowercased() == "book" else
		{
			return
		}
		
		guard let code = attributeDict["code"] else
		{
			print("ERROR: Book element without code attribute")
			return
		}
		
		openBookCode = code
	}
	
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
	{
		guard let openBookCode = openBookCode else
		{
			return
		}
		
		guard elementName.lowercased() == "book" else
		{
			return
		}
		
		collectedBookInfo.add((openBookCode, collectedIdentifier))
		self.openBookCode = nil
		collectedIdentifier = ""
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String)
	{
		if openBookCode != nil
		{
			collectedIdentifier += string
		}
	}
}
