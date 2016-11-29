//
//  Language.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Languages represent different written languages
final class Language: Storable
{
	// ATTRIBUTES	-------
	
	static let TYPE = "language"
	
	private let uid: String
	var name: String
	
	
	// COMP. PROPERTIES	----
	
	static var idIndexMap: [String : IdIndex] {return ["lang_uid" : IdIndex(0)]}
	
	var idProperties: [Any] {return [uid]}
	
	var properties: [String : PropertyValue] {return [PROPERTY_TYPE : PropertyValue(Language.TYPE), "name" : PropertyValue(name)]}
	
	
	// INIT	---------------
	
	init(name: String, uid: String = UUID().uuidString)
	{
		self.uid = uid
		self.name = name
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> Language
	{
		return Language(name: properties["name"].string(), uid: id["lang_uid"].string())
	}
	
	
	// IMPLEMENTED METHODS	--
	
	func update(with properties: PropertySet)
	{
		if let name = properties["name"].string
		{
			self.name = name
		}
	}
}
