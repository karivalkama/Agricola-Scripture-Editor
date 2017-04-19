//
//  Comparable.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 19.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
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
