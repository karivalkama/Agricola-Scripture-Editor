//
//  Section.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A section is a collection of paragraphs that creates a larger whole. Sections are placed inside chapters.
class Section
{
	// ATTRIBUTES	------
	
	var content: [Paragraph]
	
	
	// COMP. PROPS	------
	
	// TODO: Create a common protocol for this
	var range: VerseRange?
	{
		var start: VerseIndex?
		for paragraph in content
		{
			if let range = paragraph.range
			{
				start = range.start
				break
			}
		}
		
		var end: VerseIndex?
		for paragraph in content.reversed()
		{
			if let range = paragraph.range
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
	
	
	// INIT	--------------
	
	init(content: [Paragraph])
	{
		self.content = content
	}
	
	convenience init(header: Paragraph, content: [Paragraph])
	{
		var allContent = [Paragraph]()
		allContent.append(header)
		allContent.append(contentsOf: content)
		
		self.init(content: allContent)
	}
}
