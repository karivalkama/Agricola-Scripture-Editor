//
//  IdIndex.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

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

struct IdIndex: Hashable, ExpressibleByIntegerLiteral
{
	typealias IntegerLiteralType = Int
	
	let start: Int // Inclusive
	let end: Int // Exclusive
	
	var hashValue: Int {return (31 &* start.hashValue) &+ end.hashValue}
	
	var length: Int {return end - start}
	
	init(integerLiteral value: Int)
	{
		self.start = value
		self.end = value + 1
	}
	
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
	
	/*
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
	}*/
	
	static func == (left: IdIndex, right: IdIndex) -> Bool
	{
		return left.start == right.start && left.end == right.end
	}
	
	static func + (index: IdIndex, amount: Int) -> IdIndex
	{
		if amount == 0
		{
			return index
		}
		else if amount > 0
		{
			return IdIndex(index.end + amount - 1)
		}
		else
		{
			print("WARNING: Using a negative number on id index addition.")
			return index
		}
	}
}

struct IdIndexMap: ExpressibleByDictionaryLiteral, ExpressibleByArrayLiteral
{
	// ATTRIBUTES	-------------
	
	private var dict: [String: IdIndex]
	
	
	// COMPUTED PROPERTIES	-----
	
	var toDict: [String : IdIndex] { return dict }
	
	
	// INIT	---------------------
	
	init(dictionaryLiteral elements: (String, IdIndex)...)
	{
		dict = [String: IdIndex]()
		for (key, value) in elements
		{
			dict[key] = value
		}
	}
	
	init(arrayLiteral elements: String...)
	{
		dict = [String: IdIndex]()
		for i in 0 ..< elements.count
		{
			dict[elements[i]] = IdIndex(i)
		}
	}
	
	
	// SUBSCRIPT	-------------
	
	subscript(indexName: String) -> IdIndex?
	{
		get { return dict[indexName] }
		set { dict[indexName] = newValue }
	}
	
	
	// OTHER METHODS	---------
	
	// The smallest idIndex within this map
	var minIndex: IdIndex
	{
		if dict.isEmpty
		{
			return IdIndex(0)
		}
		
		let values = dict.values
		return values.dropFirst().reduce(values.first!, { return min($0, $1) })
	}
	
	// The largest index within this map
	var maxIndex: IdIndex { return dict.values.reduce(IdIndex(0), { return max($0, $1) }) }
	
	// The index range of this map
	var index: IdIndex { return IdIndex(minIndex.start, maxIndex.end) }
	
	// Creates an extended id index map.
	// Parent path name = the name of the parent path property in the new index map
	// Child path = Child path property names in order, each describing a single section of the path
	func makeChildPath(parentPathName: String, childPath: [String]) -> IdIndexMap
	{
		let switchIndex = index
		
		var indexMap = self
		indexMap[parentPathName] = switchIndex
		for i in 0 ..< childPath.count
		{
			indexMap[childPath[i]] = switchIndex + (i + 1)
		}
		
		return indexMap
	}
}
