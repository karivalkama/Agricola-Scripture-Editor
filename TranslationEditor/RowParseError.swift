//
//  RowParseError.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These errors are thrown when a CBL row can't be parsed properly
enum RowParseError: Error
{
	// This error is thrown when document properties can't be retrieved from a row
	case documentPropertiesMissing
	// This error is thrown when dealing with rows with no documentId
	case documentIdMissing
}
