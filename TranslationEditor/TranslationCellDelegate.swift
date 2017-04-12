//
//  TranslationCellDelegate.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Translation cell delegates implement / handle actions fired from translation cells
protocol TranslationCellDelegate
{
	// Performs an action fired from a translation cell
	func perform(action: TranslationCellAction, for cell: TranslationCell)
}
