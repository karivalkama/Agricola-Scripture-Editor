//
//  FootNote.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class FootNote: ParaContent, Copyable
{
	// ATTRIBUTES	------------
	
	var caller: String
	var style: String
	var originReference: String?
	// Text data and an attribute specifying whether the data is "closed"
	var charData: [CharData]
	
	
	// COMPUTED PROPERTIES	----
	
	var text: String { return "(\(CharData.text(of: charData)))" }
	
	var toUSX: String { return "<note caller=\"\(caller)\" style=\"\(style)\">\(originReference == nil ? "" : "<char style=\"fr\">\(originReference!)</char>")\(charData.reduce("", { $0 + $1.toUSX }))</note>" }
	
	var properties: [String : PropertyValue] { return ["caller": caller.value, "style": style.value, "origin_reference": originReference.value, "text": charData.value] }
	
	
	// INIT	--------------------
	
	init(caller: String, style: String, originReference: String? = nil, charData: [CharData] = [])
	{
		self.caller = caller
		self.style = style
		self.charData = charData
		self.originReference = originReference
	}
	
	static func parse(from properties: PropertySet) -> FootNote
	{
		return FootNote(caller: properties["caller"].string(), style: properties["style"].string(), originReference: properties["origin_reference"].string, charData: CharData.parseArray(from: properties["text"].array(), using: CharData.parse))
	}
	
	
	// IMPLEMENTED METHODS	---
	
	// TODO: Add option for hiding notes contents
	func toAttributedString(options: [String : Any]) -> NSAttributedString
	{
		let attSrt = NSMutableAttributedString()
		attSrt.append(NSAttributedString(string: "(", attributes: [NoteMarkerAttributeName: true]))
		charData.forEach { attSrt.append($0.toAttributedString(options: options)) }
		attSrt.append(NSAttributedString(string: ")", attributes: [NoteMarkerAttributeName: false]))
		
		attSrt.addAttribute(IsNoteAttributeName, value: true, range: NSMakeRange(0, attSrt.length))
		
		return attSrt
	}
	
	func copy() -> FootNote
	{
		return FootNote(caller: caller, style: style, originReference: originReference, charData: charData)
	}
	
	
	// OTHER METHODS	-----
	
	func emptyCopy() -> FootNote
	{
		return FootNote(caller: caller, style: style, originReference: originReference, charData: charData.map { $0.emptyCopy() })
	}
}
