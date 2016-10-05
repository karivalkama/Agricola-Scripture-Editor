//
//  StringUtilities.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A global set of utility functions
extension String
{
	// Counts the number of 'substring' within 'self'
	// Search 'range' can be specified. Full string (nil) by default
	// Case sensitive by default
	func occurrences(of str: String, within range: NSRange? = nil, caseSensitive: Bool = true) -> Int
	{
		let find: String!
		var from: String!
		
		if caseSensitive
		{
			find = str
			from = self
		}
		else
		{
			find = str.lowercased()
			from = self.lowercased()
		}
		
		if let range = range
		{
			from = (from as NSString).substring(with: range)
		}
		
		return from.components(separatedBy: find).count - 1
	}
	
	// Counts the number of occurences of 'regex' (regular expression) within 'self'
	// Whole string is searhed by default, but a specific 'range' can be specified as well
	// The case-sensitivity is determined by the regular expression
	func occurences(of regex: NSRegularExpression, within range: NSRange? = nil) -> Int
	{
		// Whole string range is used if no specific range is provided
		var trueRange: NSRange!
		if let range = range
		{
			trueRange = range
		}
		else
		{
			trueRange = NSMakeRange(0, (self as NSString).length)
		}
		
		return regex.matches(in: self, options: [], range: trueRange).count
	}
	
	// Finds a single digit at 'index' of 'self'. Nil if out of range or not a digit
	func digit(at index: Int) -> Int?
	{
		return digit(at: NSMakeRange(index, 1))
	}
	
	func digit(at range: NSRange) -> Int?
	{
		let nsStr = self as NSString
		
		// Checks the range first
		if range.location < 0 || range.location + range.length > nsStr.length
		{
			return nil
		}
		
		// Finds the 'character' at index
		let subString = nsStr.substring(with: range)
		return Int(subString)
	}
}

extension NSAttributedString
{
	// Checks whether 'self' contains an attribute with 'attrName' in 'range'
	func containsAttribute(_ attrName: String, in range: NSRange) -> Bool
	{
		var attributeFound = false
		enumerateAttribute(attrName, in: range, options: [])
		{
			value, _, stop in
			
			if value != nil
			{
				attributeFound = true
				stop[0] = true
			}
		}
		
		return attributeFound
	}
	
	// Finds the attribute value containing and surrounding the provided 'range' in 'self'
	// Nil is returned if there is no value and when the value doesn't span the required range
	func attribute(_ attrName: String, surrounding range: NSRange) -> Any?
	{
		// There are no surrounding attributes at the start and end of the string
		if range.location <= 0 || range.location + range.length >= length - 1
		{
			return nil
		}
		
		let requiredRange = NSMakeRange(range.location - 1, range.length + 2)
		let rangePointer = NSRangePointer.allocate(capacity: 1)
		
		let value = attribute(attrName, at: requiredRange.location, longestEffectiveRange: rangePointer, in: requiredRange)
		// The returned range must be the full required range
		if rangePointer[0].length < requiredRange.length
		{
			return nil
		}
		else
		{
			return value
		}
	}
}

