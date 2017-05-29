//
//  CollectionUtilities.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Swift
import Foundation

extension Sequence
{
	// Counts the number of elements that satisfy the provided result
	func count(where condition: (Self.Iterator.Element) -> (Bool)) -> Int
	{
		return reduce(0, { condition($1) ? $0 + 1 : $0 })
	}
}

extension Array
{
	// Finds an element from the array. If the index is out of bounds, nil is returned
	subscript(safe index: Int) -> Element?
	{
		if index >= 0 && index < count
		{
			return self[index]
		}
		else
		{
			return nil
		}
	}
	
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
	
	// Converts the array into a dictionary
	// If there are duplicate keys, only the latter will remain in effect
	// The provided function returns key value pair for each element
	func toDictionary<Key: Hashable, Value>(using converter: (Element) -> (Key, Value)) -> [Key : Value]
	{
		var dict = [Key : Value]()
		
		for element in self
		{
			let (key, value) = converter(element)
			dict[key] = value
		}
		
		return dict
	}
	
	// Converts the array into a dictionary that supports multiple values for a single key
	// The provided function returns key value pair for each element
	// If the converter returns nil for any element, that element is skipped
	func toArrayDictionary<Key: Hashable, Value>(using converter: (Element) -> (Key, Value)?) -> [Key : [Value]]
	{
		var dict = [Key : [Value]]()
		
		for element in self
		{
			if let (key, value) = converter(element)
			{
				dict.append(key: key, value: value, empty: [])
			}
		}
		
		return dict
	}
	
	// Takes a sub array from this array by starting from the provided index and including elements as long as the condition holds
	func take(from startIndex: Int, while condition: (Element) -> Bool) -> [Element]
	{
		var result = [Element]()
		for i in startIndex ..< count
		{
			let element = self[i]
			if condition(element)
			{
				result.append(element)
			}
			else
			{
				break
			}
		}
		
		return result
	}
	
	// Adds an element to this array and returns the new array
	static func + (left: Array<Element>, right: Element) -> Array<Element>
	{
		var copy = left
		copy.append(right)
		return copy
	}
	
	static func +(_ element: Element, array: [Element]) -> [Element]
	{
		var copy = [element]
		copy.append(contentsOf: array)
		return copy
	}
}

extension Array where Element: Equatable
{
	// Returns an array without the specified element
	static func - (array: Array<Element>, element: Element) -> Array<Element>
	{
		return array.filter { $0 != element }
	}
	
	static func - (_ left: Array<Element>, _ right: Array<Element>) -> Array<Element>
	{
		return left.filter { !right.contains($0) }
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
	
	// Finds an element from the array, but only works with exact references (not equality)
	func index(referencing element: Element) -> Int?
	{
		return index(where: { $0 === element })
	}
	
	// Returns the array without any reference to the specified element
	static func - (array: Array<Element>, element: Element) -> Array<Element>
	{
		return array.filter { !($0 === element) }
	}
}

extension Array where Element: Copyable
{
	// Copies the array. This creates a new value even with reference type contents
	func copy() -> [Element]
	{
		return map { return $0.copy() }
	}
	
	func contentEquals(with other: [Element]) -> Bool
	{
		if count == other.count
		{
			for i in 0 ..< count
			{
				if !self[i].contentEquals(with: other[i])
				{
					return false
				}
			}
			
			return true
		}
		else
		{
			return false
		}
	}
}

extension Dictionary
{
	// Checks whether the dictionary contains a value for the provided key
	func containsKey(_ key: Key) -> Bool
	{
		return self[key] != nil
	}
	
	// Maps both the keys and values of a dictionary, preserving the dictionary format
	func mapDict<K, V>(_ f: (Key, Value) -> (K, V)) -> [K: V]
	{
		var dict = [K: V]()
		for (key, value) in self
		{
			let (key, value) = f(key, value)
			dict[key] = value
		}
		
		return dict
	}
	
	// Maps both the keys and values of a dictionary, failed mappings are stripped from the final dictionary
	func flatMapDict<K, V>(_ f: (Key, Value) -> (K?, V?)) -> [K: V]
	{
		var dict = [K: V]()
		for (key, value) in self
		{
			let (castKey, castValue) = f(key, value)
			if let key = castKey, let value = castValue
			{
				dict[key] = value
			}
		}
		
		return dict
	}
	
	// Maps the dictionary values, but keeps the dictionary format
	func mapValues<T>(_ f: (Value) throws -> T) rethrows -> [Key: T]
	{
		var dict = [Key: T]()
		for (key, value) in self
		{
			dict[key] = try f(value)
		}
		
		return dict
	}
	
	// Maps the dictionary values keeping the dictionary format. Values mapped to nil will not be included in the final dictionary.
	func flatMapValues<T>(_ f: (Value) throws -> T?) rethrows -> [Key: T]
	{
		var dict = [Key: T]()
		for (key, value) in self
		{
			if let newValue = try f(value)
			{
				dict[key] = newValue
			}
		}
		
		return dict
	}
	
	// Maps the dictionary keys keeping the dictionary format and same values.
	func mapKeys<T>(_ f: (Key) throws -> T) rethrows -> [T: Value]
	{
		var dict = [T: Value]()
		
		for (key, value) in self
		{
			dict[try f(key)] = value
		}
		
		return dict
	}
	
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
	
	// Appends a single element
	mutating func add(_ e: Addable)
	// Removes and returns the first element
	mutating func popFirst() -> Addable?
	// Removes and returns the last element
	mutating func popLast() -> Addable?
}

extension Dictionary where Value: Appending
{
	// Adds a new item to the collection at a certain key
	mutating func append(key: Key, value: Value.Addable, empty: Value)
	{
		var array = self[key].or(empty)
		array.add(value)
		
		self[key] = array
	}
	
	// Finds and removes an element from the collection at the specified key
	mutating func popFirst(at key: Key) -> Value.Addable?
	{
		if var array = self[key]
		{
			let item = array.popFirst()
			self[key] = array
			
			return item
		}
		else
		{
			return nil
		}
	}
	
	// TODO: WET WET
	mutating func popLast(at key: Key) -> Value.Addable?
	{
		if var array = self[key]
		{
			let item = array.popLast()
			self[key] = array
			
			return item
		}
		else
		{
			return nil
		}
	}
}

extension Array: Appending
{
	typealias Addable = Element
	
	mutating func add(_ e: Addable)
	{
		self.append(e)
	}
	
	mutating func popFirst() -> Element?
	{
		return removeFirst()
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
