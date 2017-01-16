//
//  ScrollSyncManager.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

fileprivate enum Side
{
	case left, right
	
	var opposite: Side
	{
		switch self
		{
		case .left: return .right
		case .right: return .left
		}
	}
}

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
	
	private var lastOffsetY: [Side : CGFloat] = [.left: 0, .right: 0]
	private var lastNewCell: AnyObject?
	
	private var syncScrolling: Side?
	
	
	// INIT	---------------------
	
	init(_ leftTable: UITableView, _ rightTable: UITableView, using pathFinder: @escaping IndexForPath)
	{
		leftTableView = leftTable
		rightTableView = rightTable
		
		self.pathFinder = pathFinder
		
		super.init()
		
		rightTable.delegate = self
		leftTableView.delegate = self
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func scrollViewDidScroll(_ scrollView: UIScrollView)
	{
		let scrolledSide = sideOfTable(scrollView)
		
		// Doesn't react to scrolls caused by sync scrolling
		guard scrolledSide != syncScrolling else
		{
			return
		}
		
		//print("STATUS: SCROLLING \(scrolledSide)")
		
		// Keeps track of the direction of the drag / scroll
		let directionIsUp = scrollView.contentOffset.y < lastOffsetY[scrolledSide]!
		
		// Finds the cell that was last displayed / made visible
		let visibleCells = tableOfSide(scrolledSide).visibleCells
		
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
		
		let syncScrollSide = scrolledSide.opposite
		let syncTarget = tableOfSide(syncScrollSide)
		if let targetIndex = pathFinder(syncTarget, pathId)
		{
			print("STATUS: SYNC SCROLL \(syncScrollSide)")
			
			// Scrolls the other table so that the matching cell is visible
			syncScrolling = syncScrollSide
			syncTarget.scrollToRow(at: targetIndex, at: .none, animated: true)
		}
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
	{
		updateOffSets()
		
		print("STATUS: SCROLLING ENDED")
		syncScrolling = nil
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
	{
		updateOffSets()
	}
	
	
	// OTHER METHODS	------
	
	private func sideOfTable(_ table: AnyObject) -> Side
	{
		if table === leftTableView
		{
			return .left
		}
		else
		{
			return .right
		}
	}
	
	private func tableOfSide(_ side: Side) -> UITableView
	{
		if side == .left
		{
			return leftTableView
		}
		else
		{
			return rightTableView
		}
	}
	
	private func updateOffSets()
	{
		lastOffsetY[.left] = leftTableView.contentOffset.y
		lastOffsetY[.right] = rightTableView.contentOffset.y
	}
}
