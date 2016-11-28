//
//  JSONParseError.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These errors are thrown when some JSON data can't be parsed into desired format
struct JSONParseError: Error
{
	let data: PropertySet
	let message: String
}
