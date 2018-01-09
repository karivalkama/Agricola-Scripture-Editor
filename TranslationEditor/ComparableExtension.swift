//
//  Comparable.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 19.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// TODO: There already exists a protocol for this. How to avoid conflicts?
/*
protocol Comparable: Equatable
{
	// Checks whether the first instance is 'larger' than the second instance
	static func >(_ left: Self, _ right: Self) -> Bool
}*/

extension Comparable
{
	// Compares the two elements with '<' operator. If the result is ambiguous (elements are equal), returns nil
	// These can be combined to create a more cohesive check
	func compare(with other: Self) -> Bool?
	{
		if self == other
		{
			return nil
		}
		else
		{
			return self < other
		}
	}
	
	static func <=(_ left: Self, _ right: Self) -> Bool
	{
		return left == right || left < right
	}
	
	static func >(_ left: Self, _ right: Self) -> Bool
	{
		return !(left <= right)
	}
	
	static func >=(_ left: Self, _ right: Self) -> Bool
	{
		return !(left < right)
	}
	
	// Compares multiple value arrays going left to right
	// If the first two elements are equal, moves to the next two and so on
	// Returns nil for equal arrays
	static func compare(_ left: [Self], and right: [Self]) -> Bool?
	{
		for i in 0 ..< min(left.count, right.count)
		{
			if let result = left[i].compare(with: right[i])
			{
				return result
			}
		}
		
		return left.count.compare(with: right.count)
	}
}

/*
extension Int: Comparable
{
	// Int already contains necessary methods
}*/

/*
func min<T: Comparable>(_ first: T, _ second: T) -> T
{
	if first > second
	{
		return second
	}
	else
	{
		return first
	}
}*/
