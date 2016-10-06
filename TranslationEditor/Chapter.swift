//
//  Chapter.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Chapters consist of multiple sections
struct Chapter: PotentialVerseRangeable
{
	// ATTRIBUTES	----------
	
	let index: Int
	var sections: [Section]
	
	
	// COMP. PORPS	----------
	
	var range: VerseRange?
	{
		return Chapter.range(of: sections)
	}
	
	
	// INIT	-------
	
	init(index: Int, content: [Section])
	{
		self.index = index
		self.sections = content
	}
}
