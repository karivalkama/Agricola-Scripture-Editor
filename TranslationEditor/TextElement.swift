//
//  TextElement.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// A text element is para is a set of character data that can be used as para content
final class TextElement: ParaContent, Copyable
{
	// ATTRIBUTES	------------
	
	var charData: [CharData]
	
	
	// COMPUTED PROPERTIES	----
	
	var text: String { return CharData.text(of: charData) }
	
	var toUSX: String { return charData.reduce("", { $0 + $1.toUSX }) }
	
	var properties: [String : PropertyValue] { return ["text": charData.value] }
	
	// Whether this text element contains no text whatsoever
	var isEmpty: Bool { return charData.forAll { $0.isEmpty } }
	
	
	// INIT	--------------------
	
	init(charData: [CharData] = [])
	{
		self.charData = charData
	}
	
	// Parses a text element from a JSON property set
	static func parse(from properties: PropertySet) -> TextElement
	{
		return TextElement(charData: CharData.parseArray(from: properties["text"].array(), using: CharData.parse))
	}
	
	static func empty() -> TextElement
	{
		return TextElement(charData: [CharData(text: "")])
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func toAttributedString(options: [String : Any]) -> NSAttributedString
	{
		let attStr = NSMutableAttributedString()
		charData.forEach { attStr.append($0.toAttributedString(options: options)) }
		return attStr
	}
	
	func copy() -> TextElement
	{
		return TextElement(charData: charData)
	}
	
	
	// OPERATORS	------------
	
	// Combines two text elements into a third text element
	// Does not affect the two parameters in any way
	static func +(_ left: TextElement, _ right: TextElement) -> TextElement
	{
		return TextElement(charData: left.charData + right.charData)
	}
	
	
	// OTHER METHODS	--------
	
	func emptyCopy() -> TextElement
	{
		return TextElement(charData: charData.map{ $0.emptyCopy() })
	}
	
	func contentEquals(with other: TextElement) -> Bool
	{
		return charData == other.charData
	}
}
