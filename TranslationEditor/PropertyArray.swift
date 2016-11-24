//
//  PropertyArray.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

struct PropertyArray
{
	// ATTRIBUTES	---------
	
	private var values = [PropertyValue]()
	
	
	// COMP. PROPS	---------
	
	// Wraps this property value array into a general array
	// Empty values are not included in the final array
	var toArray: [Any]
	{
		var array = [Any]()
		for value in values
		{
			if let any = value.any
			{
				array.append(any)
			}
		}
		
		return array
	}
	
	var count: Int {return values.count}
	
	
	// SUBSCRIPT	--------
	
	subscript(index: Int) -> PropertyValue
	{
		get {return values[index]}
		set {values[index] = newValue}
	}
	
	
	// INIT	-----------
	
	init(values: PropertyValue...)
	{
		self.values = values
	}
}
