//
//  PropertySet.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This struct contains a set of named properties
// All properties are kept in lowercase to avoid case-sensitivity issues
// Property value class is used for property value wrapping
struct PropertySet: CustomStringConvertible
{
	// ATTRIBUTES	-----------
	
	static let empty = PropertySet()
	
	private var properties = [String : PropertyValue]()
	
	
	// COMP. PROPERTIES	-------
	
	// Wraps this set into a common dictionary. Only non-empty properties will be included
	var toDict: [String : Any]
	{
		var dict = [String : Any]()
		for (propertyName, propertyValue) in properties
		{
			if let value = propertyValue.any
			{
				dict[propertyName] = value
			}
		}
		
		return dict
	}
	
	// Converts the set into a JSON object
	var description: String
	{
		var s = ""
		s.append("{")
		
		var isFirst = true
		for (propertyName, propertyValue) in properties
		{
			if propertyValue.isDefined
			{
				if isFirst
				{
					isFirst = false
				}
				else
				{
					s += ", "
				}
				
				s += "\"\(propertyName)\" : \(propertyValue)"
			}
		}
		
		s.append("}")
		
		return s
	}
	
	
	// SUBSCRIPTS	-----------
	
	subscript(propertyName: String) -> PropertyValue
	{
		get
		{
			if let value = properties[propertyName.lowercased()]
			{
				return value
			}
			else
			{
				return PropertyValue.empty
			}
		}
		
		set
		{
			properties[propertyName.lowercased()] = newValue
		}
	}
	
	
	// INIT	--------
	
	init()
	{
		// Empty initialiser
	}
	
	init(_ properties: [String : Any])
	{
		for (propertyName, value) in properties
		{
			if let parsedValue = PropertyValue.of(value)
			{
				self.properties[propertyName.lowercased()] = parsedValue
			}
		}
	}
	
	
	// OTHER METHODS	------
	
	// Creates a new property set with one value appended
	static func +(_ set: PropertySet, _ property: (String, PropertyValue)) -> PropertySet
	{
		var newSet = set
		newSet[property.0] = property.1
		
		return newSet
	}
	
	// Combines two property sets together to form a single larger set.
	// The properties of the left set will be overwritten by right side properties where they have the same name
	static func +(_ left: PropertySet, _ right: PropertySet) -> PropertySet
	{
		return PropertySet(left.properties + right.properties)
	}
	
	
	// OTHER METHODS	------
	
	func contains(propertyWithName propertyName: String) -> Bool
	{
		return self[propertyName].isDefined
	}
}
