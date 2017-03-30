//
//  TranslationVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

// TranslationVC is the view controller used in the translation / review / work view
class TranslationVC: UIViewController, CellInputListener, AppStatusListener, TranslationCellManager, AddNotesDelegate, OpenThreadListener, UIGestureRecognizerDelegate
{
	// TYPES	----------
	
	typealias QueryTarget = ParagraphView
	
	
	// OUTLETS	----------
	
	@IBOutlet weak var commitButton: BasicButton!
	@IBOutlet weak var translationTableView: UITableView!
	@IBOutlet weak var resourceTableView: UITableView!
	@IBOutlet weak var resourceSegmentControl: UISegmentedControl!
	@IBOutlet weak var topUserView: TopUserView!
	
	
	// PROPERTIES	---------
	
	// Configurable data
	private var configured = false
	private var book: Book!
	
	// Target translation managing
	private let targetHistoryManager = TranslationHistoryManager()
	
	private var targetTranslationDS: TranslationTableViewDS!
	private var targetSwipeRecognizerLeft: UISwipeGestureRecognizer?
	private var targetSwipeRecognizerRight: UISwipeGestureRecognizer?
	
	// resource table managing
	private var resourceManager: ResourceManager!
	
	// Scroll management
	private var scrollManager: ScrollSyncManager!
	
	// paragraph data modified, but not committed by user
	// Key = paragraph path id, value = edited text
	private var inputData = [String : NSAttributedString]()
	
	// Open thread status
	// path id -> [ resource ids for each resource containing open threads for the path ]
	private var openThreadStatus = [String: [String]]()
	
	private var active = false
	
	
	// VIEW CONTROLLER	-----
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		print("STATUS: Translation VC loaded")
		
		guard configured else
		{
			fatalError("Translation VC must be configured before use")
		}
		
		commitButton.isEnabled = false
		
		// (Epic hack which) Makes table view cells have automatic height
		translationTableView.rowHeight = UITableViewAutomaticDimension
		translationTableView.estimatedRowHeight = 320
		
		resourceTableView.rowHeight = UITableViewAutomaticDimension
		resourceTableView.estimatedRowHeight = 320
		
		targetTranslationDS = TranslationTableViewDS(tableView: translationTableView, cellReuseId: "TranslationCell", bookId: book.idString)
		targetTranslationDS.cellManager = self
		translationTableView.dataSource = targetTranslationDS
		
		resourceManager = ResourceManager(resourceTableView: resourceTableView, addNotesDelegate: self, threadStatusListener: self)
		
		// Sets initial resources (TEST)
		let sourceLanguage = try! LanguageView.instance.language(withName: "English")
		if let sourceBook = try! ProjectBooksView.instance.booksQuery(languageId: sourceLanguage.idString, projectId: book.projectId, code: book.code).firstResultObject(), let binding = try! ParagraphBindingView.instance.latestBinding(from: sourceBook.idString, to: book.idString)
		{
			// TODO: Use a better query (more languages, etc.) (catch errors too)
			let notesResources = try! ResourceCollectionView.instance.collectionQuery(bookId: book.idString, languageId: book.languageId, category: .notes).resultObjects()
			resourceManager.setResources(sourceBooks: [(sourceBook, binding)], notes: notesResources)
		}
		
		// Makes resource manager listen to paragraph content changes
		targetTranslationDS.contentListener = resourceManager
		
		resourceSegmentControl.removeAllSegments()
		let resourceTitles = resourceManager.resourceTitles
		for i in 0 ..< resourceTitles.count
		{
			resourceSegmentControl.insertSegment(withTitle: resourceTitles[i], at: i, animated: false)
		}
		if !resourceTitles.isEmpty
		{
			resourceSegmentControl.selectedSegmentIndex = 0
		}
		
		// Sets scroll syncing
		scrollManager = ScrollSyncManager(leftTable: resourceTableView, rightTable: translationTableView, leftResourceId: resourceTitles.isEmpty ? "none" : resourceTitles.first!, rightResourceId: "target")
		{
			tableView, oppositePathId in
			
			if tableView === self.resourceTableView
			{
				return self.resourceManager.indexPathsForTargetPathId(oppositePathId)
			}
			else
			{
				return self.resourceManager.targetPathsForSourcePath(oppositePathId).flatMap { self.targetTranslationDS.indexForPath($0) }
			}
		}
		
		// Sets selection listening
		scrollManager.registerSelectionListener(resourceManager)
		
		// Adds swipe listening
		if targetSwipeRecognizerLeft == nil
		{
			targetSwipeRecognizerLeft = UISwipeGestureRecognizer(target: self, action: #selector(targetTableSwiped(recognizer:)))
			targetSwipeRecognizerLeft?.direction = .left
			translationTableView.addGestureRecognizer(targetSwipeRecognizerLeft!)
			targetSwipeRecognizerLeft?.delegate = self
		}
		if targetSwipeRecognizerRight == nil
		{
			
			targetSwipeRecognizerRight = UISwipeGestureRecognizer(target: self, action: #selector(targetTableSwiped(recognizer:)))
			targetSwipeRecognizerRight?.direction = .right
			translationTableView.addGestureRecognizer(targetSwipeRecognizerRight!)
			targetSwipeRecognizerRight?.delegate = self
		}
		
		// Sets up top user view
		if let avatarId = Session.instance.avatarId
		{
			do
			{
				if let avatarInfo = try AvatarInfo.get(avatarId: avatarId)
				{
					topUserView.configure(userName: try avatarInfo.displayName(), userIcon: avatarInfo.image.or(#imageLiteral(resourceName: "userIcon")))
				}
				else
				{
					print("ERROR: Couldn't find avatar information for id: \(avatarId)")
				}
			}
			catch
			{
				print("ERROR: Couldn't read avatar information. \(error)")
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
		commitButton.isEnabled = true
		
		// Resets cell height
		UIView.setAnimationsEnabled(false)
		translationTableView.beginUpdates()
		translationTableView.endUpdates()
		UIView.setAnimationsEnabled(true)
	}
	
	func insertThread(noteId: String, pathId: String, associatedParagraphData: [(String, Paragraph)])
	{
		guard let avatarId = Session.instance.avatarId else
		{
			print("ERROR: Cannot insert a thread without avatar selected")
			return
		}
		
		displayAlert(withIdentifier: "PostThread")
		{
			// Finds the targeted paragraph
			guard let targetParagraph = self.targetTranslationDS.paragraphForPath(pathId) else
			{
				print("ERROR: No target paragraph for post thread")
				return
			}
			
			($0 as! PostThreadVC).configure(userId: avatarId, noteId: noteId, targetParagraph: targetParagraph, contextParagraphData: associatedParagraphData)
		}
	}
	
	func insertPost(thread: NotesThread, selectedComment originalComment: NotesPost, associatedParagraphData: [(String, Paragraph)])
	{
		displayAlert(withIdentifier: "AddPost")
		{
			($0 as! PostCommentVC).configure(thread: thread, selectedComment: originalComment, associatedParagraphData: associatedParagraphData)
		}
	}
	
	
	// CELL MANAGEMENT	-------------
	
	func overrideContentForParagraph(_ paragraph: Paragraph) -> NSAttributedString?
	{
		// Checks if history is used
		if let history = targetHistoryManager.currentHistoryForParagraph(withId: paragraph.idString)
		{
			return history.toAttributedString(options: [Paragraph.optionDisplayParagraphRange: false])
		}
		else
		{
			return inputData[paragraph.pathId]
		}
	}
	
	func cellUpdated(_ cell: TranslationCell, paragraph: Paragraph)
	{
		if let cell = cell as? TargetTranslationCell
		{
			// Finds the first viable index of a resource that contains an open thread for this paragraph cell
			var noteResourceIndex: Int? = nil
			if let openResourceIds = cell.pathId.flatMap({ self.openThreadStatus[$0] })
			{
				for resourceId in openResourceIds
				{
					if let resourceIndex = resourceManager.indexForResource(withId: resourceId)
					{
						noteResourceIndex = resourceIndex
						break
					}
				}
			}
			
			cell.configure(showsHistory: targetHistoryManager.currentDepthForParagraph(withId: paragraph.idString) != 0, inputListener: self, scrollManager: scrollManager, withNotesAtIndex: noteResourceIndex, openResource: switchToResource)
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
	
	
	// OTHER IMPLEMENTED	---------
	
	func configure(book: Book)
	{
		self.book = book
		configured = true
	}
	
	func onThreadStatusUpdated(forResouceId resourceId: String, status: [String : Bool])
	{
		// Updates the open thread status for each path
		for (pathId, isOpen) in status
		{
			if let currentStatus = openThreadStatus[pathId]
			{
				if isOpen
				{
					if !currentStatus.contains(resourceId)
					{
						openThreadStatus[pathId] = currentStatus + resourceId
					}
				}
				else
				{
					if currentStatus.contains(resourceId)
					{
						openThreadStatus[pathId] = currentStatus - resourceId
					}
				}
			}
			else
			{
				// Adds new elements where necessary
				openThreadStatus[pathId] = isOpen ? [resourceId] : []
			}
		}
		
		translationTableView.reloadData()
	}
	
	
	// IB ACTIONS	-----------------
	
	@IBAction func backButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func commitPressed(_ sender: Any)
	{
		// Makes a new commit
		commit()
	}
	
	@IBAction func resouceSegmentChanged(_ sender: Any)
	{
		switchToResource(atIndex: resourceSegmentControl.selectedSegmentIndex)
	}
	
	func targetTableSwiped(recognizer: UISwipeGestureRecognizer)
	{
		// First finds the targeted cell
		guard let index = translationTableView.indexPathForRow(at: recognizer.location(in: translationTableView)) else
		{
			print("ERROR: Could not find swipe target cell")
			return
		}
		
		guard let paragraph = targetTranslationDS?.paragraphAtIndex(index) else
		{
			print("ERROR: Could not find swipe target paragraph")
			return
		}
		
		var changed = false
		do
		{
			// Depending on the swipe direction, the history either goes forward or backward
			if recognizer.direction == .right
			{
				changed = try targetHistoryManager.goToPreviousVersionOfParagraph(withId: paragraph.idString)
			}
			else if recognizer.direction == .left
			{
				changed = targetHistoryManager.goToNextVersionOfParagraph(withId: paragraph.idString)
			}
		}
		catch
		{
			print("ERROR: Failed to modify history. \(error)")
		}
		
		if changed
		{
			translationTableView.reloadRows(at: [index], with: recognizer.direction == .left ? .left : .right)
		}
	}
	
	
	// OTHER	---------------------
	
	private func switchToResource(atIndex index: Int)
	{
		resourceSegmentControl.selectedSegmentIndex = index
		resourceManager.selectResource(atIndex: index)
		if let newTitle = resourceSegmentControl.titleForSegment(at: index)
		{
			print("STATUS: Switching to \(newTitle)")
			scrollManager.leftResourceId = newTitle
		}
		scrollManager.syncScrollToRight()
	}
	
	private func displayAlert(withIdentifier alertId: String, using configurer: (UIViewController) -> ())
	{
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let myAlert = storyboard.instantiateViewController(withIdentifier: alertId)
		myAlert.modalPresentationStyle = .overCurrentContext
		myAlert.modalTransitionStyle = .crossDissolve
		
		configurer(myAlert)
		
		print("STATUS: Presenting view with id \(alertId)")
		present(myAlert, animated: true, completion: nil)
	}
	
	private func commit()
	{
		guard !inputData.isEmpty else
		{
			return
		}
		
		guard let avatarId = Session.instance.avatarId else
		{
			print("ERROR: Cannot commit without avatar selected")
			return
		}
		
		print("STATUS: STARTING COMMIT")
		commitButton.isEnabled = false
		
		DATABASE.inTransaction
		{
			do
			{
				// Saves each user input as a commit
				for (pathId, text) in self.inputData
				{
					if let paragraph = self.targetTranslationDS?.paragraphForPath(pathId)
					{
						_ = try paragraph.commit(userId: avatarId, text: text)
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
		guard !active else
		{
			return
		}
		
		do
		{
			print("STATUS: ACTIVATING")
			active = true
			
			// Retrieves edit data from the database
			// TODO: rework after user data and book data are in place
			if inputData.isEmpty
			{
				guard let avatarId = Session.instance.avatarId else
				{
					print("ERROR: Cannot save edits without avatar selected")
					return
				}
				
				let paragraphEdits = try ParagraphEditView.instance.editsForRangeQuery(bookId: book.idString, userId: avatarId).resultObjects()
				
				print("STATUS: FOUND \(paragraphEdits.count) edits")
				
				for edit in paragraphEdits
				{
					for paragraph in edit.edits.values
					{
						inputData[paragraph.pathId] = paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false])
					}
				}
				
				commitButton.isEnabled = !inputData.isEmpty
			}
			
			// Starts the database listening process, if not yet started
			targetTranslationDS?.activate()
			resourceManager.activate()
		}
		catch
		{
			print("ERROR: Failed to read edit data. \(error)")
		}
	}
	
	private func deactivate()
	{
		guard active else
		{
			return
		}
		
		print("STATUS: DEACTIVATING")
		active = false
		
		// Ends the database listening process, if present
		targetTranslationDS?.pause()
		resourceManager.pause()
		
		guard let avatarId = Session.instance.avatarId else
		{
			print("ERROR: Cannot save edits without avatar selected")
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
				let previousEdits = try ParagraphEditView.instance.editsForRangeQuery(bookId: self.book.idString).resultObjects()
				
				// Inserts new data to the database
				var insertedIds = [String]()
				for (chapterIndex, paragraphs) in chapterData
				{
					var edits = [String : Paragraph]()
					for paragraph in paragraphs
					{
						edits[paragraph.idString] = paragraph
					}
					
					let edit = ParagraphEdit(bookId: self.book.idString, chapterIndex: chapterIndex, userId: avatarId, edits: edits)
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
