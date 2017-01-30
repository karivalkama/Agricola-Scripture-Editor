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
	
	private let uid: String
	var name: String
	
	
	// COMP. PROPERTIES	----
	
	static let idIndexMap: IdIndexMap = ["lang_uid"]
	
	var idProperties: [Any] { return [uid] }
	
	var properties: [String : PropertyValue] { return ["name" : PropertyValue(name)] }
	
	
	// INIT	---------------
	
	init(name: String, uid: String = UUID().uuidString.lowercased())
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
