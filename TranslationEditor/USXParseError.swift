//
//  USXParseError.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
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
