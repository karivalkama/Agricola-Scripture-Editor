//
//  Id.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Ids are used for converting between id strings and property sets
// Ids are unique and used for differentiating between documents and instances
struct Id: CustomStringConvertible
{
	// ATTRIBUTES	---------
	
	let idString: String
	
	private let idParts: [String]
	private let indexMap: IdIndexMap
	
	
	// COMP. PROPERTIES	-----
	
	var description: String { return idString }
	
	
	// INIT	-----------------
	
	init(id: String, indexMap: IdIndexMap)
	{
		self.idString = id.lowercased()
		self.indexMap = indexMap
		self.idParts = idString.components(separatedBy: ID_SEPARATOR)
	}
	
	
	// SUBSCRIPT	---------
	
	subscript(propertyName: String) -> PropertyValue
	{
		if let index = indexMap[propertyName]
		{
			if index.length > 1
			{
				var partsInRange = [String]()
				for i in index.start ..< index.end
				{
					if let part = idPart(i)
					{
						partsInRange.append(part)
					}
				}
				
				if partsInRange.isEmpty
				{
					return PropertyValue.empty
				}
				else
				{
					var s = partsInRange.first!
					for part in partsInRange.dropFirst()
					{
						s += ID_SEPARATOR
						s += part
					}
					
					return PropertyValue(s)
				}
			}
			else if index.length == 1
			{
				return PropertyValue(idPart(index.start))
			}
		}
		
		return PropertyValue.empty
	}
	
	
	// OTHER	-----------
	
	// Shortens a string id by the specified amount of parts
	// For example, "a/b/c/d" shortened by 2 is "a/b"
	static func shorten(_ idString: String, by n: Int = 1) -> String
	{
		if n <= 0
		{
			return idString
		}
		else
		{
			let components = idString.components(separatedBy: ID_SEPARATOR).dropLast(n)
			if components.isEmpty
			{
				return ""
			}
			else
			{
				var s = components.first!
				components.dropFirst().forEach { s += ID_SEPARATOR + $0 }
				return s
			}
		}
	}
	
	private func idPart(_ index: Int) -> String?
	{
		if index < 0 || index >= idParts.count
		{
			return nil
		}
		else
		{
			return idParts[index]
		}
	}
}

