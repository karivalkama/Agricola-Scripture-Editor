//
//  TableCellSelectionListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Classes conforming to this protocol are willing to receive events when certain types of table view cells are selected
protocol TableCellSelectionListener: class
{
	// The cell reuse identifiers for the cell types this listener should be informed of
	var targetedCellIds: [String] { get }
	
	// This method will be called when a targeted table view cell is selected
	func onTableCellSelected(_ cell: UITableViewCell, identifier: String)
}
