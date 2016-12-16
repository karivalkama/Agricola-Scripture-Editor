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
	// Key = paragraph id
	private var inputData = [String : EditState]()
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
		if let inputState = inputData[paragraph.idString]
		{
			stringContents = inputState.text
			// TODO: Set cell state to conflicted if necessary
		}
		else
		{
			stringContents = paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false])
		}
		
		cell.setContent(to: stringContents, withId: paragraph.idString)
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
			print("STATUS: UPDATES ROWS")
			translationTableView.reloadData()
		}
	}
	
	
	// CELL LISTENING	-------------
	
	func cellContentChanged(id: String, newContent: NSAttributedString)
	{
		let wasConflict = (inputData[id]?.isConflict).or(false)
		inputData[id] = EditState(text: newContent, isConflict: wasConflict)
		
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
		for (paragraphId, editState) in inputData
		{
			if let paragraph = try Paragraph.get(paragraphId)
			{
				// TODO: Prompt the user to handle edit conflicts
				// Makes changes to the actual paragraphs (where edited)
				paragraph.replaceContents(with: editState.text)
				try paragraph.push()
				
				// And saves new commits
				// TODO: Change paragraph model structure to use versioning instead of mutable instances
			}
		}
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
					print("STATUS: '\(edit.paragraph.text)'")
					
					inputData[edit.targetId] = EditState(text: edit.paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false]), isConflict: edit.isConflict)
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
			
			// Saves paragraph edit status to the database
			do
			{
				// Deletes previous data
				let paragraphEdits = try! getParagraphEdits()
				paragraphEdits.forEach { try? $0.delete() }
				
				for (paragraphId, editState) in inputData
				{
					if let paragraph = try Paragraph.get(paragraphId)
					{
						print("STATUS: SAVING PARAGRAPH EDIT")
						
						paragraph.replaceContents(with: editState.text)
						
						let edit = ParagraphEdit(userId: userId, paragraph: paragraph, isConflict: editState.isConflict)
						
						print("STATUS: SAVED EDIT: \(edit.toPropertySet)")
						
						try edit.push()
						
						print("STATUS: NEW EDIT WITH ID: " + edit.idString)
					}
				}
			}
			catch
			{
				// TODO: Add better error handling
				print("DB: Failed to save edit status \(error)")
			}
		}
	}
	
	private func getParagraphEdits() throws -> [ParagraphEdit]
	{
		guard let book = book else { return [] }
		return try ParagraphEditView.instance.editsForRangeQuery(userId: userId, bookId: book.idString).resultObjects()
	}
}
