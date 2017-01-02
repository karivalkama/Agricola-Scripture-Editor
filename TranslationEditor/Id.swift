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

func max(_ left: IdIndex, _ right: IdIndex) -> IdIndex
{
	if left.end == right.end
	{
		if left.start >= right.start
		{
			return left
		}
		else
		{
			return right
		}
	}
	else if left.end > right.end
	{
		return left
	}
	else
	{
		return right
	}
}

func min(_ left: IdIndex, _ right: IdIndex) -> IdIndex
{
	if left.end == right.end
	{
		if left.start < right.start
		{
			return left
		}
		else
		{
			return right
		}
	}
	else if left.end < right.end
	{
		return left
	}
	else
	{
		return right
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
	
	static func of(indexMap: [String : IdIndex]) -> IdIndex
	{
		return IdIndex(minIndex(of: indexMap).start, maxIndex(of: indexMap).end)
	}
	
	static func minIndex(of indexMap: [String : IdIndex]) -> IdIndex
	{
		if indexMap.isEmpty
		{
			return IdIndex(0)
		}
		
		let values = indexMap.values
		return values.dropFirst().reduce(values.first!, { return min($0, $1) })
	}
	
	static func maxIndex(of indexMap: [String : IdIndex]) -> IdIndex
	{
		return indexMap.values.reduce(IdIndex(0), { return max($0, $1) })
	}
	
	static func == (left: IdIndex, right: IdIndex) -> Bool
	{
		return left.start == right.start && left.end == right.end
	}
}
