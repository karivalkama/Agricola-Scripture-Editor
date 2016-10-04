//
//  Verse.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A verseIndex is a way of indexing certain text ranges.
// A single index may contain one, multiple, a half or multiple and a half verses
struct VerseIndex
{
	// ATTRIBUTES	----------
	
	let index: Int
	// Whether the index is at the midle of a verse (eg. 6b)
	let midVerse: Bool
	
	
	// COMP. PROPS	-----
	/*
	var preciseIndex: Double
	{
		// Ternary operator not working because of some xcode bug?
		var d = Double(index)
		if midVerse
		{
			d += 0.5
		}
		
		return d
	}*/
	
	
	// INIT	--------
	
	init(_ index: Int, midVerse: Bool = false)
	{
		self.index = index
		self.midVerse = midVerse
	}
	
	
	// OPERATORS	--
	
	static func < (left: VerseIndex, right: VerseIndex) -> Bool
	{
		return left.isBefore(right)
	}
	
	static func > (left: VerseIndex, right: VerseIndex) -> Bool
	{
		return left.isAfter(right)
	}
	
	static func <= (left: VerseIndex, right: VerseIndex) -> Bool
	{
		return !left.isAfter(right)
	}
	
	static func >= (left: VerseIndex, right: VerseIndex) -> Bool
	{
		return !left.isBefore(right)
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
	
	static func max(_ first: VerseIndex, _ second: VerseIndex) -> VerseIndex
	{
		if first > second
		{
			return first
		}
		else
		{
			return second
		}
	}
	
	static func min(_ first: VerseIndex, _ second: VerseIndex) -> VerseIndex
	{
		if first < second
		{
			return first
		}
		else
		{
			return second
		}
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
