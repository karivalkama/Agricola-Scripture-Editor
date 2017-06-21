//
//  USXAttributes.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// the value of a charStyle attribute should be a CharStyle
let CharStyleAttributeName = NSAttributedStringKey("charStyle")

// IsNoteAttribute is used for marking areas in string that contain note data
// The value should be a boolean determining whether this area should be considered to be a note (no attribute is considered false)
let IsNoteAttributeName = NSAttributedStringKey("isNote")
// NoteMarkerAttribute value determines whether the marker is considered to be a start (true) or end (false) of a note
let NoteMarkerAttributeName = NSAttributedStringKey("noteMarker")

// the value of a verseIndexMarker attribute should be the verse index as an integer
let VerseIndexMarkerAttributeName = NSAttributedStringKey("verseIndexMarker")

// Para marker and para style have the para style as values
let ParaMarkerAttributeName = NSAttributedStringKey("paraMarker")
let ParaStyleAttributeName = NSAttributedStringKey("paraStyle")

// The value of this attribute should be the chapter index
let ChapterMarkerAttributeName = NSAttributedStringKey("chapterMarker")


let chapterMarkerFont = UIFont(name: "Arial", size: 32.0)!
let defaultParagraphFont = UIFont(name: "Arial", size: 16.0)!
let headingFont = UIFont(name: "Arial", size: 24.0)!
let quotationFont = defaultParagraphFont.withItalic ?? defaultParagraphFont
let notesFont = UIFont(name: "Arial", size: 12.0)!

enum ParagraphStyling
{
	case rightAlignment
	case indented(level: Int)
	case centered
	case thin
	case list(level: Int)
	
	
	// COMPUTED PROPERTIES	----------
	
	var style: NSParagraphStyle
	{
		let style = NSMutableParagraphStyle()
		let indentStep: CGFloat = 32
		
		switch self
		{
		case .rightAlignment: style.alignment = .right
		case .indented(let level):
			style.firstLineHeadIndent = indentStep * CGFloat(level)
			style.headIndent = indentStep * CGFloat(level)
		case .centered: style.alignment = .center
		case .thin:
			style.firstLineHeadIndent = indentStep
			style.headIndent = indentStep
			style.tailIndent = indentStep
		case .list(let level):
			let firstIndent = indentStep * CGFloat(level)
			style.firstLineHeadIndent = firstIndent
			style.headIndent = firstIndent + indentStep
		}
		
		return style
	}
}
