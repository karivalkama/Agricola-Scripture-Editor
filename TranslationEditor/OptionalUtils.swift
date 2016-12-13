//
//  OptionalUtils.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
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
}
