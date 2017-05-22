//
//  TranslationParagraphListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 23.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Classes conforming to this protocol should be informed when translation data changes
protocol TranslationParagraphListener: class
{
	// This method is called each time the translation paragraphs have been updated
	func translationParagraphsUpdated(_ paragraphs: [Paragraph])
}
