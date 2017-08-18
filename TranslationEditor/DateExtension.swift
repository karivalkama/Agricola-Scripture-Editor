//
//  DateExtension.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

extension Date
{
	// Checks if the two dates are within the same day
	func isWithinSameDay(with date: Date) -> Bool
	{
		let calendar = Calendar.current
		
		guard calendar.component(.day, from: self) == calendar.component(.day, from: date) else
		{
			return false
		}
		
		guard calendar.component(.month, from: self) == calendar.component(.month, from: date) else
		{
			return false
		}
		
		guard calendar.component(.year, from: self) == calendar.component(.year, from: date) else
		{
			return false
		}
		
		return true
	}
}
