//
//  OverwritePreviewVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 11.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller displays two versions of a book and allows the user to overwrite existing data with new
class OverwritePreviewVC: UIViewController
{
	// OUTLETS	----------------
	
	@IBOutlet weak var oldVersionTable: UITableView!
	@IBOutlet weak var newVersionTable: UITableView!
	@IBOutlet weak var topBar: TopBarUIView!
	
	@IBOutlet weak var previewDataStackView: StatefulStackView!
	@IBOutlet weak var previewView: UIView!
	
	
	// ATTRIBUTES	------------
	
	private var configured = false
	
	private var newBook: Book!
	private var oldBook: Book!
	private var newParagraphs = [Paragraph]()
	private var oldParagraphs = [Paragraph]()
	private var matches = [(Paragraph, Paragraph)]()
	
	private var oldSideDS: VersionTableDS!
	private var newSideDS: VersionTableDS!
	
	private var scrollManager: ScrollSyncManager!
	
	
	// LOAD	--------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		guard configured else
		{
			fatalError("ERROR: OverWritePreviewVC must be configured before use")
		}
		
		topBar.configure(hostVC: self, title: "Preview Changes")
		
		previewDataStackView.register(previewView, for: .data)
		previewDataStackView.setState(.loading)
		
		// Loads the data and finalizes view asynchronously
		DispatchQueue.main.async
		{
			self.loadData()
		}
    }
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		let title = "Preview Changes"
		if let presentingViewController = presentingViewController
		{
			if let presentingViewController = presentingViewController as? ImportUSXVC
			{
				topBar.configure(hostVC: self, title: title, leftButtonText: presentingViewController.shouldDismissBelow ? "Cancel" : "Back", leftButtonAction: { presentingViewController.dismissFromAbove() })
			}
			else
			{
				topBar.configure(hostVC: self, title: title, leftButtonText: "Cancel", leftButtonAction: { self.dismiss(animated: true, completion: nil) })
			}
		}
		else
		{
			topBar.updateUserView()
		}
	}
	
	
	// ACTIONS	---------------
	
	@IBAction func abortPressed(_ sender: Any)
	{
		closeImport()
	}
	
	@IBAction func acceptPressed(_ sender: Any)
	{
		overwrite()
	}
	
	
	// OTHER METHODS	-------
	
	func configure(oldBook: Book, newBook: Book, newParagraphs: [Paragraph])
	{
		self.oldBook = oldBook
		self.newBook = newBook
		self.newParagraphs = newParagraphs
		
		self.configured = true
	}
	
	private func loadData()
	{
		// Loads the old paragraphs from the database
		do
		{
			oldParagraphs = try ParagraphView.instance.latestParagraphQuery(bookId: oldBook.idString).resultObjects()
		}
		catch
		{
			print("ERROR: Failed to load old version data")
			previewDataStackView.errorOccurred()
			return
		}
		
		previewDataStackView.dataLoaded(isEmpty: oldParagraphs.isEmpty && newParagraphs.isEmpty)
		
		// Sets up the paragraph tables
		let tables = [oldVersionTable, newVersionTable]
		tables.forEach { $0?.register(UINib(nibName: "ParagraphCell", bundle: nil), forCellReuseIdentifier: ParagraphCell.identifier) }
		tables.forEach { $0?.rowHeight = UITableViewAutomaticDimension }
		tables.forEach { $0?.estimatedRowHeight = 160 }
		
		matches = match(oldParagraphs, and: newParagraphs)
		oldSideDS = VersionTableDS(paragraphs: oldParagraphs, matches: matches)
		newSideDS = VersionTableDS(paragraphs: newParagraphs, matches: matches.map { ($0.1, $0.0) })
		
		oldVersionTable.dataSource = oldSideDS
		newVersionTable.dataSource = newSideDS
		
		// Adds scroll sync
		scrollManager = ScrollSyncManager(leftTable: oldVersionTable, rightTable: newVersionTable, leftResourceId: "old", rightResourceId: "new")
		{
			tableView, oppositePathId in
			
			if tableView == self.oldVersionTable
			{
				return self.oldSideDS.indexPaths(forOppositePathId: oppositePathId)
			}
			else
			{
				return self.newSideDS.indexPaths(forOppositePathId: oppositePathId)
			}
		}
	}
	
	private func closeImport()
	{
		if let importVC = presentingViewController as? ImportUSXVC
		{
			importVC.close()
		}
		else
		{
			dismiss(animated: true, completion: nil)
		}
	}
	
	// Runs a matching algorithm on between the new and previous data, then updates each paragraph and the book
	// Also updates bindings
	// The target translation should be checked for conflicts before this
	private func overwrite()
	{
		guard let avatarId = Session.instance.avatarId else
		{
			print("ERROR: Cannot save new data without a selected avatar")
			return
		}
		
		do
		{
			// New paragraphs can be resolved in 3 ways
			var newInserts = [Paragraph]() // Completely new versions
			var commits = [(oldVersion: Paragraph, newVersion: Paragraph)]() // Old version -> New version
			var merges = [(oldVersions: [Paragraph], newVersion: Paragraph)]() // Old versions -> New independent version
			
			// Existing paragraphs that have already been associated with a new paragraph / paragraphs
			var matchedExisting = [Paragraph]()
			
			for newParagraph in newParagraphs
			{
				// Finds out how many connections (existing -> new) were made to each new paragraph
				// Only counts paragraphs that have not been matched already
				let matchingExisting = matches.filter { $0.1 === newParagraph }.map { $0.0 }.filter { !matchedExisting.containsReference(to: $0) }
				
				// If there are 0 previous versions, or if all of those were already matched to different paragraphs, inserts the new paragraph as a completely new entry
				if matchingExisting.isEmpty
				{
					newInserts.add(newParagraph)
				}
					// If there is only a single match, handles it as a new commit
				else if matchingExisting.count == 1
				{
					commits.add((oldVersion: matchingExisting.first!, newVersion: newParagraph))
					matchedExisting.add(matchingExisting.first!)
				}
				else
				{
					merges.add((oldVersions: matchingExisting, newVersion: newParagraph))
					matchedExisting.append(contentsOf: matchingExisting)
				}
			}
			
			// Saves new data to the database all at once
			try DATABASE.tryTransaction
			{
				try newInserts.forEach { try $0.push() }
				
				for (oldVersion, newVersion) in commits
				{
					_ = try oldVersion.commit(userId: avatarId, chapterIndex: newVersion.chapterIndex, sectionIndex: newVersion.sectionIndex, paragraphIndex: newVersion.index, content: newVersion.content)
				}
				
				for (oldVersions, newVersion) in merges
				{
					// On merge, all old versions are deprecated while the new version is inserted separately
					try oldVersions.forEach { try ParagraphHistoryView.instance.deprecatePath(ofId: $0.idString) }
					try newVersion.push()
				}
				
				// Old paragraphs that were left without any matches are deprecated
				try self.oldParagraphs.filter { !matchedExisting.containsReference(to: $0) }.forEach { try ParagraphHistoryView.instance.deprecatePath(ofId: $0.idString) }
				
				// Updates book identifier too, if necessary
				if self.oldBook.identifier != self.newBook.identifier
				{
					self.oldBook.identifier = self.newBook.identifier
					try self.oldBook.push()
				}
			}
			
			let bookId = oldBook.idString
			
			// Updates the paragraph bindings if necessary
			// Also updates notes
			if !newInserts.isEmpty || !merges.isEmpty
			{
				let bindings = try ParagraphBindingView.instance.bindings(forBookWithId: bookId)
				
				for binding in bindings
				{
					// Makes sure the other side doesn't have any conflicts
					let otherSideId = binding.sourceBookId == bookId ? binding.targetBookId : binding.sourceBookId
					// If both books belong to the same project, can just auto-resolve any conflicts
					if Book.projectId(fromId: otherSideId) == oldBook.projectId
					{
						try ParagraphHistoryView.instance.autoCorrectConflictsInRange(bookId: otherSideId)
					}
						// Otherwise will have to skip binding update
					else if try ParagraphHistoryView.instance.rangeContainsConflicts(bookId: otherSideId)
					{
						continue
					}
					
					var sources: [Paragraph]!
					var targets: [Paragraph]!
					
					if binding.sourceBookId == bookId
					{
						sources = newParagraphs
						targets = try ParagraphView.instance.latestParagraphQuery(bookId: binding.targetBookId).resultObjects()
					}
					else
					{
						sources = try ParagraphView.instance.latestParagraphQuery(bookId: binding.sourceBookId).resultObjects()
						targets = newParagraphs
					}
					
					let bindMatches = match(sources, and: targets).map { (sourceId: $0.0.idString, targetId: $0.1.idString) }
					
					binding.created = Date().timeIntervalSince1970
					binding.creatorId = avatarId
					binding.bindings = bindMatches
				}
				
				// Saves all changes at once
				try DATABASE.tryTransaction
				{
					try bindings.forEach { try $0.push() }
				}
				
				// Records all changed notes so that the changes can be made all at once
				var notesToBeSaved = [ParagraphNotes]()
				
				let notesCollectionIds = try ResourceCollectionView.instance.collectionQuery(bookId: bookId, category: .notes).resultRows().flatMap { $0.id }
				for notesCollectionId in notesCollectionIds
				{
					// Creates a new note for each new inserted paragraph
					for insertedParagraph in newInserts
					{
						notesToBeSaved.add(ParagraphNotes(collectionId: notesCollectionId, chapterIndex: insertedParagraph.chapterIndex, pathId: insertedParagraph.pathId))
					}
					
					// Changes the path id of the merged paragraph notes
					for (oldVersions, newVersion) in merges
					{
						for oldVersion in oldVersions
						{
							for note in try ParagraphNotesView.instance.notesForParagraph(collectionId: notesCollectionId, chapterIndex: oldVersion.chapterIndex, pathId: oldVersion.pathId)
							{
								note.pathId = newVersion.pathId
								notesToBeSaved.add(note)
							}
						}
					}
					
					// TODO: Should some notes be deleted?
				}
				
				// Saves the changes
				try DATABASE.tryTransaction
				{
					try notesToBeSaved.forEach { try $0.push() }
				}
			}
			
			// Selects a target translation matching the newly updated book
			do
			{
				if let projectId = Session.instance.projectId, let project = try Project.get(projectId)
				{
					Session.instance.bookId = try project.targetTranslationQuery().firstResultRow()?.id
				}
			}
			catch
			{
				print("ERROR: Failed to find associated target translation")
			}
			
			closeImport()
		}
		catch
		{
			print("ERROR: Failed to perform changes to the database. \(error)")
		}
	}
}

fileprivate class VersionTableDS: NSObject, UITableViewDataSource
{
	// ATTRIBUTES	----------
	
	// Key = opposite side path id. Value = this side indices
	private let indexMap: [String: [Int]]
	private let paragraphs: [Paragraph]
	
	
	// INIT	------------------
	
	init(paragraphs: [Paragraph], matches: [(thisSide: Paragraph, otherSide: Paragraph)])
	{
		self.paragraphs = paragraphs
		self.indexMap = matches.toArrayDictionary { match in paragraphs.index(referencing: match.thisSide).map { (match.otherSide.pathId, $0) } }
	}
	
	
	// IMPLEMENTED METHODS	--
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return paragraphs.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: ParagraphCell.identifier, for: indexPath) as! ParagraphCell
		cell.configure(paragraph: paragraphs[indexPath.row])
		return cell
	}
	
	
	// OTHER METHODS	-----
	
	func indexPaths(forOppositePathId pathId: String) -> [IndexPath]
	{
		return (indexMap[pathId] ?? []).map { IndexPath(row: $0, section: 0) }
	}
}
