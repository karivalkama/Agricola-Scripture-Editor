//
//  OptionalUtils.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.12.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

extension Optional
{
	// Returns the optional's value, if present - or the provided default value
	func or(_ defaultValue: Wrapped) -> Wrapped
	{
		switch (self)
		{
		case .none: return defaultValue
		case .some(let value): return value
		}
	}
	
	// Checks whether a condition holds true for the optional's possible value
	// Always returns false when the optional is empty
	func exists(_ condition: (Wrapped) throws -> Bool) rethrows -> Bool
	{
		switch (self)
		{
		case .none: return false
		case .some(let value): return try condition(value)
		}
	}
}
