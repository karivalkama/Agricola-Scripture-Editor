//
//  JSONConvertible.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.11.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// These objects can be written into JSON data
protocol JSONConvertible: PropertyValueWrapable
{
	// The properties of this instance that are stored into JSON data
	// Nil values are allowed but skipped when the object is written
	var properties: [String : PropertyValue] {get}
}

extension JSONConvertible
{
	// This instance converted into a property set, containing all object properties
	var toPropertySet: PropertySet {return PropertySet(properties)}
	
	var value: PropertyValue { return toPropertySet.value }
	
	// Parses an array of property data into an array of object data
	static func parseArray(from array: [PropertyValue], using converter: (PropertySet) throws -> Self) rethrows -> [Self]
	{
		return try array.map { try converter($0.object()) }
	}
}
