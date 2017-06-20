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
	
	private weak var stateView: StatefulStackView?
	private weak var tableView: UITableView!
	
	private var isLoaded = false
	
	// Path id -> Chapter index + index in current data array
	private var pathIndex = [String : (chapterIndex: Int, index: Int)]()
	private var queryManager: LiveQueryManager<QueryTarget>
	
	// Chapter index -> Paragraphs per chapter
	private var currentData = [Int: [Paragraph]]()
	
	// Content listener is informed whenever the table contents have been updated
	private var _contentListeners = [Weak<TranslationParagraphListener>]()
	var contentListeners: [TranslationParagraphListener]
	{
		get { return _contentListeners.flatMap { $0.value } }
		set { _contentListeners = newValue.weakReference }
	}
	
	private let configureCell: (UITableView, IndexPath, Paragraph) -> UITableViewCell
	private let prepareUpdate: (() -> ())?
	
	
	// INIT	-------------------------
	
	// TODO: Change book id to translation range
	// Activation must be called separately
	init(tableView: UITableView, bookId: String, stateView: StatefulStackView? = nil, configureCell: @escaping (UITableView, IndexPath, Paragraph) -> UITableViewCell, prepareUpdate: (() -> ())? = nil)
	{
		self.stateView = stateView
		self.tableView = tableView
		self.configureCell = configureCell
		self.prepareUpdate = prepareUpdate
		
		let query = ParagraphView.instance.latestParagraphQuery(bookId: bookId)
		self.queryManager = query.liveQueryManager
		
		tableView.register(UINib(nibName: "ChapterHeaderCell", bundle: nil), forCellReuseIdentifier: ChapterHeaderCell.identifier)
		
		super.init()
		
		self.queryManager.addListener(AnyLiveQueryListener(self))
	}
	
	
	// IMPLEMENTED METHODS	---------
	
	func rowsUpdated(rows: [Row<ParagraphView>])
	{
		// Updates paragraph data
		let paragraphs = rows.flatMap { try? $0.object() }
		
		currentData = paragraphs.toArrayDictionary { ($0.chapterIndex, $0) }
		
		// Updates the path index too
		pathIndex = [:]
		for (chapterIndex, paragraphs) in currentData
		{
			for i in 0 ..< paragraphs.count
			{
				pathIndex[paragraphs[i].pathId] = (chapterIndex: chapterIndex, index: i)
			}
		}
		
		// Updates the state view, if possible
		isLoaded = true
		stateView?.dataLoaded(isEmpty: paragraphs.isEmpty)
		
		prepareUpdate?()
		tableView.reloadData()
		
		contentListeners.forEach { $0.translationParagraphsUpdated(paragraphs) }
	}
	
	func numberOfSections(in tableView: UITableView) -> Int
	{
		return currentData.keys.max() ?? 0
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return currentData[section + 1]?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		// Updates cell content (either from current data or from current input status)
		let paragraph = currentData[indexPath.section + 1]![indexPath.row]
		return configureCell(tableView, indexPath, paragraph)
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		return "\(NSLocalizedString("Chapter", comment: "A section header in translation table. Followed by the chapter number.")) \(section + 1)"
	}
	
	func sectionIndexTitles(for tableView: UITableView) -> [String]?
	{
		return Array(currentData.keys).sorted().map { "\($0)" }
	}
	
	func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
	{
		return Int(title)! - 1
	}
	
	
	// OTHER METHODS	----------
	
	// Activates the live querying and makes this the active data source for the table view
	func activate()
	{
		if !isLoaded
		{
			stateView?.setState(.loading)
		}
		
		queryManager.start()
	}
	
	// Temporarily pauses the live querying
	func pause()
	{
		queryManager.pause()
		
		if !isLoaded
		{
			stateView?.setState(.empty)
		}
	}
	
	func paragraphForPath(_ pathId: String) -> Paragraph?
	{
		if let (chapterIndex, index) = pathIndex[pathId]
		{
			return currentData[chapterIndex]![index]
		}
		else
		{
			return nil
		}
	}
	
	func indexForPath(_ pathId: String) -> IndexPath?
	{
		if let (chapterIndex, index) = pathIndex[pathId]
		{
			return IndexPath(row: index, section: chapterIndex - 1)
		}
		else
		{
			return nil
		}
	}
	
	// Finds the paragraph displayed at certain index path
	func paragraphAtIndex(_ index: IndexPath) -> Paragraph?
	{
		guard let chapterParagraphs = currentData[index.section + 1] else
		{
			return nil
		}
		
		if index.row < 0 || index.row >= chapterParagraphs.count
		{
			return nil
		}
		else
		{
			return chapterParagraphs[index.row]
		}
	}
}
