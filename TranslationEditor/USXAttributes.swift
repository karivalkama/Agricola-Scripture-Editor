//
//  USXAttributes.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// the value of a charStyle attribute should be a CharStyle
let CharStyleAttributeName = "charStyle"

// IsNoteAttribute is used for marking areas in string that contain note data
// The value should be a boolean determining whether this area should be considered to be a note (no attribute is considered false)
let IsNoteAttributeName = "isNote"
// NoteMarkerAttribute value determines whether the marker is considered to be a start (true) or end (false) of a note
let NoteMarkerAttributeName = "noteMarker"

// the value of a verseIndexMarker attribute should be the verse index as an integer
let VerseIndexMarkerAttributeName = "verseIndexMarker"

// Para marker and para style have the para style as values
let ParaMarkerAttributeName = "paraMarker"
let ParaStyleAttributeName = "paraStyle"

// The value of this attribute should be the chapter index
let ChapterMarkerAttributeName = "chapterMarker"


let chapterMarkerFont = UIFont(name: "Arial", size: 32.0)!
let defaultParagraphFont = UIFont(name: "Arial", size: 16.0)!
let headingFont = UIFont(name: "Arial", size: 24.0)!
let quotationFont = defaultParagraphFont.withItalic ?? defaultParagraphFont
let notesFont = UIFont(name: "Arial", size: 12.0)!
