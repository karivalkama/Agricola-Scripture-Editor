//
//  CharData.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Chardata is used for storing text within a verse or another container. Character data may have specific styling associated with it (quotation, special meaning, etc.)
struct CharData: Equatable, USXConvertible, AttributedStringConvertible, JSONConvertible, ExpressibleByStringLiteral
{
	// typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
	
	// ATTRIBUTES	----
	
	var style: CharStyle?
	var text: String
	
	
	// COMP. PROPERTIES	--
	
	var properties: [String : PropertyValue]
	{
		return [
			"style" : (style?.code).value,
			"text" : text.value]
	}
	
	var toUSX: String
	{
		// Empty charData is not recorded in USX
		if isEmpty
		{
			return ""
		}
		else if let style = style
		{
			return "<char style=\"\(style.code)\">\(text)</char>"
		}
		else
		{
			return text
		}
	}
	
	var isEmpty: Bool { return text.isEmpty }
	
	
	// INIT	----
	
	init(text: String, style: CharStyle? = nil)
	{
		self.text = text
		self.style = style
	}
	
	init(stringLiteral value: String)
	{
		self.text = value
		self.style = nil
	}
	
	init(unicodeScalarLiteral value: String)
	{
		self.text = value
		self.style = nil
	}
	
	init(extendedGraphemeClusterLiteral value: String)
	{
		self.text = value
		self.style = nil
	}
	
	static func parse(from propertyData: PropertySet) -> CharData
	{
		var style: CharStyle? = nil
		if let styleValue = propertyData["style"].string
		{
			style = CharStyle.of(styleValue)
		}
		return CharData(text: propertyData["text"].string(), style: style)
	}
	
	
	// OPERATORS	----
	
	static func == (left: CharData, right: CharData) -> Bool
	{
		return left.text == right.text && left.style == right.style
	}
	
	
	// CONFORMED	---
	
	func toAttributedString(options: [String : Any] = [:]) -> NSAttributedString
	{
		// TODO: At some point one may wish to add other types of attributes based on the style
		let attributes = [CharStyleAttributeName : style as Any]
		return NSAttributedString(string: text, attributes: attributes)
	}
	
	
	// OTHER	------
	
	func appended(_ text: String) -> CharData
	{
		return CharData(text: self.text + text, style: self.style)
	}
	
	func emptyCopy() -> CharData
	{
		return CharData(text: "", style: style)
	}
	
	static func text(of data: [CharData]) -> String
	{
		return data.reduce("") { $0 + $1.text }
		/*
		var text = ""
		
		for charData in data
		{
			text.append(charData.text)
		}
		
		return text*/
	}
	
	static func update(_ first: [CharData], with second: [CharData]) -> [CharData]
	{
		var updated = [CharData]()
		
		// Updates the text in the first array with the matching style instances in the second array
		var lastSecondIndex = -1
		
		for oldVersion in first
		{
			// Finds the matching version
			var matchingIndex: Int?
			for secondIndex in lastSecondIndex + 1 ..< second.count
			{
				if second[secondIndex].style == oldVersion.style
				{
					matchingIndex = secondIndex
					break
				}
			}
			
			// Copies the new text or empties the array
			if let matchingIndex = matchingIndex
			{
				// In case some of the second array data was skipped, adds it in between
				for i in lastSecondIndex + 1 ..< matchingIndex
				{
					updated.add(second[i])
				}
				
				updated.add(CharData(text: second[matchingIndex].text, style: oldVersion.style))
				lastSecondIndex = matchingIndex
			}
			else
			{
				updated.add(CharData(text: "", style: oldVersion.style))
			}
		}
		
		// Makes sure the rest of the second array are included
		for i in lastSecondIndex + 1 ..< second.count
		{
			updated.add(second[i])
		}
		
		return updated
	}
}
