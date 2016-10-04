//
//  VerseError.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These are the errors used in verse operations
enum VerseError: Error
{
	case versesAreSeparate
	case ambiguousTextPosition
	case ambiguousRange
}
