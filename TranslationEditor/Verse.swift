//
//  Verse.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A verse has certain range but also text
// The text on a verse is mutable
final class Verse: AttributedStringConvertible, JSONConvertible, Copyable, USXConvertible
{
	// ATTRIBUTES	------
	
	// String conversion option defining whether verse markers should be included (default true)
	// If you would set this to false, the string may not be parsed back to verse data anymore
	static let OptionDisplayVerseNumber = "displayVerseNumber"
	
	var range: VerseRange
	var content: TextWithNotes
	
	
	// COMP. PROPS	------
	
	var properties: [String : PropertyValue]
	{
		return ["range" : range.toPropertySet.value, "content" : content.value]
	}
	
	var text: String
	{
		return content.text
	}
	
	var toUSX: String
	{
		if range.containsVerseMarkers
		{
			return "<verse number=\"\(range.simpleName)\" style=\"v\"/>\(content.toUSX)"
		}
		else
		{
			return content.toUSX
		}
	}
	
	
	// INIT	-------
	
	init(range: VerseRange, content: TextWithNotes)
	{
		self.range = range
		self.content = content
	}
	
	convenience init(range: VerseRange, content: String? = nil)
	{
		if let content = content
		{
			self.init(range: range, content: TextWithNotes(text: content))
		}
		else
		{
			self.init(range: range, content: TextWithNotes())
		}
	}
	
	// Parses verse data from property data
	// Verse range must be defined and parseable in the 'range' element
	// Throws a JSONParseError if the verse data couldn't be parsed
	static func parse(from propertyData: PropertySet) throws -> Verse
	{
		// The range must be parseable
		if let rangeValue = propertyData["range"].object
		{
			return Verse(range: try VerseRange.parse(from: rangeValue), content: TextWithNotes.parse(from: propertyData["content"].object()))
		}
		else
		{
			throw JSONParseError(data: propertyData, message: "range property required")
		}
	}
	
	
	// OPERATORS	-----
	
	// Appends the ranges, combines the texts
	static func + (_ left: Verse, _ right: Verse) throws -> Verse
	{
		// Doesn't work if the one verse is within another
		if left.range.contains(range: right.range) || right.range.contains(range: left.range)
		{
			throw VerseError.ambiguousTextPosition
		}
		
		// Determines how the text is ordered
		var combined: TextWithNotes!
		if left.range.start < right.range.start
		{
			combined = left.content + right.content
		}
		else
		{
			combined = right.content + left.content
		}
		
		// Fails if the ranges don't connect
		return try Verse(range: left.range + right.range, content: combined)
	}
	
	
	// IMPLEMENTED	----
	
	func copy() -> Verse
	{
		return Verse(range: range, content: content.copy())
	}
	
	// Adds the verse marker(s) for the verse, then the contents
	func toAttributedString(options: [String : Any]) -> NSAttributedString
	{
		let str = NSMutableAttributedString()
		
		var displayVerseNumber = true
		if let displayOption = options[Verse.OptionDisplayVerseNumber] as? Bool
		{
			displayVerseNumber = displayOption
		}
		
		// by default, adds the verse markers
		// (each start of a complete verse is added)
		if displayVerseNumber
		{
			for verse in range.verses
			{
				if !verse.start.midVerse
				{
					// Eg. '23. '
					str.append(NSAttributedString(string: "\(verse.start.index). ", attributes: [VerseIndexMarkerAttributeName : verse.start.index]))
				}
			}
		}
		
		// Adds the verse content afterwards
		str.append(content.toAttributedString(options: options))
		
		return str
	}
	
	
	// OTHER	-----
	
	func contentEquals(with other: Verse) -> Bool
	{
		let equals = range == other.range && content.contentEquals(with: other.content)
		// print("STATUS: Comparing two verses. Ranges: \(range) and \(other.range). Are considered equal: \(equals)")
		return equals
	}
	
	// Creates a copy of this verse that has no character data in it
	func emptyCopy() -> Verse
	{
		return Verse(range: range, content: content.emptyCopy())
	}
	
	static func merge(_ verses: [Verse]) throws -> Verse
	{
		return try verses.dropFirst().reduce(verses.first!, { try $0 + $1 })
	}
	
	static func contentEqualsBetween(_ left: [Verse], and right: [Verse]) -> Bool
	{
		// Checks whether any of the arrays is empty
		if left.isEmpty
		{
			return right.isEmpty
		}
		else if right.isEmpty
		{
			return false
		}
		
		// The start and end ranges should be the same
		if left.first!.range.start != right.first!.range.start || left.last!.range.end != right.last!.range.end
		{
			return false
		}
		
		// Starts comparing verses one by one
		var nextLeftIndex = 0
		var nextRightIndex = 0
		
		while (nextLeftIndex < left.count && nextRightIndex < right.count)
		{
			// Makes sure the verses start at the same spot
			if left[nextLeftIndex].range.start != right[nextRightIndex].range.start
			{
				return false
			}
			
			// Finds the shortest equal range between the two groups, starting from the selected verses
			var finalLeftIndex = nextLeftIndex
			var finalRightIndex = nextRightIndex
			
			while (left[finalLeftIndex].range.end != right[finalRightIndex].range.end)
			{
				if left[finalLeftIndex].range.end < right[finalRightIndex].range.end
				{
					finalLeftIndex += 1
				}
				else
				{
					finalRightIndex += 1
				}
			}
			
			// The merged content of the groups must be equal
			do
			{
				let leftSideMerge = try Verse.merge(Array(left[nextLeftIndex ... finalLeftIndex]))
				let rightSideMerge = try Verse.merge(Array(right[nextRightIndex ... finalRightIndex]))
				
				if !leftSideMerge.contentEquals(with: rightSideMerge)
				{
					return false
				}
			}
			catch
			{
				print("ERROR: Verse contents couldn't be merged. \(error)")
				return false
			}
			
			// Moves to the next range
			nextLeftIndex = finalLeftIndex + 1
			nextRightIndex = finalRightIndex + 1
		}
		
		return true
	}
}
