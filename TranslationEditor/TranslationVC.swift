//
//  TranslationVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

// TranslationVC is the view controller used in the translation / review / work view
class TranslationVC: UIViewController, CellInputListener, AppStatusListener, TranslationCellManager
{
	// TYPES	----------
	
	typealias QueryTarget = ParagraphView
	
	
	// OUTLETS	----------
	
	@IBOutlet weak var translationTableView: UITableView!
	@IBOutlet weak var resourceTableView: UITableView!
	
	
	// PROPERTIES	---------
	
	// Testing data
	private var book: Book?
	private let userId = "testuserid"
	
	// Target translation managing
	private var targetTranslationDS: TranslationTableViewDS?
	
	// Source translation managing
	private var sourceTranslationDS: TranslationTableViewDS?
	
	// Table binding
	private var binding: ParagraphBinding?
	private var scrollManager: ScrollSyncManager?
	
	// paragraph data modified, but not committed by user
	// Key = paragraph path id, value = edited text
	private var inputData = [String : NSAttributedString]()
	
	private var active = false
	
	
	// VIEW CONTROLLER	-----
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		// (Epic hack which) Makes table view cells have automatic height
		translationTableView.rowHeight = UITableViewAutomaticDimension
		translationTableView.estimatedRowHeight = 160
		
		resourceTableView.rowHeight = UITableViewAutomaticDimension
		resourceTableView.estimatedRowHeight = 160
		
		// TODO: Use certain ranges, which should be changeable
		// Reads necessary data (TEST)
		let language = try! LanguageView.instance.language(withName: "Finnish")
		if let book = try! BookView.instance.booksQuery(languageId: language.idString, code: "gal").firstResultObject()
		{
			self.book = book
			
			targetTranslationDS = TranslationTableViewDS(tableView: translationTableView, cellReuseId: "TranslationCell", bookId: book.idString)
			targetTranslationDS?.cellManager = self
		}
		
		let sourceLanguage = try! LanguageView.instance.language(withName: "English")
		if let sourceBook = try! BookView.instance.booksQuery(languageId: sourceLanguage.idString, code: "gal").firstResultObject()
		{
			sourceTranslationDS = TranslationTableViewDS(tableView: resourceTableView, cellReuseId: "sourceCell", bookId: sourceBook.idString)
			
			// Sets up scroll management
			if let book = book, let binding = try? ParagraphBindingView.instance.latestBinding(from: sourceBook.idString, to: book.idString)
			{
				self.binding = binding
				
				self.scrollManager = ScrollSyncManager(resourceTableView, translationTableView)
				{
					tableView, pathId in
					
					if tableView === self.resourceTableView
					{
						print("STATUS: FINDING PATH ID FROM RESOURCE TABLE")
						
						if let sourcePathId = self.binding?.sourcePath(forPath: pathId)
						{
							return self.sourceTranslationDS?.indexForPath(sourcePathId)
						}
						else
						{
							return nil
						}
					}
					else
					{
						print("STATUS: FINDING PATH ID FROM TARGET TABLE")
						
						if let targetPathId = self.binding?.targetPath(forPath: pathId)
						{
							return self.targetTranslationDS?.indexForPath(targetPathId)
						}
						else
						{
							return nil
						}
					}
				}
			}
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

	/*
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		
		// Dispose of any resources that can be recreated.
	}*/
	
	
	// CELL LISTENING	-------------
	
	func cellContentChanged(id: String, newContent: NSAttributedString)
	{
		inputData[id] = newContent
		
		// Resets cell height
		translationTableView.beginUpdates()
		translationTableView.endUpdates()
	}
	
	
	// CELL MANAGEMENT	-------------
	
	func overrideContentForPath(_ pathId: String) -> NSAttributedString?
	{
		return inputData[pathId]
	}
	
	func cellUpdated(_ cell: TranslationCell)
	{
		if let cell = cell as? TargetTranslationCell
		{
			cell.inputListener = self
		}
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
	
	
	// IB ACTIONS	-----------------
	
	@IBAction func commitPressed(_ sender: Any)
	{
		// Makes a new commit
		commit()
	}
	
	
	// OTHER	---------------------
	
	private func commit()
	{
		guard !inputData.isEmpty else
		{
			return
		}
		
		print("STATUS: STARTING COMMIT")
		
		DATABASE.inTransaction
		{
			do
			{
				// Saves each user input as a commit
				for (pathId, text) in self.inputData
				{
					if let paragraph = self.targetTranslationDS?.paragraphForPath(pathId)
					{
						_ = try paragraph.commit(userId: self.userId, text: text)
					}
				}
				
				// Clears the input afterwards
				self.inputData = [:]
				
				print("STATUS: COMMIT COMPLETE")
				
				return true
			}
			catch
			{
				// TODO: Create better error handling
				print("STATUS: ERROR WHILE COMMITTING \(error)")
				return false
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
					print("STATUS: Edit status: \(edit.idString), \(edit.toPropertySet)")
					
					for paragraph in edit.edits.values
					{
						print("Updating input for paragraph \(paragraph.pathId)")
						inputData[paragraph.pathId] = paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false])
					}
				}
				
				print("There are now \(inputData.count) inputs")
			}
			
			// Starts the database listening process, if not yet started
			targetTranslationDS?.activate()
			sourceTranslationDS?.activate()
		}
	}
	
	private func deactivate()
	{
		if active
		{
			print("STATUS: DEACTIVATING")
			active = false
			
			// Ends the database listening process, if present
			targetTranslationDS?.pause()
			sourceTranslationDS?.pause()
			
			// TODO: Test. modify later
			guard let book = book else
			{
				return
			}
			
			// Parses the input data into paragraphs, grouped by chapter index
			var chapterData = [Int : [Paragraph]]()
			for (pathId, inputText) in self.inputData
			{
				if let paragraphCopy = targetTranslationDS?.paragraphForPath(pathId)?.copy()
				{
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
