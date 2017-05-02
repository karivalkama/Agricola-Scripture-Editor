//
//  CellInputListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Classes implementing this protocol are informed when the user makes some changes to cell contents
protocol CellInputListener: class
{
	// This method is called each time the contents of a cell change
	// Only user initiated changes are sent
	func cellContentChanged(originalParagraph: Paragraph, newContent: NSAttributedString)
}
