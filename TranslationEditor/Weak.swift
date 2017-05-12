//
//  Weak.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This is a generic wrapper used so that weak references can be stored in an array
struct Weak<T: AnyObject>
{
	// ATTRIBUTES	------------
	
	private(set) weak var value: T!
	
	
	// INIT	--------------------
	
	init(_ value: T)
	{
		self.value = value
	}
}

extension Array where Element: AnyObject
{
	var weakReference: [Weak<Element>] { return map { Weak($0) } }
}
