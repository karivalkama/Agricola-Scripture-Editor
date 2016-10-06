//
//  Paragraph.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 5.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

class Paragraph: AttributedStringConvertible, PotentialVerseRangeable
{
	// ATTRIBUTES	---------
	
	var content = [Para]()
	
	
	// COMP. PROPS	---------
	
	var range: VerseRange?
	{
		return Paragraph.range(of: content)
	}
	
	
	// INIT	----------
	
	init(content: [Para])
	{
		self.content = content
	}
	
	convenience init(content: Para)
	{
		self.init(content: [content])
	}
	
	init(content: NSAttributedString)
	{
		replaceContents(with: content)
	}
	
	
	// AttributedStringConvertible	-----
	
	func toAttributedString() -> NSAttributedString
	{
		let str = NSMutableAttributedString()
		
		for para in content
		{
			// Paras other than the first are indicated with a newline character
			var paraIdentifier = "\n"
			
			// Parses the style information for the first para element
			// At this point the paragraph range is used to mark the start. Replace with a better solution when possible
			if str.length == 0
			{
				if let range = range
				{
					paraIdentifier = range.name + ". "
				}
				else
				{
					paraIdentifier = " "
				}
			}
			
			let paraMarker = NSAttributedString(string: paraIdentifier, attributes: [ParaMarkerAttributeName : para.style, ParaStyleAttributeName : para.style])
			str.append(paraMarker)
			
			// Adds para contents
			str.append(para.toAttributedString())
		}
		
		return str
	}
	
	func replaceContents(with usxString: NSAttributedString)
	{
		// Deletes previous content
		self.content = []
		
		// Parses the para content ranges and generates the para elements
		let paraRanges = parseParaRanges(from: usxString)
		for (style, contentRange) in paraRanges
		{
			content.append(Para(content: usxString.attributedSubstring(from: contentRange), style: style))
		}
	}
	
	private func parseParaRanges(from usxString: NSAttributedString) -> [(ParaStyle, NSRange)]
	{
		// Enumerates through the paramarker attribute values and collects each range for style
		var parsedRanges = [(ParaStyle, NSRange)]()
		var lastStyle: ParaStyle?
		var lastRangeStart = 0
		
		usxString.enumerateAttribute(ParaMarkerAttributeName, in: NSMakeRange(0, usxString.length), options: [])
		{
			value, range, _ in
			
			// If a new para marker is found, the last range is parsed and new one begins
			if let style = value as? ParaStyle
			{
				if let lastStyle = lastStyle
				{
					parsedRanges.append((lastStyle, NSMakeRange(lastRangeStart, range.location - lastRangeStart)))
					lastRangeStart = range.location + range.length
				}
				
				lastStyle = style
			}
		}
		// Appends the last para range as well
		if let style = lastStyle
		{
			parsedRanges.append((style, NSMakeRange(lastRangeStart, usxString.length - lastRangeStart)))
		}
		
		return parsedRanges
	}
}




