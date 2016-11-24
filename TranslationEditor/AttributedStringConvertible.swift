//
//  File.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Instances conforming to this protocol can be parsed into attributed strings with existing USX attributes
protocol AttributedStringConvertible
{
	// Converts the instance to an attributed string. The possible usx style and structure information should be presented withing the string as attribute data
	func toAttributedString(options: [String : Any]) -> NSAttributedString
}
