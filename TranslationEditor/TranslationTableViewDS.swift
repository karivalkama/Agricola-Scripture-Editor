//
//  TranslationTableViewDS.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class handles data management for a single table view containing translation cell data
class TranslationTableViewDS: NSObject, UITableViewDataSource, LiveQueryListener
{
	// TYPES	---------------------
	
	typealias QueryTarget = ParagraphView
	
	
	// ATTRIBUTES	-----------------
	
	private weak var tableView: UITableView!
	
	// Path id -> Current Data index
	private var pathIndex = [String : Int]()
	private var queryManager: LiveQueryManager<ParagraphView>
	
	private(set) var currentData = [Paragraph]()
	
	let cellReuseId: String
	
	// The instance that manages content change listening and overwrites content when necessary
	var cellManager: TranslationCellManager?
	
	
	// INIT	-------------------------
	
	// TODO: Change book id to translation range
	// Activation must be called separately
	init(tableView: UITableView, cellReuseId: String, bookId: String)
	{
		self.tableView = tableView
		self.cellReuseId = cellReuseId
		
		let query = ParagraphView.instance.latestParagraphQuery(bookId: bookId)
		self.queryManager = query.liveQueryManager
		
		super.init()
		
		self.queryManager.addListener(AnyLiveQueryListener(self))
	}
	
	
	// IMPLEMENTED METHODS	---------
	
	func rowsUpdated(rows: [Row<ParagraphView>])
	{
		// Updates paragraph data
		// TODO: Check for conflicts. Make safer
		currentData = rows.map { try! $0.object() }
		// Updates the path index too
		pathIndex = [:]
		for i in 0 ..< currentData.count
		{
			pathIndex[currentData[i].pathId] = i
		}
		
		print("STATUS: Paragraph data updated (\(rows.count) rows)")
		
		tableView.reloadData()
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return currentData.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		// Finds a reusable cell
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath) as! TranslationCell
		
		// Updates cell content (either from current data or from current input status)
		let paragraph = currentData[indexPath.row]
		
		var stringContents: NSAttributedString!
		if let input = cellManager?.overrideContentForPath(paragraph.pathId)
		{
			stringContents = input
			print("STATUS: Presenting input data")
		}
		else
		{
			stringContents = paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false])
		}
		
		cell.setContent(stringContents, withId: paragraph.pathId)
		cellManager?.cellUpdated(cell)
		return cell
	}
	
	
	// OTHER METHODS	----------
	
	// Activates the live querying and makes this the active data source for the table view
	func activate()
	{
		tableView.dataSource = self
		queryManager.start()
		
		print("STATUS: Paragraph data retrieval started")
	}
	
	// Temporarily pauses the live querying
	func pause()
	{
		queryManager.pause()
	}
	
	func paragraphForPath(_ pathId: String) -> Paragraph?
	{
		if let index = pathIndex[pathId]
		{
			return currentData[index]
		}
		else
		{
			return nil
		}
	}
	
	func indexForPath(_ pathId: String) -> IndexPath?
	{
		if let index = pathIndex[pathId]
		{
			return IndexPath(row: index, section: 0)
		}
		else
		{
			return nil
		}
	}
}
