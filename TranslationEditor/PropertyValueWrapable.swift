//
//  PropertyValueWrapable.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// Elements conforming to this protocol can be expressed with property values
protocol PropertyValueWrapable
{
	var value: PropertyValue { get }
}


// Extensions for existing elements to conform to this protocol
extension String: PropertyValueWrapable
{
	var value: PropertyValue { return PropertyValue(self) }
}

extension Int: PropertyValueWrapable
{
	var value: PropertyValue { return PropertyValue(self) }
}

extension Double: PropertyValueWrapable
{
	var value: PropertyValue { return PropertyValue(self) }
}

extension Bool: PropertyValueWrapable
{
	var value: PropertyValue { return PropertyValue(self) }
}


// Other extensions
extension Optional where Wrapped: PropertyValueWrapable
{
	// This optional wrapped into property value (cannot conform to protocol because language limitations)
	var value: PropertyValue
	{
		if let wrapped = self
		{
			return wrapped.value
		}
		else
		{
			return PropertyValue.empty
		}
	}
}

extension Array where Element: PropertyValueWrapable
{
	// This array wrapped into property value (cannot conform to protocol because language limitations)
	var value: PropertyValue
	{
		return PropertyValue(self)
	}
}
