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
	
	static let type = "language"
	
	static let PROPERTY_NAME = "name"
	
	let name: String
	
	
	// COMP. PROPERTIES	----
	
	static let idIndexMap: IdIndexMap = ["language_prefix", PROPERTY_NAME]
	
	var idProperties: [Any] { return ["language", name.toKey] }
	
	var properties: [String : PropertyValue] { return ["name": name.value] }
	
	
	// INIT	---------------
	
	init(name: String)
	{
		self.name = name.capitalized
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> Language
	{
		return Language(name: properties["name"].string.or(id[PROPERTY_NAME].string()))
	}
	
	
	// IMPLEMENTED METHODS	--
	
	func update(with properties: PropertySet)
	{
		// No mutable fields
	}
}
