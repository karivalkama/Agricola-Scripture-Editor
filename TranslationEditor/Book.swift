//
//  Book.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Books are translated units that contain a number of chapters each
class Book
{
	// ATTRIBUTES	-------
	
	var chapters = [Chapter]()
	var name: String
	var introduction: Paragraph
	var code: String
	
	
	// INIT	---------------
	
	init(code: String, name: String, content: [Chapter], introduction: Paragraph = Paragraph(content: []))
	{
		self.code = code
		self.name = name
		self.chapters = content
		self.introduction = introduction
	}
	
	
	// OTHER METHODS	--
	
	func toAttributedStringCollection(displayParagraphRanges: Bool = true) -> [NSAttributedString]
	{
		var strings = [NSAttributedString]()
		
		for chapter in chapters
		{
			var chapterMarkerAdded = false
			
			for section in chapter.sections
			{
				for paragraph in section.content
				{
					var options: [String : Any] = [Paragraph.optionDisplayParagraphRange : displayParagraphRanges]
					if !chapterMarkerAdded
					{
						options[Paragraph.optionDisplayedChapterIndex] = chapter.index
						chapterMarkerAdded = true
					}
					
					strings.append(paragraph.toAttributedString(options: options))
				}
			}
		}
		
		return strings
	}
}
