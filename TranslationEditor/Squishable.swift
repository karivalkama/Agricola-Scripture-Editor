//
//  Squishable.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 15.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Squishable elements can be squished horizontally or vertically to preserve space
protocol Squishable: class
{
	// Squishes or resets the object. Squishing can be done for a specific axis
	func setSquish(_ isSquished: Bool, along axis: UILayoutConstraintAxis)
}
