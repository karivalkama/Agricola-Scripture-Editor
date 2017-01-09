//
//  ResourceCategory.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These are the different resource categories available in the project
// TODO: Add more categories
enum ResourceCategory: Int
{
	// Source translation category contains the translation source material
	// which uses the same format as the target translation
	case sourceTranslation = 1
	// Notes are message threads concerning a paragraph in the target translation
	case notes = 2
	case other = 0
}
