//
//  Row.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Rows are used for wrapping CBLQueryRows into a more accessible format
class Row<T: Storable>
{
	// ATTRIBUTES	-------
	
	let keys: [PropertyValue]
	let value: PropertyValue
	let object: T
	
	
	// SUBSCRIPT	-------
	
	// Finds the key at a certain index
	subscript(index: Int) -> PropertyValue
	{
		if index < 0 || index >= keys.count
		{
			return PropertyValue.empty
		}
		else
		{
			return keys[index]
		}
	}
	
	
	// INIT	---------------
	
	init(_ row: CBLQueryRow) throws
	{
		// Parses the keys from the row into propertyvalue format
		var keyBuffer = [PropertyValue]()
		
		var i = 0
		while let key = row.key(at: UInt(i))
		{
			if let value = PropertyValue.of(key)
			{
				keyBuffer.append(value)
			}
			else
			{
				keyBuffer.append(PropertyValue.empty)
			}
			
			i += 1
		}
		
		keys = keyBuffer
		
		// Parses the object
		if let idString = row.documentID
		{
			var properties: [String : Any]!
			if let preProperties = row.documentProperties
			{
				properties = preProperties
			}
			else if let documentProperties = row.document?.properties
			{
				properties = documentProperties
			}
			else
			{
				throw RowParseError.documentPropertiesMissing
			}
			
			object = try T.create(from: PropertySet(properties), withId: T.createId(from: idString))
		}
		else
		{
			throw RowParseError.documentIdMissing
		}
		
		// Parses the row value
		if let rowValue = PropertyValue.of(row.value)
		{
			value = rowValue
		}
		else
		{
			value = PropertyValue.empty
		}
	}
}
