//
//  JSONConvertible.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These objects can be written into JSON data
protocol JSONConvertible
{
	// The properties of this instance that are stored into JSON data
	// Nil values are allowed but skipped when the object is written
	var properties: [String : PropertyValue] {get}
}

extension JSONConvertible
{
	// This instance converted into a property set, containing all object properties
	var toPropertySet: PropertySet {return PropertySet(properties)}
}
