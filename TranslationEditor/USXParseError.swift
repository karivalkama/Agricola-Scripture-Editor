//
//  USXParseError.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.10.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

enum USXParseError: Error
{
	case verseIndexNotFound
	case verseIndexParsingFailed(indexAttribute: String)
	case verseRangeParsingFailed
	case chapterIndexNotFound
	case bookNameNotSpecified
	case bookCodeNotFound
	case attributeMissing(requiredAttributeName: String)
	case unknownNoteStyle(style: String)
}
