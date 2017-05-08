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
	var content: TextWithFootnotes
	var crossReferences: [CrossReference]
	
	
	// COMP. PROPS	------
	
	var properties: [String : PropertyValue]
	{
		return ["range" : range.toPropertySet.value, "content" : content.value, "cross_references": crossReferences.value]
	}
	
	var text: String
	{
		return content.text
	}
	
	var toUSX: String { return "<verse number=\"\(range)\" style=\"v\"/>\(crossReferences.reduce("", { $0 + $1.toUSX }))\(content.toUSX)" }
	
	
	// INIT	-------
	
	init(range: VerseRange, content: TextWithFootnotes, crossReferences: [CrossReference] = [])
	{
		self.range = range
		self.content = content
		self.crossReferences = crossReferences
	}
	
	convenience init(range: VerseRange, content: String? = nil)
	{
		if let content = content
		{
			self.init(range: range, content: TextWithFootnotes(text: content))
		}
		else
		{
			self.init(range: range, content: TextWithFootnotes())
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
			return Verse(range: try VerseRange.parse(from: rangeValue), content: TextWithFootnotes.parse(from: propertyData["content"].object()), crossReferences: CrossReference.parseArray(from: propertyData["cross_references"].array(), using: CrossReference.parse))
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
		var combined: TextWithFootnotes!
		var references: [CrossReference]!
		if left.range.start < right.range.start
		{
			combined = left.content + right.content
			references = left.crossReferences + right.crossReferences
		}
		else
		{
			combined = right.content + left.content
			references = right.crossReferences + left.crossReferences
		}
		
		// Fails if the ranges don't connect
		return try Verse(range: left.range + right.range, content: combined, crossReferences: references)
	}
	
	
	// IMPLEMENTED	----
	
	func copy() -> Verse
	{
		return Verse(range: range, content: content.copy(), crossReferences: crossReferences)
	}
	
	// Adds the verse marker(s) for the verse, then the contents
	// Doesn't convert cross references into attribute strings
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
		return range == other.range && content.contentEquals(with: other.content) && crossReferences == other.crossReferences
	}
	
	// Creates a copy of this verse that has no character data in it
	func emptyCopy() -> Verse
	{
		return Verse(range: range, content: content.emptyCopy(), crossReferences: crossReferences.map { $0.emptyCopy() })
	}
}
