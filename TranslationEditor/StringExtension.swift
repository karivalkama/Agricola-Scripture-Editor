//
//  StringUtilities.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

fileprivate let keyRegex = try! NSRegularExpression(pattern: "[a-z0-9_@\\-\\+\\.:]")

// A global set of utility functions
extension String
{
	// A non-empty version of this string. If the string was empty, nil is returned
	var nonEmpty: String? { return isEmpty ? nil : self }
	
	var length: Int { return (self as NSString).length }
	
	// The range of this string instance
	var nsRange: NSRange { return NSMakeRange(0, length) }
	
	// A key-compatible version of this string
	var toKey: String { return lowercased().replacingOccurrences(of: " ", with: "_").limited(toExpression: keyRegex) }
	
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
			trueRange = nsRange
		}
		
		return regex.matches(in: self, options: [], range: trueRange).count
	}
	
	func components(separatedBy regex: NSRegularExpression, trim: Bool = false) -> [String]
	{
		// Replaces all matches of regex with a certain string
		let splitter = "<;splitter;>"
		let temp = NSMutableString(string: self)
		regex.replaceMatches(in: temp, options: [], range: NSMakeRange(0, temp.length), withTemplate: splitter)
		
		// Returns the components (may have to trim them first)
		if trim
		{
			var trimmedComponents = [String]()
			for component in temp.components(separatedBy: splitter)
			{
				trimmedComponents.append(component.trimmingCharacters(in: CharacterSet(charactersIn: " ")))
			}
			
			return trimmedComponents
		}
		else
		{
			return temp.components(separatedBy: splitter)
		}
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
	
	// Finds the matches for the regular expression in this string
	func matches(for regex: NSRegularExpression) -> [String]
	{
		let nsStr = self as NSString
		let results = regex.matches(in: self, options: [], range: nsRange)
		return results.map { nsStr.substring(with: $0.range) }
	}
	
	// Strips this string out of elements that do not belong to the provided regular expression
	func limited(toExpression regex: NSRegularExpression) -> String
	{
		return matches(for: regex).reduce("") { $0 + $1 }
	}
	
	// Returns a version of this string that contains only specified characters
	func limited(toCharacterSet characterSet: Set<Character>) -> String
	{
		return String(characters.filter { characterSet.contains($0) })
	}
	
	// The last n characters of this string
	func tail(withLength length: Int) -> String
	{
		let nsstr = self as NSString
		
		if nsstr.length <= length
		{
			return self
		}
		else
		{
			return nsstr.substring(from: nsstr.length - length)
		}
	}
	
	// Checks whether this string ends with the provided substring
	func endsWith(_ substring: String) -> Bool
	{
		return tail(withLength: substring.length) == substring
	}
}

extension NSAttributedString
{
	// Checks whether 'self' contains an attribute with 'attrName' in 'range'
	func containsAttribute(_ attrName: NSAttributedStringKey, in range: NSRange) -> Bool
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
	func attribute(_ attrName: NSAttributedStringKey, surrounding range: NSRange) -> Any?
	{
		// There are no surrounding attributes at the start and end of the string
		if range.location <= 0 || range.location + range.length >= length
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

