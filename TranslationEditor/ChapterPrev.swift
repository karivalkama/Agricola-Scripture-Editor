//
//  Chapter.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Chapters consist of multiple sections
@available (*, deprecated)
class ChapterPrev: PotentialVerseRangeable
{
	// ATTRIBUTES	----------
	
	let index: Int
	var sections: [SectionPrev]
	
	
	// COMP. PORPS	----------
	
	var range: VerseRange?
	{
		return ChapterPrev.range(of: sections)
	}
	
	
	// INIT	-------
	
	init(index: Int, content: [SectionPrev])
	{
		self.index = index
		self.sections = content
	}
}
