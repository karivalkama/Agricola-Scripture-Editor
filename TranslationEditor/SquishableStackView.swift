//
//  SquishableStackView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 15.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// These stack views can be squished a little when necessary
class SquishableStackView: UIStackView, Squishable
{
	// ATTRIBUTES	--------------
	
	@IBInspectable var minSpacing: CGFloat = 0
	
	private var originalSpacing: CGFloat?
	
	
	// IMPLEMENTED METHODS	------
	
	func setSquish(_ isSquished: Bool, along axis: UILayoutConstraintAxis)
	{
		// Can only be squished along it's own axis
		if axis == self.axis
		{
			if isSquished
			{
				if originalSpacing == nil
				{
					originalSpacing = spacing
				}
				spacing = minSpacing
			}
			else if let originalSpacing = originalSpacing
			{
				spacing = originalSpacing
				self.originalSpacing = nil
			}
		}
	}
}
