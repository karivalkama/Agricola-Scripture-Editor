//
//  FootNote.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

class FootNote
{
	// ATTRIBUTES	------------
	
	var caller: String
	var style: String
	var originReference: String?
	// Text data and an attribute specifying whether the data is "closed"
	var charData: [CharData]
	
	
	// INIT	--------------------
	
	init(caller: String, style: String, originReference: String? = nil, charData: [CharData] = [])
	{
		self.caller = caller
		self.style = style
		self.charData = charData
		self.originReference = originReference
	}
}
