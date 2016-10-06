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
		get
		{
			let index = headingIndex
			if let (paragraphIndex, paraIndex) = index
			{
				return content[paragraphIndex].content[paraIndex]
			}
			else
			{
				return nil
			}
		}
		set
		{
			// Finds the index of an existing heading
			let index = headingIndex
			if let (paragraphIndex, paraIndex) = index
			{
				// If heading is found and new value is provided, replaces the element
				if let newValue = newValue
				{
					content[paragraphIndex].content[paraIndex] = newValue
				}
				// If heading is found but new value is not provided, deletes the existing heading
				else
				{
					var paragraph = content[paragraphIndex]
					if paragraph.content.count <= 1
					{
						content.remove(at: paragraphIndex)
					}
					else
					{
						paragraph.content.remove(at: paraIndex)
					}
				}
			}
			// If heading is not found and new value is provided, inserts the provided heading as a new separate paragraph to the beginning of the section
			else if let newValue = newValue
			{
				content.insert(Paragraph(content: newValue), at: 0)
			}
		}
	}
	
	var name: String?
	{
		return heading?.text
	}
	
	var text: String
	{
		var text = ""
		
		for i in 0 ..< content.count
		{
			if i != 0
			{
				text.append("\n\n")
			}
			text.append(content[i].text)
		}
		
		return text
	}
	
	private var headingIndex: (Int, Int)?
	{
		for paragraphIndex in 0 ..< content.count
		{
			let paragraph = content[paragraphIndex]
			
			for paraIndex in 0 ..< paragraph.content.count
			{
				if paragraph.content[paraIndex].style.isSectionHeadingStyle()
				{
					return (paragraphIndex, paraIndex)
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
