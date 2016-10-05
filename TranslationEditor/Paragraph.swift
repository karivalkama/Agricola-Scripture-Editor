//
//  Paragraph.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 5.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

class Paragraph
{
	// ATTRIBUTES	---------
	
	private var content = [Para]()
	
	
	// COMP. PROPS	---------
	
	var range: VerseRange?
	{
		var start: VerseIndex?
		for para in content
		{
			if let range = para.range
			{
				start = range.start
				break
			}
		}
		
		var end: VerseIndex?
		for para in content.reversed()
		{
			if let range = para.range
			{
				end = range.end
				break
			}
		}
		
		if let start = start, let end = end
		{
			return VerseRange(start, end)
		}
		else
		{
			return nil
		}
	}
	
	
	// AttributedStringConvertible	-----
	
	func toAttributedString() -> NSAttributedString
	{
		let str = NSMutableAttributedString()
		
		// Parses the style information for the first para element
		
		return str
	}
}
