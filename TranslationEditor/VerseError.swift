//
//  VerseError.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.9.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// These are the errors used in verse operations
enum VerseError: Error
{
	case versesAreSeparate
	case ambiguousTextPosition
	case ambiguousRange
}
