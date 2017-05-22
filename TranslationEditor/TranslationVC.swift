//
//  TranslationVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

// TranslationVC is the view controller used in the translation / review / work view
class TranslationVC: UIViewController, CellInputListener, AppStatusListener, AddNotesDelegate, OpenThreadListener, UIGestureRecognizerDelegate, TranslationCellDelegate, ResourceUpdateListener, TranslationParagraphListener
{
	// TYPES	----------
	
	typealias QueryTarget = ParagraphView
	
	
	// OUTLETS	----------
	
	@IBOutlet weak var commitButton: BasicButton!
	@IBOutlet weak var translationTableView: UITableView!
	@IBOutlet weak var resourceTableView: UITableView!
	@IBOutlet weak var resourceSegmentControl: UISegmentedControl!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var topBar: TopBarUIView!
	
	
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
	// Key = paragraph path id, value = original paragraph + edited text
	private var inputData = [String : (Paragraph, NSAttributedString)]()
	
	// Open thread status
	// path id -> [ resource ids for each resource containing open threads for the path ]
	private var openThreadStatus = [String: [String]]()
	// The conflicting paragraphs for each path id
	// path id -> paragraph ids
	private var conflictStatus = [String: [String]]()
	
	private var active = false
	
	// Tracking of edit (cursor) status
	private var lastEditPath: String?
	private var lastEditRange: NSRange?
	
	
	// VIEW CONTROLLER	-----
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		print("STATUS: Translation VC loaded")
		
		guard configured else
		{
			fatalError("Translation VC must be configured before use")
		}
		
		topBar.configure(hostVC: self, title: "Translation", leftButtonText: "To Main Menu")
		{
			Session.instance.bookId = nil
			self.dismiss(animated: true, completion: nil)
		}
		
		commitButton.isEnabled = false
		
		// (Epic hack which) Makes table view cells have automatic height
		translationTableView.rowHeight = UITableViewAutomaticDimension
		translationTableView.estimatedRowHeight = 320
		
		resourceTableView.rowHeight = UITableViewAutomaticDimension
		resourceTableView.estimatedRowHeight = 320
		
		targetTranslationDS = TranslationTableViewDS(tableView: translationTableView, bookId: book.idString, configureCell: configureTargetTranslationCell, prepareUpdate: prepareForTargetUpdate)
		translationTableView.dataSource = targetTranslationDS
		
		resourceManager = ResourceManager(resourceTableView: resourceTableView, targetBookId: book.idString, addNotesDelegate: self, threadStatusListener: self, updateListener: self)
		
		// Makes resource manager listen to paragraph content changes
		targetTranslationDS.contentListeners = [self, resourceManager]
		
		// Sets scroll syncing
		scrollManager = ScrollSyncManager(leftTable: resourceTableView, rightTable: translationTableView, leftResourceId: "none", rightResourceId: "target")
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
		
		do
		{
			if let language = try Language.get(book.languageId)
			{
				titleLabel.text = "\(language.name): \(book.identifier)"
			}
		}
		catch
		{
			print("ERROR: Failed to retrieve target language data. \(error)")
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
	
	
	// CELL LISTENING	-------------
	
	func cellContentChanged(originalParagraph: Paragraph, newContent: NSAttributedString)
	{
		inputData[originalParagraph.pathId] = (originalParagraph, newContent)
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
		
		displayAlert(withIdentifier: "PostThread", storyBoardId: "Main")
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
		displayAlert(withIdentifier: "AddPost", storyBoardId: "Main")
		{
			($0 as! PostCommentVC).configure(thread: thread, selectedComment: originalComment, associatedParagraphData: associatedParagraphData)
		}
	}
	
	
	// CELL MANAGEMENT	-------------
	
	/*
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
	}*/
	
	func perform(action: TranslationCellAction, for cell: TargetTranslationCell)
	{
		switch action
		{
		// For a open notes action, opens a new resource and performs the sync scrolling
		case .openNotes(let index):
			switchToResource(atIndex: index)
			scrollManager.scrollToAnchor(cell: cell)
		// For conflicts, displays the conflict resolve VC
		case .resolveConflict:
			displayAlert(withIdentifier: "ResolveConflictVC", storyBoardId: "Main")
			{
				let viewController = $0 as! ResolveConflictVC
				// TODO: Make more secure
				viewController.configure(versionIds: self.conflictStatus[cell.pathId!]!)
			}
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
	
	func onResourcesUpdated(optionLabels: [String])
	{
		resourceSegmentControl.removeAllSegments()
		for i in 0 ..< optionLabels.count
		{
			resourceSegmentControl.insertSegment(withTitle:optionLabels[i], at: i, animated: false)
		}
		if !optionLabels.isEmpty
		{
			resourceSegmentControl.selectedSegmentIndex = 0
		}
	}
	
	func translationParagraphsUpdated(_ paragraphs: [Paragraph])
	{
		// Sets the focus back to the text view that was last edited
		if let lastEditPath = lastEditPath, let lastEditRange = lastEditRange
		{
			if let index = targetTranslationDS.indexForPath(lastEditPath), let cell = translationTableView.cellForRow(at: index) as? TargetTranslationCell
			{
				if cell.inputTextField.becomeFirstResponder()
				{
					cell.inputTextField.selectedRange = lastEditRange
				}
			}
		}
	}
	
	
	// IB ACTIONS	-----------------
	
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
	
	private func configureTargetTranslationCell(tableView: UITableView, indexPath: IndexPath, paragraph: Paragraph) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: TargetTranslationCell.identifier, for: indexPath) as! TargetTranslationCell
		
		var displaysHistory = false
		
		if let history = targetHistoryManager.currentHistoryForParagraph(withId: paragraph.idString)
		{
			cell.setContent(paragraph: history)
			displaysHistory = true
		}
		// Sets the cell contents either based on displayed history, collected user input or paragraph data
		else if let (originalParagraph, input) = inputData[paragraph.pathId]
		{
			cell.setContent(paragraph: originalParagraph, attString: input)
		}
		else
		{
			cell.setContent(paragraph: paragraph)
		}
		
		var action: TranslationCellAction?
		
		// Checks if there are any conflicts for the cell
		if conflictStatus[paragraph.pathId] != nil
		{
			action = .resolveConflict
		}
		// If there are no conflicts, checks for notes
		else if let openResourceIds = cell.pathId.flatMap({ self.openThreadStatus[$0] })
		{
			for resourceId in openResourceIds
			{
				if let resourceIndex = resourceManager.indexForResource(withId: resourceId)
				{
					action = TranslationCellAction.openNotes(atIndex: resourceIndex)
					break
				}
			}
		}
			
		cell.configure(showsHistory: displaysHistory, inputListener: self, scrollManager: scrollManager, action: action)
		cell.delegate = self
		
		return cell
	}
	
	private func prepareForTargetUpdate()
	{
		// Records which cell was the first responder before the update and what the selected range was
		var foundActiveCell = false
		for cell in translationTableView.visibleCells
		{
			if let cell = cell as? TargetTranslationCell
			{
				if cell.inputTextField.isFirstResponder
				{
					lastEditPath = cell.pathId
					lastEditRange = cell.inputTextField.selectedRange
					foundActiveCell = true
					break
				}
			}
		}
		
		if !foundActiveCell
		{
			lastEditPath = nil
			lastEditRange = nil
		}
		
		updateConflictData()
	}
	
	private func updateConflictData()
	{
		do
		{
			conflictStatus = try ParagraphHistoryView.instance.conflictsInRange(bookId: book.idString)
		}
		catch
		{
			print("ERROR: Failed to update paragraph conflict status. \(error)")
		}
	}
	
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
				for (_, (paragraph, text)) in self.inputData
				{
					_ = try paragraph.commit(userId: avatarId, text: text)
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
						inputData[paragraph.pathId] = (paragraph, paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false]))
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
		for (_, (paragraph, inputText)) in self.inputData
		{
			let paragraphCopy = paragraph.copy()
			paragraphCopy.update(with: inputText)
			
			let chapterIndex = paragraphCopy.chapterIndex
			chapterData[chapterIndex] = chapterData[chapterIndex].or([]) + paragraphCopy
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
