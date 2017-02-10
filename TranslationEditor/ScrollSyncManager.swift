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
	typealias IndexForPath = (UITableView, String) -> [IndexPath]
	
	
	// ATTRIBUTES	-------------
	
	private weak var leftTableView: UITableView!
	private weak var rightTableView: UITableView!
	
	private var pathFinder: IndexForPath
	
	private var lastOffsetY: [Side : CGFloat] = [.left: 0, .right: 0]
	private var lastOffsetTime: [Side : TimeInterval] = [.left: 0, .right: 0]
	private var lastVelocity: [Side : CGFloat] = [.left: 0, .right: 0]
	private var lastAcceleration: [Side : CGFloat] = [.left: 0, .right: 0]
	private var isDragging = false
	
	private var lastCenterCell: AnyObject?
	
	private var syncScrolling: Side?
	
	private var cellHeights: [String : [IndexPath : CGFloat]]
	private let defaultCellHeight: CGFloat = 640
	private var currentHeightIds: [Side : String]
	
	
	// COMPUTED PROPERTIES	-----
	
	var leftResourceId: String
	{
		get { return currentHeightIds[.left]! }
		set
		{
			if !cellHeights.containsKey(newValue)
			{
				cellHeights[newValue] = [:]
			}
			currentHeightIds[.left] = newValue
		}
	}
	
	
	// INIT	---------------------
	
	init(leftTable: UITableView, rightTable: UITableView, leftResourceId: String, rightResourceId: String, using pathFinder: @escaping IndexForPath)
	{
		leftTableView = leftTable
		rightTableView = rightTable
		
		self.pathFinder = pathFinder
		
		cellHeights = [String : [IndexPath : CGFloat]]()
		cellHeights[leftResourceId] = [:]
		cellHeights[rightResourceId] = [:]
		
		currentHeightIds = [Side.left: leftResourceId, Side.right: rightResourceId]
		
		super.init()
		
		rightTable.delegate = self
		leftTableView.delegate = self
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
	{
		return cellHeight(side: sideOfTable(tableView), index: indexPath)
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView)
	{
		let scrolledSide = sideOfTable(scrollView)
		
		// When the table is scrolled to top or bottom, the other table will be too
		if scrollView.isAtTop
		{
			tableOfSide(scrolledSide.opposite).scrollToTop()
		}
		else if scrollView.isAtBottom
		{
			tableOfSide(scrolledSide.opposite).scrollToBottom()
		}
		// Otherwise the tables are matched by their center cells
		else
		{
			// Records the scroll speed
			let currentTime = Date().timeIntervalSince1970
			let duration = currentTime - lastOffsetTime[scrolledSide]!
			
			// Doesn't record very short intervals
			if duration >= 0.1
			{
				let offsetY = scrollView.contentOffset.y
				
				// If the interval is very long, there hasn't been a scroll for a while and the program needs to recollect the material
				if duration <= 1
				{
					// x = x0 + v*t
					// -> v = (x - x0) / t
					let velocity = (offsetY - lastOffsetY[scrolledSide]!) / CGFloat(duration)
					
					// Calculates the deceleration as well
					// a = (v - v0) / t
					let acceleration = (velocity - lastVelocity[scrolledSide]!) / CGFloat(duration)
					
					lastAcceleration[scrolledSide] = acceleration
					lastVelocity[scrolledSide] = velocity
				}
				else
				{
					lastAcceleration[scrolledSide] = 0
					lastVelocity[scrolledSide] = 0
				}
				
				lastOffsetY[scrolledSide] = offsetY
				lastOffsetTime[scrolledSide] = currentTime
			}
			
			// Doesn't react to scrolls caused by sync scrolling
			guard scrolledSide != syncScrolling else
			{
				return
			}
			
			syncScroll(toSide: scrolledSide, velocity: lastVelocity[scrolledSide]!, acceleration: lastAcceleration[scrolledSide]!, skipIfAnchorStill: true)
		}
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
	{
		syncScrolling = nil
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
	{
		isDragging = true
		
		if syncScrolling == sideOfTable(scrollView)
		{
			syncScrolling = nil
		}
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
	{
		isDragging = false
	}
	
	
	// OTHER METHODS	------
	
	func syncScrollToRight()
	{
		syncScroll(toSide: .right)
	}
	
	private func syncScroll(toSide anchorSide: Side, velocity: CGFloat = 0, acceleration: CGFloat = 0, skipIfAnchorStill: Bool = false)
	{
		let scrolledTable = tableOfSide(anchorSide)
		guard let newCell = centerCell(ofTable: scrolledTable, withVelocity: velocity, andAcceleration: acceleration) else
		{
			print("ERROR: No visible cells at \(anchorSide)")
			return
		}
		
		guard !(skipIfAnchorStill && newCell === lastCenterCell) else
		{
			return
		}
		lastCenterCell = newCell
		
		// finds the matching cell in the other table
		guard let pathId = (newCell as? ParagraphAssociated)?.pathId else
		{
			print("ERROR: Path id of the cell is not available")
			return
		}
		
		let syncScrollSide = anchorSide.opposite
		let syncTarget = tableOfSide(syncScrollSide)
		
		updateVisibleRowHeights(forTable: scrolledTable)
		updateVisibleRowHeights(forTable: syncTarget)
		
		if let targetIndex = centerIndex(of: pathFinder(syncTarget, pathId), onSide: syncScrollSide)
		{
			// Scrolls the other table so that the matching cell is visible
			syncScrolling = syncScrollSide
			syncTarget.scrollToRow(at: targetIndex, at: .middle, animated: true)
		}
	}
	
	private func updateVisibleRowHeights(forTable tableView: UITableView)
	{
		let heightId = currentHeightIds[sideOfTable(tableView)]!
		
		if let paths = tableView.indexPathsForVisibleRows
		{
			for indexPath in paths
			{
				cellHeights[heightId]?[indexPath] = tableView.rectForRow(at: indexPath).height
			}
		}
	}
	
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
	
	private func cellHeight(side: Side, index: IndexPath) -> CGFloat
	{
		return cellHeights[currentHeightIds[side]!]![index].or(defaultCellHeight)
	}
	
	private func centerIndex(of indexes: [IndexPath], onSide side: Side) -> IndexPath?
	{
		guard !indexes.isEmpty else
		{
			return nil
		}
		
		let heightId = currentHeightIds[side]!
		let heights = indexes.map { cellHeights[heightId]![$0].or(defaultCellHeight) }
		let totalHeight = heights.reduce(0, { $0 + $1 })
		
		let centerY = totalHeight / 2
		
		var y: CGFloat = 0
		for i in 0 ..< indexes.count
		{
			let nextY = y + heights[i]
			
			if nextY > centerY
			{
				return indexes[i]
			}
			
			y = nextY
		}
		
		return nil
	}
	
	// Velocity is in pixels per second
	private func centerCell(ofTable tableView: UITableView, withVelocity velocity: CGFloat, andAcceleration acceleration: CGFloat) -> UITableViewCell?
	{
		// Finds the index path of each cell
		let indexPaths = tableView.indexPathsForVisibleRows.or([])
		
		guard !indexPaths.isEmpty else
		{
			print("ERROR: No visible cells available")
			return nil
		}
		
		// Finds the height of each cell
		let cellHeights = indexPaths.map { tableView.rectForRow(at: $0).height }
		
		// Calculates the velocity modifier, which depends from dragging state, velocity and deceleration values
		let duration: CGFloat = isDragging ? 0 : 0.5
		// a = dv / dt
		// s = vt + at^2 / 2
		let travelDistance = velocity * duration + acceleration * duration * duration / 2
		
		// Calculates the height of the visible area
		let totalHeight = cellHeights.reduce(0, { result, h in return result + h })
		// The targeted center cell is at the center, but velocity is also taken into account (counts 0.5 second reaction time)
		let centerY = max(0, min(totalHeight / 2 + travelDistance, totalHeight - 1))
		
		// Finds the centermost cell
		var y:CGFloat = 0
		for i in 0 ..< cellHeights.count
		{
			let nextY = y + cellHeights[i]
			
			if nextY > centerY
			{
				return tableView.cellForRow(at: indexPaths[i])
			}
			
			y = nextY
		}
		
		print("ERROR: Couldn't find a cell that would contain y of \(centerY)")
		return nil
	}
}
