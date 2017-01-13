//
//  ScrollSyncManager.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class handles the simultaneous scrolling of two scroll views
class ScrollSyncManager: NSObject, UITableViewDelegate
{
	// TYPES	-----------------
	
	// Target table view, associated path id -> index of the target table view's associated cell
	typealias IndexForPath = (UITableView, String) -> IndexPath?
	
	
	// ATTRIBUTES	-------------
	
	private weak var leftTableView: UITableView!
	private weak var rightTableView: UITableView!
	
	private var pathFinder: IndexForPath
	
	private var lastOffsetY: CGFloat = 0
	private var lastNewCell: AnyObject?
	
	
	// INIT	---------------------
	
	init(_ leftTable: UITableView, _ rightTable: UITableView, using pathFinder: @escaping IndexForPath)
	{
		leftTableView = leftTable
		rightTableView = rightTable
		
		self.pathFinder = pathFinder
		
		super.init()
		
		// TODO: Add to right table as well
		leftTableView.delegate = self
	}
	
	
	// IMPLEMENTED METHODS	----
	
	// TODO: Make it so that works both ways
	func scrollViewDidScroll(_ scrollView: UIScrollView)
	{
		print("STATUS: SCROLLING")
		
		// Keeps track of the direction of the drag / scroll
		let directionIsUp = scrollView.contentOffset.y < lastOffsetY
		
		// Finds the cell that was last displayed / made visible
		let visibleCells = leftTableView.visibleCells
		
		guard !visibleCells.isEmpty else
		{
			return
		}
		
		let newCell = directionIsUp ? visibleCells.first! : visibleCells.last!
		
		guard !(newCell === lastNewCell) else
		{
			return
		}
		lastNewCell = newCell
		
		// finds the matching cell in the other table
		guard let pathId = (newCell as? ParagraphAssociated)?.pathId else
		{
			print("ERROR: Path id of the cell is not available")
			return
		}
		
		print("STATUS: FINDING TARGET CELL")
		
		if let targetIndex = pathFinder(rightTableView, pathId)
		{
			print("STATUS: SYNC SCROLL")
			
			// Scrolls the other table so that the matching cell is visible
			rightTableView.scrollToRow(at: targetIndex, at: .none, animated: true)
		}
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
	{
		lastOffsetY = scrollView.contentOffset.y
	}
}
