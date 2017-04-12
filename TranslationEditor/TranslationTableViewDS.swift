//
//  TranslationTableViewDS.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class handles data management for a single table view containing translation cell data
class TranslationTableViewDS: NSObject, UITableViewDataSource, LiveQueryListener, LiveResource
{
	// TYPES	---------------------
	
	typealias QueryTarget = ParagraphView
	
	
	// ATTRIBUTES	-----------------
	
	private weak var tableView: UITableView!
	
	// Path id -> Current Data index
	private var pathIndex = [String : Int]()
	private var queryManager: LiveQueryManager<QueryTarget>
	
	private(set) var currentData = [Paragraph]()
	
	// Content listener is informed whenever the table contents have been updated
	var contentListener: TranslationParagraphListener?
	
	private let configureCell: (UITableView, IndexPath, Paragraph) -> UITableViewCell
	private let prepareUpdate: (() -> ())?
	
	
	// INIT	-------------------------
	
	// TODO: Change book id to translation range
	// Activation must be called separately
	init(tableView: UITableView, bookId: String, configureCell: @escaping (UITableView, IndexPath, Paragraph) -> UITableViewCell, prepareUpdate: (() -> ())? = nil)
	{
		self.tableView = tableView
		self.configureCell = configureCell
		self.prepareUpdate = prepareUpdate
		
		let query = ParagraphView.instance.latestParagraphQuery(bookId: bookId)
		self.queryManager = query.liveQueryManager
		
		super.init()
		
		self.queryManager.addListener(AnyLiveQueryListener(self))
	}
	
	
	// IMPLEMENTED METHODS	---------
	
	func rowsUpdated(rows: [Row<ParagraphView>])
	{
		// Updates paragraph data
		currentData = rows.flatMap { try? $0.object() }
		
		// Updates the path index too
		pathIndex = [:]
		for i in 0 ..< currentData.count
		{
			pathIndex[currentData[i].pathId] = i
		}
		
		prepareUpdate?()
		tableView.reloadData()
		
		contentListener?.translationParagraphsUpdated(currentData)
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return currentData.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		// Updates cell content (either from current data or from current input status)
		let paragraph = currentData[indexPath.row]
		return configureCell(tableView, indexPath, paragraph)
		
		/*
		var stringContents: NSAttributedString!
		if let input = cellManager?.overrideContentForParagraph(paragraph)
		{
			stringContents = input
			print("STATUS: Presenting input data")
		}
		else
		{
			stringContents = paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false])
		}
		
		cell.setContent(stringContents, withId: paragraph.pathId)
		cellManager?.cellUpdated(cell, paragraph: paragraph)
		return cell
		*/
	}
	
	
	// OTHER METHODS	----------
	
	// Activates the live querying and makes this the active data source for the table view
	func activate()
	{
		//tableView.dataSource = self
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
	
	// Finds the paragraph displayed at certain index path (row)
	func paragraphAtIndex(_ index: IndexPath) -> Paragraph?
	{
		if index.row < 0 || index.row >= currentData.count
		{
			return nil
		}
		else
		{
			return currentData[index.row]
		}
	}
}
