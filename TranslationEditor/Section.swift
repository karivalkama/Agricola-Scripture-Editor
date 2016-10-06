//
//  Section.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A section is a collection of paragraphs that creates a larger whole. Sections are placed inside chapters.
struct Section: PotentialVerseRangeable
{
	// ATTRIBUTES	------
	
	var content: [Paragraph]
	
	
	// COMP. PROPS	------
	
	var range: VerseRange?
	{
		return Section.range(of: content)
	}
	
	// The heading element of this section, if present
	var heading: Para?
	{
		for paragraph in content
		{
			for para in paragraph.content
			{
				if para.style.isSectionHeadingStyle()
				{
					return para
				}
			}
		}
		
		return nil
	}
	
	
	// INIT	--------------
	
	init(content: [Paragraph])
	{
		self.content = content
	}
	
	init(header: Paragraph, content: [Paragraph])
	{
		var allContent = [Paragraph]()
		allContent.append(header)
		allContent.append(contentsOf: content)
		
		self.init(content: allContent)
	}
}
