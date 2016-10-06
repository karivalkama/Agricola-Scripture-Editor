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
struct Verse: AttributedStringConvertible
{
	// ATTRIBUTES	------
	
	let range: VerseRange
	var content: [CharData]
	
	
	// COMP. PROPS	------
	
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
	
	init(range: VerseRange, content: String? = nil)
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
	
	
	// OPERATORS	-----
	
	static func + (left: Verse, right: Verse) throws -> Verse
	{
		return try left.appended(with: right)
	}
	
	
	// IMPLEMENTED	----
	
	// Adds the verse marker(s) for the verse, then the contents
	func toAttributedString() -> NSAttributedString
	{
		let str = NSMutableAttributedString()
		
		// First adds the verse markers
		// (each start of a complete verse is added)
		for verse in range.verses
		{
			if !verse.start.midVerse
			{
				// Eg. '23. '
				str.append(NSAttributedString(string: "\(verse.start.index). ", attributes: [VerseIndexMarkerAttributeName : verse.start.index]))
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
}
