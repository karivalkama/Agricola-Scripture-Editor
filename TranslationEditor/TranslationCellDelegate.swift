//
//  TranslationCellDelegate.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// Translation cell delegates implement / handle actions fired from translation cells
protocol TranslationCellDelegate: class
{
	// Performs an action fired from a translation cell
	func perform(action: TranslationCellAction, for cell: TargetTranslationCell)
}
