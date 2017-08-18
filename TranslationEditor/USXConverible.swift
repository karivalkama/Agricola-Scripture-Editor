//
//  USXConverible.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// Instances conforming to this protocol can be written as USX data
protocol USXConvertible
{
	// Converts this instance to a usx string
	var toUSX: String { get }
}
