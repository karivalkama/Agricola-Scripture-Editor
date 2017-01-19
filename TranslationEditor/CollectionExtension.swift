//
//  CollectionUtilities.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Swift
import Foundation

extension Array
{
	// Checks that the provided condition is true for all elements in the array
	// Returns true if the array is empty
	func forAll(_ condition: (Element) throws -> Bool) rethrows -> Bool
	{
		return try filter({ !(try condition($0)) }).isEmpty
	}

	// Arrays can be combined together to form a new array with both elements. The left side
	// elements will be placed before the right side elements
	static func + (left: Array<Element>, right: Array<Element>) -> Array<Element>
	{
		var combined = [Element]()
		combined.append(contentsOf: left)
		combined.append(contentsOf: right)
		return combined
	}
}

extension Array
{
	// Adds an element to this array and returns the new array
	static func + (left: Array<Element>, right: Element) -> Array<Element>
	{
		var copy = left
		copy.append(right)
		return copy
	}
}

extension Array where Element: AnyObject
{
	// Checks if the array contains a reference to the provided object instance
	func containsReference(to element: Element) -> Bool
	{
		return contains(where: { $0 === element })
	}
	
	// Checks if the array contains references to each of the provided object instances
	func containsReferences(to elements: [Element]) -> Bool
	{
		return elements.forAll(containsReference)
	}
}

extension Array where Element: Copyable
{
	// Copies the array. This creates a new value even with reference type contents
	func copy() -> [Element]
	{
		return map { return $0.copy() }
	}
}

extension Dictionary
{
	// Combines two dictionaries together to form a single, larger dictionary
	// If both dictionaries contain equal keys, the values of the right dictionary will overwrite the values of the left dictionary for those keys in the returned dictionary
	// For example: ["dog" : "woof", "cat" : "meow"] + ["dog" : "rawr!", "mouse" : "squeek"] => ["dog" : "rawr!", "cat" : "meow", "mouse" : "squeek"]
	static func + (left: Dictionary<Key, Value>, right: Dictionary<Key, Value>) -> Dictionary<Key, Value>
	{
		var combined = [Key : Value]()
		for (key, value) in left
		{
			combined[key] = value
		}
		for (key, value) in right
		{
			combined[key] = value
		}
		
		return combined
	}
}

protocol Appending
{
	associatedtype Addable
	
	mutating func add(_ e: Addable)
}

extension Dictionary where Value: Appending
{
	mutating func append(key: Key, value: Value.Addable, empty: Value)
	{
		var array = self[key].or(empty)
		array.add(value)
		
		self[key] = array
	}
}

extension Array: Appending
{
	typealias Addable = Element
	
	mutating func add(_ e: Addable)
	{
		self.append(e)
	}
}

extension NSDictionary
{
	// Converts this dictionary into a swift dictionary
	// Only string keys are recognised
	// Keys with null values are also not included in the returned dictionary
	var toDict: [String : Any]
	{
		var dict = [String : Any]()
		
		for (key, value) in self
		{
			if let key = key as? String, !(value is NSNull)
			{
				dict[key] = value
			}
		}
		
		return dict
	}
}
