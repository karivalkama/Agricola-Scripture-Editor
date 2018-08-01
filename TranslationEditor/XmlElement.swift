//
//  XmlElement.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 1.8.2018.
//  Copyright © 2018 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Xml elements are used for representing xml data in DOM format
// Xml elements have value semantics
class XmlElement: Equatable
{
	// ATTRIBUTES	------------------
	
	let name: String
	let text: String?
	let attributes: [String: String]
	let children: [XmlElement]
	
	
	// COMPUTED	-----------------------
	
	var value: PropertyValue { return text.value }
	
	
	// INIT	---------------------------
	
	init(name: String, text: String? = nil, attributes: [String: String] = [:], children: [XmlElement] = [])
	{
		self.name = name
		self.text = text.filter { !$0.isEmpty }
		self.attributes = attributes.filter { !$1.isEmpty }
		self.children = children
	}

	
	// OPERATORS	------------------
	
	static func ==(_ a: XmlElement, _ b: XmlElement) -> Bool
	{
		return a.text == b.text && a.attributes == b.attributes && a.children == b.children
	}
	
	
	// SUBSCRIPT	------------------
	
	// Finds an existing child or makes a temporary replacement
	subscript(_ childName: String) -> XmlElement
	{
		if let child = existingChildWith(name: childName)
		{
			return child
		}
		else
		{
			return XmlElement(name: childName)
		}
	}
	
	
	// OTHER	-----------------------
	
	// Only returns existing children
	func existingChildWith(name childName: String) -> XmlElement?
	{
		return children.first(where: { $0.name == childName })
	}
	
	func attributeValue(_ attName: String) -> PropertyValue
	{
		return attributes[attName].value
	}
}
