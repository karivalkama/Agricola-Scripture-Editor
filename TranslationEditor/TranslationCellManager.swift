//
//  CellCreationDelegate.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This protocol can be used along with some table view controllers in order to provide custom cell content and management
@available(*, deprecated)
protocol TranslationCellManager
{
	// Provides custom content for a certain cell. Nil if original content should be used.
	func overrideContentForParagraph(_ paragraph: Paragraph) -> NSAttributedString?
	
	// This is called after creation and updating of a cell, before it is updated to the table view
	func cellUpdated(_ cell: TranslationCell, paragraph: Paragraph)
}
