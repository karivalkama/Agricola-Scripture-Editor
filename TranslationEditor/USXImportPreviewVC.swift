//
//  USXImportPreviewVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 26.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

class USXImportPreviewVC: UIViewController
{
	// OUTLETS	--------------------
	
	@IBOutlet weak var translationNameLabel: UILabel!
	@IBOutlet weak var newVersionLabel: UILabel!
	@IBOutlet weak var oldVersionStackView: UIStackView!
	@IBOutlet weak var oldVersionTableView: UITableView!
	@IBOutlet weak var newVersionTableView: UITableView!
	@IBOutlet weak var progressLabel: UILabel!
	
	
	// ATTRIBUTES	----------------
	
	static let idedntifier = "USXImportPreview"
	
	private var booksToOverwrite = [(oldData: BookData, newData: BookData, matches: [(Paragraph, Paragraph)])]()
	private var booksToInsert = [BookData]()
	private var languageId: String?
	private var translationName: String?
	private var nextIndex = 0
	
	private var completion: (() -> ())?
	
	private var oldVersionDS: VersionTableDS?
	private var newVersionDS: VersionTableDS?
	private var scrollManager: ScrollSyncManager?
	
	
	// LOAD	------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		let tables = [oldVersionTableView, newVersionTableView]
		tables.forEach { $0?.register(UINib(nibName: "ParagraphCell", bundle: nil), forCellReuseIdentifier: ParagraphCell.identifier) }
		tables.forEach { $0?.rowHeight = UITableViewAutomaticDimension }
		tables.forEach { $0?.estimatedRowHeight = 160 }
		
		update()
    }
	
	
	// ACTIONS	--------------------
	
	@IBAction func skipPressed(_ sender: Any)
	{
		// Moves to the next book or closes the dialog
		proceed()
	}
	
	@IBAction func importPressed(_ sender: Any)
	{
		// Either imports or overwrites the current item, then proceeds to next one
		if nextIndex < booksToOverwrite.count
		{
			let (oldData, newData, matches) = booksToOverwrite[nextIndex]
			USXImportPreviewVC.overwrite(oldData: oldData, newData: newData, matches: matches)
		}
		else if nextIndex < booksToInsert.count, let languageId = languageId, let translationName = translationName
		{
			USXImportPreviewVC.insert(bookData: booksToInsert[nextIndex - booksToOverwrite.count], languageId: languageId, nickName: translationName, hostVC: self)
		}
		
		proceed()
	}
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		// Cancels all remaining imports and closes the dialog
		dismiss(animated: true, completion: completion)
	}
	
	
	// OTHER METHODS	-----------
	
	// TranslationName and languageId optional ONLY if no books to insert
	func configure(translationName: String?, languageId: String?, booksToOverwrite: [(oldBook: Book, newBookData: BookData)], booksToInsert: [BookData], completion: @escaping () -> ())
	{
		self.booksToInsert = booksToInsert
		self.languageId = languageId
		self.translationName = translationName
		self.nextIndex = 0
		self.completion = completion
		
		self.booksToOverwrite = []
		for (oldBook, newBookData) in booksToOverwrite
		{
			do
			{
				let oldParagraphs = try ParagraphView.instance.latestParagraphQuery(bookId: oldBook.idString).resultObjects()
				let matches = match(oldParagraphs, and: newBookData.paragraphs)
				self.booksToOverwrite.add((BookData(book: oldBook, paragraphs: oldParagraphs), newBookData, matches))
			}
			catch
			{
				print("ERROR: Couldn't read old paragraph data. \(error)")
			}
		}
	}
	
	private func proceed()
	{
		nextIndex += 1
		if nextIndex < booksToOverwrite.count + booksToInsert.count
		{
			update()
		}
		else
		{
			dismiss(animated: true, completion: completion)
		}
	}
	
	private func update()
	{
		let overwriteAmount = booksToOverwrite.count
		let insertAmount = booksToInsert.count
		let totalAmount = overwriteAmount + insertAmount
		
		translationNameLabel.text = translationName
		progressLabel.text = "\(nextIndex + 1) / \(totalAmount)"
		
		if nextIndex < overwriteAmount
		{
			// CASE: Overwrite
			let (oldData, newData, matches) = booksToOverwrite[nextIndex]
			
			oldVersionDS = VersionTableDS(paragraphs: oldData.paragraphs, matches: matches)
			newVersionDS = VersionTableDS(paragraphs: newData.paragraphs, matches: matches.map { ($0.1, $0.0) })
			
			oldVersionTableView.dataSource = oldVersionDS
			newVersionTableView.dataSource = newVersionDS
			
			scrollManager = ScrollSyncManager(leftTable: oldVersionTableView, rightTable: newVersionTableView, leftResourceId: "old", rightResourceId: "new")
			{
				tableView, oppositePathId in
				
				if tableView == self.oldVersionTableView
				{
					return self.oldVersionDS?.indexPaths(forOppositePathId: oppositePathId) ?? []
				}
				else
				{
					return self.newVersionDS?.indexPaths(forOppositePathId: oppositePathId) ?? []
				}
			}
		}
		else if nextIndex < totalAmount
		{
			oldVersionTableView.dataSource = nil
			oldVersionDS = nil
			
			newVersionDS = VersionTableDS(paragraphs: booksToInsert[nextIndex - overwriteAmount].paragraphs, matches: [])
			newVersionTableView.dataSource = newVersionDS
			scrollManager = nil
			
			oldVersionStackView.isHidden = true
		}
		else
		{
			oldVersionTableView.dataSource = nil
			newVersionTableView.dataSource = nil
			
			oldVersionDS = nil
			newVersionDS = nil
			scrollManager = nil
			
			oldVersionStackView.isHidden = true
		}
		
		oldVersionTableView.reloadData()
		newVersionTableView.reloadData()
	}
	
	static func insert(bookData: BookData, languageId: String, nickName: String, hostVC: UIViewController)
	{
		guard let avatarId = Session.instance.avatarId else
		{
			print("ERROR: Cannot save new data without user being selected")
			return
		}
		
		// Inserts the collected data as a totally new entry
		bookData.book.languageId = languageId
		
		do
		{
			guard let projectId = Session.instance.projectId, let project = try Project.get(projectId) else
			{
				print("ERROR: Associated project data couldn't be found")
				return
			}
			
			// If there are target translations that will be connected to this book, and those translations are in a conflicted state,
			// The database operations are postponed until the conflicts have been resolved
			let targetTranslations = try project.targetTranslationQuery(bookCode: bookData.book.code).resultObjects()
			
			print("STATUS: Found \(targetTranslations.count) existing target translations")
			
			guard try targetTranslations.forAll({ try !ParagraphHistoryView.instance.rangeContainsConflicts(bookId: $0.idString) }) else
			{
				hostVC.displayAlert(withIdentifier: "ErrorAlert", storyBoardId: "MainMenu")
				{
					vc in
					
					let translationString = targetTranslations.dropFirst().reduce("\(targetTranslations.first!.code)", { "\($0), \($1)" })
					
					(vc as! ErrorAlertVC).configure(heading: "Conflicts in Target Translation", text: "There are conflicts in target translation of: \(translationString)\nPlease resolve the conflicts and import the file again afterwards")
				}
				
				return
			}
			
			print("STATUS: Creating bindings between the new book and target translation(s)")
			
			// Creates new bindings for the books
			var newResources = [ResourceCollection]()
			var newBindings = [ParagraphBinding]()
			for targetBook in targetTranslations
			{
				let resource = ResourceCollection(languageId: languageId, bookId: targetBook.idString, category: .sourceTranslation, name: nickName)
				let bindings = match(bookData.paragraphs, and: try ParagraphView.instance.latestParagraphQuery(bookId: targetBook.idString).resultObjects()).map { ($0.0.idString, $0.1.idString) }
				
				newResources.add(resource)
				newBindings.add(ParagraphBinding(resourceCollectionId: resource.idString, sourceBookId: bookData.book.idString, targetBookId: targetBook.idString, bindings: bindings, creatorId: avatarId))
			}
			
			print("STATUS: Saving new book data")
			
			// Saves the new data to the database
			try DATABASE.tryTransaction
			{
				try bookData.book.push()
				try bookData.paragraphs.forEach { try $0.push() }
				try newResources.forEach { try $0.push() }
				try newBindings.forEach { try $0.push() }
			}
			
			// If there is no target translation for the book yet, creates an empty copy of the just created book
			// Or, if this book was the first target translation version, creates notes
			if targetTranslations.isEmpty
			{
				if languageId == project.languageId
				{
					let notesResource = ResourceCollection(languageId: languageId, bookId: bookData.book.idString, category: .notes, name: NSLocalizedString("Notes", comment: "The generated name of the notes resource"))
					let notes = bookData.paragraphs.map { ParagraphNotes(collectionId: notesResource.idString, chapterIndex: $0.chapterIndex, pathId: $0.pathId) }
					
					try DATABASE.tryTransaction
					{
						try notesResource.push()
						try notes.forEach { try $0.push() }
					}
				}
				else
				{
					print("STATUS: Creates a new target translation for the book")
					_ = try bookData.book.makeEmptyCopy(projectId: projectId, identifier: project.defaultBookIdentifier, languageId: languageId, userId: avatarId, resourceName: nickName)
				}
			}
		}
		catch
		{
			print("ERROR: Couldn't save book data to the database. \(error)")
		}
	}
	
	static func overwrite(oldBook: Book, newData: BookData) throws
	{
		let oldParagraphs = try ParagraphView.instance.latestParagraphQuery(bookId: oldBook.idString).resultObjects()
		USXImportPreviewVC.overwrite(oldData: BookData(book: oldBook, paragraphs: oldParagraphs), newData: newData, matches: match(oldParagraphs, and: newData.paragraphs))
	}
	
	// Runs a matching algorithm on between the new and previous data, then updates each paragraph and the book
	// Also updates bindings
	// The target translation should be checked for conflicts before this
	static func overwrite(oldData: BookData, newData: BookData, matches: [(Paragraph, Paragraph)])
	{
		guard let avatarId = Session.instance.avatarId else
		{
			print("ERROR: Cannot save new data without a selected avatar")
			return
		}
		
		do
		{
			let bookId = oldData.book.idString
			
			// Sets the correct book id for all the new paragraphs
			newData.paragraphs.forEach { $0.bookId = bookId }
			newData.book.languageId = oldData.book.languageId
			newData.book.setId(bookId)
			
			// New paragraphs can be resolved in 3 ways
			var newInserts = [Paragraph]() // Completely new versions
			var commits = [(oldVersion: Paragraph, newVersion: Paragraph)]() // Old version -> New version
			var merges = [(oldVersions: [Paragraph], newVersion: Paragraph)]() // Old versions -> New independent version
			
			// Existing paragraphs that have already been associated with a new paragraph / paragraphs
			var matchedExisting = [Paragraph]()
			
			for newParagraph in newData.paragraphs
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
				try oldData.paragraphs.filter { !matchedExisting.containsReference(to: $0) }.forEach { try ParagraphHistoryView.instance.deprecatePath(ofId: $0.idString) }
				
				// Updates book data too
				try newData.book.push()
			}
			
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
					if Book.projectId(fromId: otherSideId) == oldData.book.projectId
					{
						try ParagraphHistoryView.instance.autoCorrectConflictsInRange(bookId: otherSideId)
					}
						// Otherwise will have to skip binding update in case of conflicts
					else if try ParagraphHistoryView.instance.rangeContainsConflicts(bookId: otherSideId)
					{
						continue
					}
					
					var sources: [Paragraph]!
					var targets: [Paragraph]!
					
					if binding.sourceBookId == bookId
					{
						sources = newData.paragraphs
						targets = try ParagraphView.instance.latestParagraphQuery(bookId: binding.targetBookId).resultObjects()
					}
					else
					{
						sources = try ParagraphView.instance.latestParagraphQuery(bookId: binding.sourceBookId).resultObjects()
						targets = newData.paragraphs
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

