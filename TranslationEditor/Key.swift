//
//  Key.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Keys are used for specifying query ranges
struct Key
{
	let min: Any
	let max: Any
	let isDefined: Bool
	
	var inverted: Key
	{
		return Key(min: max, max: min, defined: isDefined)
	}
	
	static var undefined = Key(nil)
	
	private init(min: Any, max: Any, defined: Bool = true)
	{
		self.min = min
		self.max = max
		self.isDefined = defined
	}
	
	init(_ key: Any?)
	{
		var min: Any = NSNull()
		var max: Any = [:]
		var defined = false
		
		if let key = key
		{
			// Array type keys are handled differently
			if let key = key as? [Any?]
			{
				if key.count > 0, let first = key[0]
				{
					min = first
					defined = true
				}
				if key.count > 1, let second = key[1]
				{
					max = second
					defined = true
				}
			}
				// Other type values allow only single value range
			else
			{
				min = key
				max = key
				defined = true
			}
		}
		
		self.min = min
		self.max = max
		self.isDefined = defined
	}
}
