//
//  Weak.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.5.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This is a generic wrapper used so that weak references can be stored in an array
struct Weak<T>
{
	// ATTRIBUTES	------------
	
	private weak var _value: AnyObject!
	
	
	// COMPUTED PROPERTIES	----
	
	var value: T!
	{
		get { return _value as? T }
	}
	
	var isDefined: Bool { return _value != nil }
	
	
	// INIT	--------------------
	
	init(_ value: T)
	{
		_value = value as AnyObject
		
		/*
		if let value = value as? AnyObject
		{
			_value = value
		}
		else
		{
			fatalError("Value \(value) does not conform to AnyObject -> Cannot wrap it into a weak container.")
		}
		*/
	}
}

extension Array
{
	var weakReference: [Weak<Element>] { return map { Weak($0) } }
}
