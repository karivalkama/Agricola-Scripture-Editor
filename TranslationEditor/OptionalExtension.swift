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
	// Whether this optional value is nil
	var isEmpty: Bool
	{
		switch (self)
		{
		case .none: return true
		case .some(_): return false
		}
	}
	
	// Whether this optional contains a value
	var isDefined: Bool { return !isEmpty }
	
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
	
	// Performs an operation for each 0-1 values in this optional
	func forEach(_ operation: (Wrapped) throws -> ()) rethrows
	{
		if (isDefined)
		{
			try operation(self!)
		}
	}
	
	// Filters this optional, returning it only if it fulfills the provided condition
	func filter(_ check: (Wrapped) throws -> Bool) rethrows -> Optional<Wrapped>
	{
		if (try exists(check))
		{
			return self
		}
		else
		{
			return nil
		}
	}
}
