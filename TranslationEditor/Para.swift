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
final class Para: AttributedStringConvertible, PotentialVerseRangeable, JSONConvertible, Copyable, USXConvertible
{
	// ATTIRIBUTES	------
	
	// A para can have either defined verse content OR ambiguous text content. The two are exclusive.
	var verses: [Verse] = []
	var ambiguousContent: TextWithNotes?
	var style: ParaStyle
	
	
	// COMPUTED PROPS.	---
	
	var toUSX: String
	{
		return "<para style=\"\(style.code)\">\(ambiguousContent == nil ? verses.reduce("", { $0 + $1.toUSX }) : ambiguousContent!.toUSX)</para>"
	}
	
	// The verse range of the para. Nil if the paragraph doesn't contain any verse markers
	var range: VerseRange?
	{
		let start = verses.first?.range.start
		let end = verses.last?.range.end
		
		if let start = start, let end = end
		{
			return VerseRange(start, end)
		}
		else
		{
			return nil
		}
	}
	
	var properties: [String : PropertyValue]
	{
		var properties = ["style" : style.code.value]
		
		// Verses and ambiguous content are mutually exclusive
		if verses.isEmpty
		{
			properties["ambiguous_content"] = ambiguousContent.value
		}
		else
		{
			properties["verses"] = verses.value
		}
		
		return properties
	}
	
	// A collection of the para contents, whether split between verses or not
	var content: [ParaContent]
	{
		if let ambiguousContent = ambiguousContent
		{
			return ambiguousContent.content
		}
		else
		{
			return verses.flatMap { $0.content.content }
		}
	}
	
	var text: String
	{
		return content.reduce("", { $0 + $1.text })
	}
	
	// Whether the whole para element is filled with text
	var isFilled: Bool
	{
		if let ambiguousContent = ambiguousContent
		{
			return ambiguousContent.isFilled
		}
		else
		{
			return verses.forAll { $0.content.isFilled }
		}
	}
	
	// Calculates how much of the para element has been filled / completed
	// Checks on verse by berse basis, although paras with no verses are considered to have 1 element
	var completion: (filledVerses: Int, total: Int)
	{
		if let ambiguousContent = ambiguousContent
		{
			return ambiguousContent.isFilled ? (1, 1) : (0, 1)
		}
		else
		{
			return (verses.count(where: { $0.content.isFilled }), verses.count)
		}
	}
	
	
	// INIT	------
	
	init(content: [Verse] = [], style: ParaStyle = .normal)
	{
		self.style = style
		self.verses = content
	}
	
	convenience init(content: Verse, style: ParaStyle = .normal)
	{
		self.init(content: [content], style: style)
	}
	
	// This initialiser doesn't specify any verse data in the para. Should be used only when verse range data is not available (headers, etc.)
	init(content: TextWithNotes, style: ParaStyle)
	{
		self.style = style
		self.ambiguousContent = content
	}
	
	/*
	init(content: NSAttributedString, style: ParaStyle = .normal)
	{
		self.style = style
		replaceContents(with: content)
	}*/
	
	// Parses a para element from JSON data
	// Throws a JSONParseError if the contents of an optional 'verses' element were invalid or incomplete
	static func parse(from propertyData: PropertySet) throws -> Para
	{
		var style = ParaStyle.normal
		if let styleValue = propertyData["style"].string
		{
			style = ParaStyle.value(of: styleValue)
		}
		
		// Some Paras contain 'verses' -element, others contain 'ambiguousContent' -element
		if let versesValue = propertyData["verses"].array
		{
			return Para(content: try Verse.parseArray(from: versesValue, using: Verse.parse), style: style)
		}
		else
		{
			return Para(content: TextWithNotes.parse(from: propertyData["ambiguous_content"].object()), style: style)
		}
	}
	
	
	// IMPLEMENTED -----
	
	func copy() -> Para
	{
		if let ambiguousContent = ambiguousContent
		{
			return Para(content: ambiguousContent.copy(), style: style)
		}
		else
		{
			return Para(content: verses.copy(), style: style)
		}
	}
	
	func contentEquals(with other: Para) -> Bool
	{
		// print("STATUS: Checking if two para element contents are equal")
		if style != other.style
		{
			// print("STATUS: Different style -> Not equal")
			return false
		}
		
		if let ambiguousContent = ambiguousContent
		{
			if let otherAmbiguousContent = other.ambiguousContent
			{
				// print("STATUS: Comparing ambiguous para contents")
				return ambiguousContent.contentEquals(with: otherAmbiguousContent)
			}
			else
			{
				// print("STATUS: Only one of the paras has verses")
				return false
			}
		}
		else
		{
			// print("STATUS: Comparing verses (\(verses.count) vs \(other.verses.count))")
			return verses.contentEquals(with: other.verses)
		}
	}
	
	func toAttributedString(options: [String : Any]) -> NSAttributedString
	{
		let str = NSMutableAttributedString()
		
		// Adds either ambiguous content or verse data
		if let ambiguousContent = ambiguousContent
		{
			str.append(ambiguousContent.toAttributedString(options: options))
		}
		else
		{
			verses.forEach { str.append($0.toAttributedString(options: options)) }
		}
		
		// Sets paragraph style as well
		str.addAttribute(ParaStyleAttributeName, value: style, range: NSMakeRange(0, str.length))
		
		return str
	}
	
	
	// OTHER	-------
	
	// Creates a copy of this para element without any character data content
	func emptyCopy() -> Para
	{
		if let ambiguousContent = ambiguousContent
		{
			return Para(content: ambiguousContent.emptyCopy(), style: style)
		}
		else
		{
			return Para(content: verses.map { $0.emptyCopy() }, style: style)
		}
	}
	
	func update(with attString: NSAttributedString)
	{
		do
		{
			let verseRanges = try Para.parseRanges(from: attString)
			
			// If the old verses have a longer range, cuts out the unnecessary bits
			let firstVerseIndex = verseRanges.first!.0.start
			while let firstVerse = verses.first, firstVerse.range.start < firstVerseIndex
			{
				if firstVerse.range.contains(index: firstVerseIndex)
				{
					firstVerse.range = VerseRange(firstVerseIndex, firstVerse.range.end)
				}
				else
				{
					verses.removeFirst()
				}
			}
			
			let endIndex = verseRanges.last!.0.end
			while let lastVerse = verses.last, lastVerse.range.end > endIndex
			{
				if lastVerse.range.contains(index: endIndex)
				{
					lastVerse.range = VerseRange(lastVerse.range.start, endIndex)
				}
				else
				{
					verses.removeLast()
				}
			}
			
			// If the parsed range is longer than the original, adds empty buffers
			if verses.isEmpty
			{
				verses.add(Verse(range: VerseRange(firstVerseIndex, endIndex)))
			}
			else
			{
				if verses.first!.range.start > firstVerseIndex
				{
					verses.insert(Verse(range: VerseRange(firstVerseIndex, verses.first!.range.start)), at: 0)
				}
				if verses.last!.range.end < endIndex
				{
					verses.add(Verse(range: VerseRange(verses.last!.range.end, endIndex)))
				}
			}
			
			// Starts matching the verses, altering the range combinations to those of the new data
			for i in 0 ..< verseRanges.count
			{
				let (verseRange, stringRange) = verseRanges[i]
				let subString = attString.attributedSubstring(from: stringRange)
				let matchingVerse = verses[i]
				
				// The starts of the verses should match on each iteration
				if verseRange.start != matchingVerse.range.start
				{
					print("ERROR: Verse matching algorithm is malfunctioning. \(verseRange) is being matched against \(matchingVerse.range)")
				}
				
				// If the new range is longer than the matched range, combines target verses until enough range is covered
				while verseRange.end > matchingVerse.range.end, i + 1 < verses.count
				{
					let nextVerse = verses.remove(at: i + 1)
					matchingVerse.content = matchingVerse.content + nextVerse.content
					matchingVerse.range = VerseRange(matchingVerse.range.start, nextVerse.range.end)
				}
				
				// If the new range is smaller than the now matched range, 
				// Matches the new shorter data against the longer range, 
				// then forms a new range from the cutOff material
				if verseRange.end < matchingVerse.range.end
				{
					let newContent = matchingVerse.content.update(with: subString) ?? TextWithNotes()
					verses.insert(Verse(range: VerseRange(verseRange.end, matchingVerse.range.end), content: newContent), at: i + 1)
				}
				// If the ranges match, just updates the verse
				else
				{
					// There should be no cutoff in this merge
					if let cutOff = matchingVerse.content.update(with: subString)
					{
						print("ERROR: Verse matching algorithm is not working correctly. '\(cutOff.text)' was removed from the matched verse upon update.")
					}
				}
			}
		}
		catch VerseError.ambiguousRange
		{
			// If the range was ambiguous, parses the data into the ambiguous content slot
			if let ambiguousContent = ambiguousContent
			{
				if let cutOff = ambiguousContent.update(with: attString)
				{
					print("ERROR: '\(cutOff.text)' was cut off when updating the para element")
				}
			}
			else
			{
				print("ERROR: Para contains \(verses.count) verses but no verse range could be parsed from '\(attString.string)'")
			}
		}
		catch
		{
			print("ERROR: Failed to update para data. \(error)")
		}
	}
	
	/*
	func replaceContents(with usxString: NSAttributedString)
	{
		// Deletes previous contents
		self.verses = []
		self.ambiguousContent = []
		
		// Function for parsing character data from the provided usxString
		// The array will contain the parsed data. Should be emptied after each iteration.
		var parsedData = [CharData]()
		func parseCharData(style: Any?, in range: NSRange, stop: UnsafeMutablePointer<ObjCBool>)
		{
			let string = (usxString.string as NSString).substring(with: range)
			let style = style as? CharStyle
			
			// if the consecutive data have the same styling, they are appended to each other
			if let lastData = parsedData.last, lastData.style == style
			{
				let combinedText = lastData.text.appending(string)
				parsedData[parsedData.count - 1] = CharData(text: combinedText, style: style)
			}
			// Otherwise a new charData section is added
			else
			{
				parsedData.append(CharData(text: string, style: style))
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
			self.verses = parsedVerses
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
	}*/
	
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
					/*
					if lastVerseIndex!.startPosition >= range.location
					{
						lastVerseIndex = (lastVerseIndex!.minIndex, newIndex, range.location + range.length)
					}*/
						// Otherwise completes and records the preceeding range
					//else
					//{
					verseRanges.append((VerseRange(lastVerseIndex!.minIndex, newIndex), NSMakeRange(lastVerseIndex!.startPosition, range.location - lastVerseIndex!.startPosition)))
					lastVerseIndex = (newIndex, newIndex, range.location + range.length)
					//}
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



