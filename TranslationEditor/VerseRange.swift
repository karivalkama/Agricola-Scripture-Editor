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
struct VerseRange: JSONConvertible, Equatable, CustomStringConvertible
{
	// ATTRIBUTES	--------
	
	// Inclusive
	let start: VerseIndex
	// Exclusive
	let end: VerseIndex
	
	
	// COMPUTED PROPS.	---
	
	var properties: [String : PropertyValue]
	{
		return ["start" : start.value, "end" : end.value]
	}
	
	var description: String {return name}
	
	// Splits the range on verse markings. For example, range of 4b-7 would become [4b-5, 5-6, 6-7]
	var verses: [VerseRange]
	{
		var verses = [VerseRange]()
		
		// The first and last verses may be incomplete (eg. 6b-7 or 10-10b)
		var nextStart = start
		var nextEnd = VerseIndex(nextStart.index + 1)
		
		while nextEnd <= end
		{
			verses.append(VerseRange(nextStart, nextEnd))
			
			nextStart = nextEnd
			nextEnd = nextEnd + 1
		}
		if end.midVerse
		{
			verses.append(VerseRange(nextStart, end))
		}
		
		return verses
	}
	
	// The name of the range, for example '4b-7a' or '2'
	// The name is inclusive (no exclusive end is added)
	var name: String
	{
		// The start may contain 'b' if it starts mid-verse
		var str = "\(start.index)"
		if start.midVerse
		{
			str.append("b")
		}
		
		// If the range goes over verse boundaries, adds the end part (only the inclusive)
		let verses = self.verses
		if verses.count > 1
		{
			str.append("-\(verses.last!.start.index)")
		}
		
		// The end may contain 'a' if it ends mid-verse
		if end.midVerse
		{
			str.append("a")
		}
		
		return str
	}
	
	// A simplified version of the range name (The verse markers within the range, with the exception of ranges with no markers (eg. 7b))
	var simpleName: String
	{
		let startIndex = start.midVerse ? start.index + 1 : start.index
		let endIndex = end.midVerse ? end.index + 1 : end.index
		
		if startIndex == endIndex
		{
			return name
		}
		else if startIndex == endIndex - 1
		{
			return "\(startIndex)"
		}
		else
		{
			return "\(startIndex)-\(endIndex - 1)"
		}
	}
	
	// The first verse marker that is within this verse range. Nil if there are no verse markers within this range
	var firstVerseMarker: Int?
	{
		if start.midVerse
		{
			let firstMarker = VerseIndex(start.index + 1)
			if end > firstMarker
			{
				return firstMarker.index
			}
			else
			{
				return nil
			}
		}
		else
		{
			return start.index
		}
	}
	
	// The last verse marker that is within this verse range. Nil if there are no verse markers within this range
	var lastVerseMarker: Int?
	{
		var lastMarker: VerseIndex!
		if end.midVerse
		{
			lastMarker = VerseIndex(end.index)
		}
		else
		{
			lastMarker = VerseIndex(end.index - 1)
		}
		
		if start <= lastMarker
		{
			return lastMarker.index
		}
		else
		{
			return nil
		}
	}
	
	// The length of the range in verses (mid verses are counted as 1/2 verse)
	var length: Double
	{
		var length = Double(end.index) - Double(start.index)
		if end.midVerse
		{
			length += 0.5
		}
		if start.midVerse
		{
			length -= 0.5
		}
		
		return length
	}
	
	
	// INIT	--------
	
	// Start is inclusive, end is exclusive
	// For example, verse 1 would be [1, 2]. Verse 1a would be [1, 1mid] and 1-2 would be [1, 3]
	init(_ start: VerseIndex, _ end: VerseIndex)
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
	
	init (_ start: Int, _ end: Int)
	{
		self.init(VerseIndex(start), VerseIndex(end))
	}
	
	// Parses a verse range from the provided data. Both start and end data must be present and parseable
	// returns nil if there was not sufficient data to create a range
	static func parse(from propertyData: PropertySet) throws -> VerseRange
	{
		// Both start and end index must be parseable
		if let startValue = propertyData["start"].object, let endValue = propertyData["end"].object
		{
			return VerseRange(try VerseIndex.parse(from: startValue), try VerseIndex.parse(from: endValue))
		}
		
		throw JSONParseError(data: propertyData, message: "start and end properties required")
	}
	
	
	// OPERATORS	----
	
	static func == (left: VerseRange, right: VerseRange) -> Bool
	{
		return left.start == right.start && left.end == right.end
	}
	
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
				return [VerseRange(right.end, left.end)]
			}
			else if left.end == right.end
			{
				return [VerseRange(left.start, right.start)]
			}
			else
			{
				return [VerseRange(left.start, right.start), VerseRange(right.end, left.end)]
			}
		}
		// If only the start of the right range is within left range, it is used as the new end point
		else if left.contains(index: right.start, excludeEnd: true)
		{
			return [VerseRange(left.start, right.start)]
		}
		// If only the end of the right range is within left range, it is used as the new start point
		else if left.contains(index: right.end, excludeEnd: false)
		{
			return [VerseRange(right.end, left.end)]
		}
		// If the two ranges don't overlap at all, no operation is required
		else
		{
			return [left]
		}
	}
	
	
	// OTHER	--------
	
	func contains(index: VerseIndex, excludeEnd: Bool = true) -> Bool
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
			return VerseRange(index, end)
		}
		else if end < index
		{
			return VerseRange(start, index)
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
		return VerseRange(max(start, range.start), min(end, range.end))
	}
	
	// Splits the verse range at 'index', creating 2 separate ranges. If the index falls out of range or is the start or end of the range, the range is not split and is returned whole
	func split(at index: VerseIndex) -> [VerseRange]
	{
		if contains(index: index, excludeEnd: true) && start != index
		{
			return [VerseRange(start, index), VerseRange(index, end)]
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


