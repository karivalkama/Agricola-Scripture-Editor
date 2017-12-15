//
//  Verse.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.9.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// A verseIndex is a way of indexing certain text ranges.
// A single index may contain one, multiple, a half or multiple and a half verses
struct VerseIndex: JSONConvertible, Comparable, ExpressibleByIntegerLiteral
{
	// ATTRIBUTES	----------
	
	let index: Int
	// Whether the index is at the midle of a verse (eg. 6b)
	let midVerse: Bool
	
	
	// COMP. PROPS	-----
	
	var properties: [String : PropertyValue]
	{
		return ["index" : index.value, "mid_verse" : midVerse.value]
	}
	
	var nextComplete: VerseIndex
	{
		return VerseIndex(index + 1)
	}
	
	
	// INIT	--------
	
	init(integerLiteral value: Int)
	{
		self.index = value
		self.midVerse = false
	}
	
	init(_ index: Int, midVerse: Bool = false)
	{
		self.index = index
		self.midVerse = midVerse
	}
	
	// Parses a verse index from property data. Index required and must be > 0
	// Throws a JSON parse error if index couldn't be parsed
	static func parse(from propertyData: PropertySet) throws -> VerseIndex
	{
		if let index = propertyData["index"].int, index > 0
		{
			return VerseIndex(index, midVerse: propertyData["mid_verse"].bool(or: false))
		}
		else
		{
			throw JSONParseError(data: propertyData, message: "Invalid index in verse index data")
		}
	}
	
	// Parses a verseindex instance from a string, if possible
	// Viable strings are something like '11' or '13a'
	static func parse(from string: String) -> VerseIndex?
	{
		if let letterIndex = string.rangeOfCharacter(from: CharacterSet.letters)?.lowerBound
		{
            
			if let index = Int(string.prefix(upTo: letterIndex))
			{
				return VerseIndex(index, midVerse: true)
			}
			else
			{
				return nil
			}
		}
		else if let index = Int(string)
		{
			return VerseIndex(index)
		}
		else
		{
			return nil
		}
	}
	
	
	// OPERATORS	--
	
	static func < (left: VerseIndex, right: VerseIndex) -> Bool
	{
		return left.isBefore(right)
	}
	
	/*
	static func + (left: VerseIndex, right: VerseIndex) -> VerseRange
	{
		return VerseRange(start: left, end: right)
	}*/
	
	static func + (left: VerseIndex, right: Int) -> VerseIndex
	{
		return VerseIndex(left.index + right, midVerse: left.midVerse)
	}
	
	static func - (left: VerseIndex, right: Int) -> VerseIndex
	{
		return left + (-right)
	}
	
	static func == (left: VerseIndex, right: VerseIndex) -> Bool
	{
		return left.compare(with: right) == 0
	}
	
	static func != (left: VerseIndex, right: VerseIndex) -> Bool
	{
		return !(left == right)
	}
	
	
	// OTHER	-----------
	
	func compare(with other: VerseIndex) -> Int
	{
		if self.index == other.index
		{
			// mid-verse indices come after start-verse indices
			if self.midVerse
			{
				return other.midVerse ? 0 : 1
			}
			else
			{
				return other.midVerse ? -1 : 0
			}
		}
		else
		{
			return self.index - other.index
		}
	}
	
	func isBefore(_ other: VerseIndex) -> Bool
	{
		return compare(with: other) < 0
	}
	
	func isAfter(_ other: VerseIndex) -> Bool
	{
		return compare(with: other) > 0
	}
}
