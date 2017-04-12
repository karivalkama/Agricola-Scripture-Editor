//
//  TranslationCellAction.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// These are different actions / functions that can be accessed through a translation cell
// Since UI space is often limited, a cell is supposed to have only up to one primary action at a time
enum TranslationCellAction
{
	case openNotes(atIndex: Int)
	case resolveConflict
	
	
	var icon: UIImage
	{
		switch (self)
		{
		case .openNotes(_): return #imageLiteral(resourceName: "flag")
		case .resolveConflict: return #imageLiteral(resourceName: "conflictArrows_red")
		}
	}
}
