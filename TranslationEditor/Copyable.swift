//
//  Copyable.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// All copyable instances can create a copy of themselves
protocol Copyable
{
	func copy() -> Self
}
