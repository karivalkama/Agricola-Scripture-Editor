//
//  VerseRange.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A verseRange contains a text range from a certain verse index to another
// TODO: Struct or class? (struct doesn't work with lazily se values)
class VerseRange
{
	// ATTRIBUTES	--------
	
	private var _verses: [VerseRange]!
	
	// Inclusive
	let start: VerseIndex
	// Exclusive
	let end: VerseIndex
	
	
	// COMPUTED PROPS.
	
	// Lazy getter for verse ranges
	// Splits the range on verse markings. For example, range of 4b-7 would become [4b-5, 5-6, 6-7]
	var verses: [VerseRange]
	{
		get
		{
			if _verses == nil
			{
				var verses = [VerseRange]()
				
				// The first and last verses may be incomplete (eg. 6b-7 or 10-10b)
				var cursor = start
				while cursor < end
				{
					let nextVerseStart = VerseIndex(cursor.index + 1)
					verses.append(VerseRange(start: cursor, end: nextVerseStart))
					cursor = nextVerseStart
				}
				if end.midVerse
				{
					verses.append(VerseRange(start: cursor, end: end))
				}
				
				_verses = verses
			}
			
			return _verses
		}
	}
	
	// The name of the range, for example '4b-7a' or '2'
	// The name is inclusive (no exclusive end is added)
	var name: String
	{
		get
		{
			// The start may contain 'b' if it starts mid-verse
			var str = "\(start.index)"
			if start.midVerse
			{
				str.append("b")
			}
			
			// If the range goes over verse boundaries, adds the end part
			if verses.count > 1
			{
				str.append("-\(end.index)")
				// The end may contain 'a' if it ends mid-verse
				if end.midVerse
				{
					str.append("a")
				}
			}
			
			return str
		}
	}
	
	
	// INIT	--------
	
	// Start is inclusive, end is exclusive
	// For example, verse 1 would be [1, 2]. Verse 1a would be [1, 1mid] and 1-2 would be [1, 3]
	init(start: VerseIndex, end: VerseIndex)
	{
		// Start always comes before end
		if end.isBefore(start)
		{
			self.start = end
			self.end = start
		}
		else
		{
			self.start = start
			self.end = end
		}
	}
	
	// Wrapper that creates a range with length 0 at the provided 'index'
	/*
	init(_ index: VerseIndex)
	{
		self.start = index
		self.end = index
	}*/
	
	
	// OPERATORS	----
	
	static func + (left: VerseRange, right: VerseRange) throws -> VerseRange
	{
		return try left.appended(with: right)
	}
	
	static func - (left: VerseRange, right: VerseRange) -> [VerseRange]
	{
		// If the right range is completely within left range, it may split the range in two
		if left.contains(range: right)
		{
			// Of course there are special cases where the right range is at the start or end of the left range, in which case the range is not split
			if left.start == right.start
			{
				return [VerseRange(start: right.end, end: left.end)]
			}
			else if left.end == right.end
			{
				return [VerseRange(start: left.start, end: right.start)]
			}
			else
			{
				return [VerseRange(start: left.start, end: right.start), VerseRange(start: right.end, end: left.end)]
			}
		}
		// If only the start of the right range is within left range, it is used as the new end point
		else if left.contains(index: right.start, excludeEnd: true)
		{
			return [VerseRange(start: left.start, end: right.start)]
		}
		// If only the end of the right range is within left range, it is used as the new start point
		else if left.contains(index: right.end, excludeEnd: false)
		{
			return [VerseRange(start: right.end, end: left.end)]
		}
		// If the two ranges don't overlap at all, no operation is required
		else
		{
			return [left]
		}
	}
	
	
	// OTHER	--------
	
	func contains(index: VerseIndex, excludeEnd: Bool) -> Bool
	{
		// Checks whether the end is contained
		if excludeEnd
		{
			if index >= end
			{
				return false
			}
		}
		else if index > end
		{
			return false
		}
		
		return index >= start
	}
	
	func contains(range: VerseRange) -> Bool
	{
		return contains(index: range.start, excludeEnd: true) && contains(index: range.end, excludeEnd: false)
	}
	
	func overlaps(with other: VerseRange) -> Bool
	{
		return contains(index: other.start, excludeEnd: true) || contains(index: other.end, excludeEnd: false)
	}
	
	// Creates an extended version of 'self' containing the specified 'index'
	func extended(to index: VerseIndex) -> VerseRange
	{
		if start > index
		{
			return VerseRange(start: index, end: end)
		}
		else if end < index
		{
			return VerseRange(start: start, end: index)
		}
		else
		{
			return self
		}
	}
	
	// Creates an extended version of 'self' containing the whole 'range'
	func extended(toContain range: VerseRange) -> VerseRange
	{
		return extended(to: range.start).extended(to: range.end)
	}
	
	// Creates a diminished version of 'self' that is contained within 'range'
	func within(range: VerseRange) -> VerseRange
	{
		return VerseRange(start: VerseIndex.max(start, range.start), end: VerseIndex.min(end, range.end))
	}
	
	// Splits the verse range at 'index', creating 2 separate ranges. If the index falls out of range or is the start or end of the range, the range is not split and is returned whole
	func split(at index: VerseIndex) -> [VerseRange]
	{
		if contains(index: index, excludeEnd: true) && start != index
		{
			return [VerseRange(start: start, end: index), VerseRange(start: index, end: end)]
		}
		else
		{
			return [self]
		}
	}
	
	// This method appends a 'range' to the start or end of 'self'
	// The function will fail if the verses are not connected (ie. 1-2 and 5-6)
	// The function will work on overlapping ranges (ie. 1-4 and 2-6)
	// Use 'extended(toContain: range)' if you don't want the function to fail on separate ranges
	func appended(with range: VerseRange) throws -> VerseRange
	{
		// Can't append ranges if they are not connected
		if !contains(index: range.start, excludeEnd: false) && !contains(index: range.end, excludeEnd: false)
		{
			throw VerseError.versesAreSeparate
		}

		return extended(toContain: range)
	}
}


