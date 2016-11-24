//
//  DBModel.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

protocol Storable
{
	var idProperties: [Any] {get}
	var properties: [String : Any?] {get}
	
	func update(with properties: PropertySet)
	
	static func create(from properties: PropertySet, withId id: [PropertyValue]) -> Self
}

extension Storable
{
	static func get(_ id: String) -> Self
	{
		let doc = DATABASE.document(withID: id)!
		let idProperties = id.components(separatedBy: ID_SEPARATOR).map{PropertyValue($0)}
		
		return create(from: PropertySet(doc.properties!), withId: idProperties)
	}
	
	static func get(_ idArray: [Any]) -> Self
	{
		if (idArray.isEmpty)
		{
			return get("")
		}
		else
		{
			return get(id(of: idArray))
		}
	}
}
