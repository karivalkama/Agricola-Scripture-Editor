//
//  Paragraph.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A para is a range of text separated from others. A para has specific styling information 
// associated with it
struct Para: AttributedStringConvertible, PotentialVerseRangeable
{
	// ATTIRIBUTES	------
	
	// A para can have either defined verse content OR ambiguous text content. The two are exclusive.
	private var verseContent: [Verse] = []
	private var ambiguousContent: [CharData] = []
	var style: ParaStyle
	
	
	// COMPUTED PROPS.	---
	
	// The verse range of the para. Nil if the paragraph doesn't contain any verse markers
	var range: VerseRange?
	{
		let start = verseContent.first?.range.start
		let end = verseContent.last?.range.end
		
		if let start = start, let end = end
		{
			return VerseRange(start, end)
		}
		else
		{
			return nil
		}
	}
	
	// A collection of the para contents, whether split between verses or not
	var content: [CharData]
	{
		if verseContent.isEmpty
		{
			return ambiguousContent
		}
		else
		{
			var content = [CharData]()
			for verse in verseContent
			{
				content.append(contentsOf: verse.content)
			}
			
			return content
		}
	}
	
	
	// INIT	------
	
	init(content: [Verse] = [], style: ParaStyle = .normal)
	{
		self.style = style
		self.verseContent = content
	}
	
	init(content: Verse, style: ParaStyle = .normal)
	{
		self.init(content: [content], style: style)
	}
	
	// This initialiser doesn't specify any verse data in the para. Should be used only when verse range data is not available (headers, etc.)
	init(content: [CharData], style: ParaStyle)
	{
		self.style = style
		self.ambiguousContent = content
	}
	
	init(content: NSAttributedString, style: ParaStyle = .normal)
	{
		self.style = style
		replaceContents(with: content)
	}
	
	
	// IMPLEMENTED -----
	
	func toAttributedString() -> NSAttributedString
	{
		let str = NSMutableAttributedString()
		
		// Adds all verse data
		for verse in verseContent
		{
			str.append(verse.toAttributedString())
		}
		// or ambiguous content
		for charData in ambiguousContent
		{
			str.append(charData.toAttributedString())
		}
		
		// Sets paragraph style as well
		str.addAttribute(ParaStyleAttributeName, value: style, range: NSMakeRange(0, str.length))
		
		return str
	}
	
	
	// OTHER	-------
	
	mutating func replaceContents(with usxString: NSAttributedString)
	{
		// Deletes previous contents
		self.verseContent = []
		self.ambiguousContent = []
		
		// Function for parsing character data from the provided usxString
		// The array will contain the parsed data. Should be emptied after each iteration.
		var parsedData = [CharData]()
		func parseCharData(style: Any?, in range: NSRange, stop: UnsafeMutablePointer<ObjCBool>)
		{
			let string = (usxString.string as NSString).substring(with: range)
			
			// if the consecutive data have the same styling, they are appended to each other
			if var lastData = parsedData.last, lastData.style == style as? CharStyle
			{
				lastData.text.append(string)
			}
				// Otherwise a new charData section is added
			else
			{
				parsedData.append(CharData(text: string, style: style as? CharStyle))
			}
		}
		
		do
		{
			let verseRanges = try Para.parseRanges(from: usxString)
			
			var parsedVerses = [Verse]()
			
			// Goes through the parsed ranges and adds content for each
			for (verseRange, stringRange) in verseRanges
			{
				usxString.enumerateAttribute(CharStyleAttributeName, in: stringRange, options: [], using: parseCharData)
				
				parsedVerses.append(Verse(range: verseRange, content: parsedData))
				parsedData = []
			}
			
			// Replaces the existing data with parsed data
			self.verseContent = parsedVerses
		}
		catch VerseError.ambiguousRange
		{
			// If the range is ambigous, parses the data without verses
			usxString.enumerateAttribute(CharStyleAttributeName, in: NSMakeRange(0, usxString.length), options: [], using: parseCharData)
			self.ambiguousContent = parsedData
			parsedData = []
		}
		catch
		{
			fatalError("unhandled error \(error)")
		}
	}
	
	// Parses the string range for each verse range in the provided 'usxString'
	private static func parseRanges(from usxString: NSAttributedString) throws -> [(VerseRange, NSRange)]
	{
		var verseRanges = [(verseRange: VerseRange, range: NSRange)]()
		var lastVerseIndex: (minIndex: VerseIndex, maxIndex: VerseIndex, startPosition: Int)?
		
		// Calculates the verse ranges first
		usxString.enumerateAttribute(VerseIndexMarkerAttributeName, in: NSMakeRange(0, usxString.length), options: [])
		{
			value, range, _ in
			
			// If a marker is found, records it
			if let index = value as? Int
			{
				// If the marker is at the very start of the paragraph string, it becomes the very first
				// verse regardless of the paragraph's previous range
				if range.location == 0
				{
					lastVerseIndex = (VerseIndex(index), VerseIndex(index), range.length)
				}
				else
				{
					// The paragraph range start is defined at this point, if not already
					if lastVerseIndex == nil
					{
						let start = VerseIndex(index - 1, midVerse: true)
						lastVerseIndex = (start, start, 0)
					}
					
					let newIndex = VerseIndex(index)
					
					// If the indices are side by side, they are considered to be one longer range
					// (ie. The later index is simply ignored and added to the previous one(s) after the end of that range is reached)
					if lastVerseIndex!.startPosition >= range.location
					{
						lastVerseIndex = (lastVerseIndex!.minIndex, newIndex, lastVerseIndex!.startPosition)
					}
						// Otherwise completes and records the preceeding range
					else
					{
						verseRanges.append((VerseRange(lastVerseIndex!.minIndex, newIndex), NSMakeRange(lastVerseIndex!.startPosition, range.location - lastVerseIndex!.startPosition)))
						
						lastVerseIndex = (newIndex, newIndex, range.location + range.length)
					}
				}
			}
		}
		
		// Adds the last range after all markers have been read
		if let lastVerseIndex = lastVerseIndex
		{
			let end = VerseIndex(lastVerseIndex.maxIndex.index, midVerse: true)
			verseRanges.append((VerseRange(lastVerseIndex.minIndex, end), NSMakeRange(lastVerseIndex.startPosition, usxString.length - lastVerseIndex.startPosition)))
		}
			// The range can't remain ambiguous forever
		else
		{
			throw VerseError.ambiguousRange
		}
		
		return verseRanges
	}
}



