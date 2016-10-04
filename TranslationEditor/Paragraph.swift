//
//  Paragraph.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

enum ParagraphStyle
{
	// Paragraph styles
	case normal
	case margin
	case embeddedTextOpening
	case embeddedTextParagraph
	case embeddedTextClosing
	case embeddedTextRefrain
	case indented(Int)
	case indentedFlushLeft
	case closureOfLetter
	case listItem(Int)
	case centered
	case liturgicalNote
	
	// Heading and title styles
	case sectionHeading(Int)
	case sectionHeadingMajor(Int)
	case descriptiveTitle
	case speakerIdentification
	
	// Poetry
	case poeticLine(Int)
	case poeticLineRight
	case poeticLineCentered
	case acrosticHeading
	case embeddedTextPoeticLine(Int)
	case blank
	
	// Other
	case other(String)
	
	// TODO: Add a protocol method for this
	var text: String
	{
		switch self
		{
		case .normal: return "p"
		case .margin: return "m"
		case .embeddedTextOpening: return "pmo"
		case .embeddedTextParagraph: return "pm"
		case .embeddedTextClosing: return "pmc"
		case .embeddedTextRefrain: return "pmr"
		case .indented(let depth): return "pi\(depth)"
		case .indentedFlushLeft: return "mi"
		case .closureOfLetter: return "cls"
		case .listItem(let depth): return "li\(depth)"
		case .centered: return "pc"
		case .liturgicalNote: return "lit"
		case .sectionHeadingMajor(let depth): return "ms\(depth)"
		case .sectionHeading(let depth): return "s\(depth)"
		case .descriptiveTitle: return "d"
		case .speakerIdentification: return "sp"
		case .poeticLine(let depth): return "q\(depth)"
		case .poeticLineRight: return "qr"
		case .poeticLineCentered: return "qc"
		case .acrosticHeading: return "qa"
		case .embeddedTextPoeticLine(let depth): return "qm\(depth)"
		case .blank: return "b"
		case .other(let code): return code
		}
	}
	
	// TODO: Parsing other way is required as well (when importing usx)
}

// A paragraph contains a range of text
// Each paragraph has a different styling information associated with it
class Paragraph: AttributedStringConvertible
{
	// ATTIRIBUTES	------
	
	var style: ParagraphStyle
	var content: [Verse]
	
	
	// COMPUTED PROPS.	---
	
	// The range of the paragraph. Nil if the paragraph doesn't have any content
	var range: VerseRange?
	{
		let start = content.first?.range.start
		let end = content.last?.range.end
		
		if let start = start, let end = end
		{
			return VerseRange(start: start, end: end)
		}
		else
		{
			return nil
		}
	}
	
	
	// INIT	------
	
	init(contents: [Verse] = [], style: ParagraphStyle = .normal)
	{
		self.style = style
		self.content = contents
	}
	
	init(content: Verse, style: ParagraphStyle = .normal)
	{
		self.style = style
		self.content = [content]
	}
	
	
	// IMPLEMENTED -----
	
	func toAttributedString() -> NSAttributedString
	{
		let str = NSMutableAttributedString()
		
		// Adds all verse data
		for verse in content
		{
			str.append(verse.toAttributedString())
		}
		
		return str
	}
	
	
	// OTHER	-------
	
	func replaceContents(with usxString: NSAttributedString) throws
	{
		let verseRanges = try parseRanges(from: usxString)
		var parsedVerses = [Verse]()
		
		// Goes through the parsed ranges the contents for each
		for (verseRange, stringRange) in verseRanges
		{
			var contents = [CharData]()
			
			usxString.enumerateAttribute(CharStyleAttributeName, in: stringRange, options: [])
			{
				value, range, _ in
				
				let string = (usxString.string as NSString).substring(with: range)
				
				// if the consecutive data have the same styling, they are appended to each other
				if var lastData = contents.last, lastData.style == value as? CharStyle
				{
					lastData.text.append(string)
				}
				// Otherwise a new charData section is added
				else
				{
					contents.append(CharData(text: string, style: value as? CharStyle))
				}
			}
			
			parsedVerses.append(Verse(range: verseRange, contents: contents))
		}
		
		// Replaces the existing data with parsed data
		self.content = parsedVerses
	}
	
	// Parses the string range for each verse range in the provided 'usxString'
	private func parseRanges(from usxString: NSAttributedString) throws -> [(VerseRange, NSRange)]
	{
		var verseRanges = [(verseRange: VerseRange, range: NSRange)]()
		var lastVerseIndex: (minIndex: VerseIndex, maxIndex: VerseIndex, startPosition: Int)?
		
		// Calculates the first index from the existing data (incomplete markers are not included in the string)
		if let start = range?.start
		{
			lastVerseIndex = (start, start, 0)
		}
		
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
						verseRanges.append((VerseRange(start: lastVerseIndex!.minIndex, end: newIndex), NSMakeRange(lastVerseIndex!.startPosition, range.location - lastVerseIndex!.startPosition)))
						
						lastVerseIndex = (newIndex, newIndex, range.location + range.length)
					}
				}
			}
		}
		
		// Adds the last range after all markers have been read
		if let lastVerseIndex = lastVerseIndex
		{
			let end = VerseIndex(lastVerseIndex.maxIndex.index, midVerse: true)
			verseRanges.append((VerseRange(start: lastVerseIndex.minIndex, end: end), NSMakeRange(lastVerseIndex.startPosition, usxString.length - lastVerseIndex.startPosition)))
		}
			// The range can't remain ambiguous forever
		else
		{
			throw VerseError.ambiguousRange
		}
		
		return verseRanges
	}
}



