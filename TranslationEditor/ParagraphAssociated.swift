//
//  ParagraphAssociated.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// Paragraph-associated instances are bound to a certain paragraph path
protocol ParagraphAssociated
{
	// The path id of the associated paragraph
	var pathId: String? { get }
}
