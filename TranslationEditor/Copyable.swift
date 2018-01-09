//
//  Copyable.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.12.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// All copyable instances can create a copy of themselves
protocol Copyable
{
	// Creates a copy of this instance
	func copy() -> Self
	
	// Checks whether the two instances have equal contents
	// This should be true between this instance and its copy right after the creation of said copy.
	// The instances may not stay equal, however
	func contentEquals(with other: Self) -> Bool
}
