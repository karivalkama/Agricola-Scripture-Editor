//
//  TextElement.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A text element is para is a set of character data that can be used as para content
class TextElement: ParaContent
{
	// ATTRIBUTES	------------
	
	var charData: [CharData]
	
	
	// COMPUTED PROPERTIES	----
	
	var text: String { return CharData.text(of: charData) }
	
	var toUSX: String { return charData.reduce("", { $0 + $1.toUSX }) }
	
	var properties: [String : PropertyValue] { return ["text": charData.value] }
	
	
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
	
	
	// IMPLEMENTED METHODS	----
	
	func toAttributedString(options: [String : Any]) -> NSAttributedString
	{
		let attStr = NSMutableAttributedString()
		charData.forEach { attStr.append($0.toAttributedString(options: options)) }
		return attStr
	}
}
