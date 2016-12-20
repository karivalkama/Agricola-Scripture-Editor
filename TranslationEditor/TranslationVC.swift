//
//  TranslationVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

// TranslationVC is the view controller used in the translation / review / work view
class TranslationVC: UIViewController, UITableViewDataSource, LiveQueryListener, CellInputListener, AppStatusListener
{
	// TYPES	----------
	
	typealias QueryTarget = ParagraphView
	
	
	// OUTLETS	----------
	
	@IBOutlet weak var translationTableView: UITableView!
	
	
	// PROPERTIES	---------
	
	// Testing data
	private var book: Book?
	private let userId = "testuserid"
	
	// Current paragraph status in database
	private var currentData = [Paragraph]()
	
	// paragraph data modified, but not committed by user
	// Key = paragraph path id, value = edited text
	private var inputData = [String : NSAttributedString]()
	// Key = path id, value = corresponding index in current paragraph data
	private var pathIndex = [String : Int]()
	private var active = false
	
	// The live query used for retrieving translation data
	private var translationQueryManager: LiveQueryManager<ParagraphView>?
	
	private var committing = false
	
	
	// VIEW CONTROLLER	-----
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		// (Epic hack which) Makes table view cells have automatic height
		translationTableView.rowHeight = UITableViewAutomaticDimension
		translationTableView.estimatedRowHeight = 160
		
		//translationTableView.delegate = self
		translationTableView.dataSource = self
		
		// TODO: Use certain ranges, which should be changeable
		// Reads necessary data (TEST)
		
		let language = try! LanguageView.instance.language(withName: "English")
		if let book = try! BookView.instance.booksQuery(languageId: language.idString, code: "GAL", identifier: nil).firstResultObject()
		{
			self.book = book
			let query = ParagraphView.instance.latestParagraphQuery(bookId: book.idString)
			translationQueryManager = query.liveQueryManager
			translationQueryManager!.addListener(AnyLiveQueryListener(self))
		}

	}
	
	override func viewDidAppear(_ animated: Bool)
	{
		AppStatusHandler.instance.registerListener(self)
		activate()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		AppStatusHandler.instance.removeListener(self)
		deactivate()
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		
		// Dispose of any resources that can be recreated.
	}
	
	
	// TABLE VIEW DATASOURCE	------
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return currentData.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		// Finds a reusable cell
		let cell = translationTableView.dequeueReusableCell(withIdentifier: "TranslationCell", for: indexPath) as! TranslationCell
		
		// Updates cell content (either from current data or from current input status)
		let paragraph = currentData[indexPath.row]
		
		var stringContents: NSAttributedString!
		if let input = inputData[paragraph.pathId]
		{
			stringContents = input
		}
		else
		{
			stringContents = paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false])
		}
		
		cell.setContent(to: stringContents, withId: paragraph.pathId)
		cell.inputListener = self
		return cell
	}
	
	
	// QUERY LISTENING	-------------
	
	func rowsUpdated(rows: [Row<ParagraphView>])
	{
		// Updates paragraph data (unless committing is in progress)
		if !committing
		{
			// TODO: Check for conflicts. Make safer
			currentData = rows.map { try! $0.object() }
			// Updates the path index too
			pathIndex = [:]
			for i in 0 ..< currentData.count
			{
				pathIndex[currentData[i].pathId] = i
			}
			
			print("STATUS: UPDATES ROWS")
			translationTableView.reloadData()
		}
	}
	
	
	// CELL LISTENING	-------------
	
	func cellContentChanged(id: String, newContent: NSAttributedString)
	{
		inputData[id] = newContent
		
		// Resets cell height
		translationTableView.beginUpdates()
		translationTableView.endUpdates()
	}
	
	
	// APP STATUS LISTENING	---------
	
	func appWillClose()
	{
		deactivate()
	}
	
	func appWillContinue()
	{
		activate()
	}
	
	
	// OTHER	---------------------
	
	private func commit() throws
	{
		/*
		for (paragraphId, editState) in inputData
		{
			if let paragraph = try Paragraph.get(paragraphId)
			{
				// TODO: Prompt the user to handle edit conflicts
				// Makes changes to the actual paragraphs (where edited)
				//paragraph.replaceContents(with: editState.text)
				//try paragraph.push()
				
				// And saves new commits
				// TODO: Change paragraph model structure to use versioning instead of mutable instances
			}
		}*/
	}
	
	private func activate()
	{
		if !active
		{
			print("STATUS: ACTIVATING")
			active = true
			
			// Retrieves edit data from the database
			// TODO: rework after user data and book data are in place
			if inputData.isEmpty
			{
				let paragraphEdits = try! getParagraphEdits()
				
				print("STATUS: FOUND \(paragraphEdits.count) edits")
				
				for edit in paragraphEdits
				{
					for paragraph in edit.edits.values
					{
						inputData[paragraph.pathId] = paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false])
					}
				}
			}
			
			// Starts the database listening process, if not yet started
			translationQueryManager?.start()
		}
	}
	
	private func deactivate()
	{
		if active
		{
			print("STATUS: DEACTIVATING")
			active = false
			
			// Ends the database listening process, if present
			translationQueryManager?.stop()
			
			// TODO: Test. modify later
			guard let book = book else
			{
				return
			}
			
			// Parses the input data into paragraphs, grouped by chapter index
			var chapterData = [Int : [Paragraph]]()
			for (pathId, inputText) in self.inputData
			{
				if let index = self.pathIndex[pathId]
				{
					let paragraphCopy = self.currentData[index].copy()
					paragraphCopy.replaceContents(with: inputText)
					
					let chapterIndex = paragraphCopy.chapterIndex
					chapterData[chapterIndex] = chapterData[chapterIndex].or([]) + paragraphCopy
				}
			}
			
			// Saves paragraph edit status to the database
			DATABASE.inTransaction
			{
				do
				{
					// Finds existing edit data
					let previousEdits = try ParagraphEditView.instance.editsForRangeQuery(bookId: book.idString).resultObjects()
					
					// Inserts new data to the database
					var insertedIds = [String]()
					for (chapterIndex, paragraphs) in chapterData
					{
						var edits = [String : Paragraph]()
						for paragraph in paragraphs
						{
							edits[paragraph.idString] = paragraph
						}
						
						let edit = ParagraphEdit(bookId: book.idString, chapterIndex: chapterIndex, userId: self.userId, edits: edits)
						try edit.push(overwrite: true)
						insertedIds.append(edit.idString)
						
						print("STATUS: SAVING EDIT \(edit.idString)")
					}
					
					// Removes the old data that wasn't overwritten
					try previousEdits.filter { !insertedIds.contains($0.idString) }.forEach { try $0.delete() }
					
					return true
				}
				catch
				{
					print("DB: Failed to save edit status \(error)")
					return false
				}
			}
		}
	}
	
	private func getParagraphEdits() throws -> [ParagraphEdit]
	{
		guard let book = book else { return [] }
		return try ParagraphEditView.instance.editsForRangeQuery(bookId: book.idString, userId: userId).resultObjects()
	}
}
