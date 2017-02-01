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
// TODO: Struct or class?
final class Verse: AttributedStringConvertible, JSONConvertible, Copyable
{
	// ATTRIBUTES	------
	
	// String conversion option defining whether verse markers should be included (default true)
	// If you would set this to false, the string may not be parsed back to verse data anymore
	static let OptionDisplayVerseNumber = "displayVerseNumber"
	
	var range: VerseRange
	var content: [CharData]
	
	
	// COMP. PROPS	------
	
	var properties: [String : PropertyValue]
	{
		return ["range" : range.toPropertySet.value, "content" : content.value]
	}
	
	var text: String
	{
		return CharData.text(of: content)
	}
	
	
	// INIT	-------
	
	init(range: VerseRange, content: [CharData])
	{
		self.range = range
		self.content = content
	}
	
	convenience init(range: VerseRange, content: String? = nil)
	{
		if let content = content
		{
			self.init(range: range, content: [CharData(text: content)])
		}
		else
		{
			self.init(range: range, content: [])
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
			return Verse(range: try VerseRange.parse(from: rangeValue), content: CharData.parseArray(from: propertyData["content"].array(), using: CharData.parse) )
		}
		else
		{
			throw JSONParseError(data: propertyData, message: "range property required")
		}
	}
	
	
	// OPERATORS	-----
	
	static func + (left: Verse, right: Verse) throws -> Verse
	{
		return try left.appended(with: right)
	}
	
	
	// IMPLEMENTED	----
	
	func copy() -> Verse
	{
		return Verse(range: range, content: content)
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
		for part in content
		{
			str.append(part.toAttributedString())
		}
		
		return str
	}
	
	
	// OTHER	-----
	
	func appended(with other: Verse) throws -> Verse
	{
		// Appends the ranges, combines the texts
		
		// Doesn't work if the one verse is within another
		if self.range.contains(range: other.range) || other.range.contains(range: self.range)
		{
			throw VerseError.ambiguousTextPosition
		}
		
		// Determines how the text is ordered
		// TODO: Might want to add a space between the texts
		var combined = [CharData]()
		if self.range.start < other.range.start
		{
			combined = self.content + other.content
		}
		else
		{
			combined = other.content + self.content
		}
		
		// Fails if the ranges don't connect
		return try Verse(range: self.range + other.range, content: combined)
	}
	
	func contentEquals(with other: Verse) -> Bool
	{
		return range == other.range && content == other.content
	}
	
	// Creates a copy of this verse that has no character data in it
	func emptyCopy() -> Verse
	{
		return Verse(range: range)
	}
}
