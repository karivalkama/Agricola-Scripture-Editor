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
