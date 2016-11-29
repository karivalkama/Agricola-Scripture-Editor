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
struct Id
{
	// ATTRIBUTES	---------
	
	let idString: String
	
	private let idParts: [String]
	private let indexMap: [String : IdIndex]
	
	
	// INIT	-----------------
	
	init(id: String, indexMap: [String : IdIndex])
	{
		self.idString = id
		self.indexMap = indexMap
		self.idParts = id.components(separatedBy: ID_SEPARATOR)
	}
	
	
	// SUBSCRIPT	---------
	
	subscript(propertyName: String) -> PropertyValue
	{
		if let index = indexMap[propertyName]
		{
			if index.length > 1
			{
				var s = idParts[index.start]
				for part in idParts.dropFirst()
				{
					s += ID_SEPARATOR
					s += part
				}
				
				return PropertyValue(s)
			}
			else if index.length == 1
			{
				return PropertyValue(idParts[index.start])
			}
		}
		
		// TODO: Possibly add error handling
		
		return PropertyValue.empty
	}
}

struct IdIndex: Hashable
{
	let start: Int // Inclusive
	let end: Int // Exclusive
	
	var hashValue: Int {return (31 &* start.hashValue) &+ end.hashValue}
	
	var length: Int {return end - start}
	
	init(_ start: Int, _ end: Int? = nil)
	{
		self.start = start
		
		if let end = end
		{
			self.end = end
		}
		else
		{
			self.end = start + 1
		}
	}
	
	static func == (left: IdIndex, right: IdIndex) -> Bool
	{
		return left.start == right.start && left.end == right.end
	}
}
