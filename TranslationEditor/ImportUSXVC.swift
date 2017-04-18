//
//  ImportUSXVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This VC is used for importing new books / updating existing data from USX files
class ImportUSXVC: UIViewController, UITableViewDataSource, FilteredSelectionDataSource, FilteredSingleSelectionDelegate, SelectBookTableControllerDelegate
{
	// TYPES	--------------
	
	typealias QueryTarget = LanguageView
	
	
	// OUTLETS	--------------
	
	@IBOutlet weak var topUserView: TopUserView!
	@IBOutlet weak var bookLabel: UILabel!
	@IBOutlet weak var paragraphTableView: UITableView!
	@IBOutlet weak var selectLanguageView: FilteredSingleSelection!
	@IBOutlet weak var selectBookTableView: UITableView!
	
	
	// ATTRIBUTES	---------
	
	private var usxURL: URL?
	private var book: Book?
	
	private var languages = [Language]()
	private var selectedLanguage: Language?
	
	private var paragraphs = [Paragraph]()
	private var bookTableController: SelectBookTableController?
	
	
	// COMPUTED PROPERTIES	--
	
	var numberOfOptions: Int { return languages.count }
	
	
	// LOAD	-----------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		// Reads paragraph data first
		guard let usxURL = usxURL else
		{
			fatalError("ImportUSXVC must be configured before use")
		}
		
		guard let projectId = Session.instance.projectId else
		{
			print("ERROR: Project must be defined before USX import")
			return
		}
		
		guard let avatarId = Session.instance.avatarId else
		{
			print("ERROR: Avatar must be selected before USX import")
			return
		}
		
		guard let parser = XMLParser(contentsOf: usxURL) else
		{
			print("ERROR: Couldn't create an XML parser")
			return
		}
		
		// Language is set afterwards
		let usxParserDelegate = USXParser(projectId: projectId, userId: avatarId, languageId: "")
		parser.delegate = usxParserDelegate
		parser.parse()
		
		guard usxParserDelegate.success else
		{
			print("ERROR: USX parsing failed. \(usxParserDelegate.error!)")
			return
		}
		
		// Only picks the first parsed book
		// TODO: Add handling for USX files that contain multiple books
		guard let bookData = usxParserDelegate.parsedBooks.first else
		{
			print("ERROR: Couldn't parse any book data")
			return
		}
		
		if usxParserDelegate.parsedBooks.count > 1
		{
			print("WARNING: Multiple books were read. Only the first one is used.")
		}
		
		book = bookData.book
		paragraphs = bookData.paragraphs
		
		// Sets up the paragraph table
		paragraphTableView.register(UINib(nibName: "ParagraphCell", bundle: nil), forCellReuseIdentifier: ParagraphCell.identifier)
		paragraphTableView.rowHeight = UITableViewAutomaticDimension
		paragraphTableView.estimatedRowHeight = 160
		paragraphTableView.dataSource = self
		
		// Sets up other views
		bookLabel.text = "\(book!.code): \(book!.identifier)"
		
		bookTableController = SelectBookTableController(table: selectBookTableView, newIdentifier: book!.identifier)
		
		do
		{
			languages = try LanguageView.instance.createQuery().resultObjects()
			selectLanguageView.datasource = self
			selectLanguageView.delegate = self
		}
		catch
		{
			print("ERROR: Couldn't read language data from the database")
		}
		
		do
		{
			try topUserView.configure(avatarId: avatarId)
		}
		catch
		{
			print("ERROR: Failed to setup the view properly. \(error)")
		}
    }

	
	// ACTIONS	-------------
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	
	// IMPLEMENTED METHODS	---
	
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
	
	func labelForOption(atIndex index: Int) -> String
	{
		return languages[index].name
	}
	
	func indexIsIncludedInFilter(index: Int, filter: String) -> Bool
	{
		return labelForOption(atIndex: index).contains(filter)
	}
	
	func onItemSelected(index: Int)
	{
		guard let projectId = Session.instance.projectId else
		{
			print("ERROR: Cannot find project books when project is not selected")
			return
		}
		
		selectedLanguage = languages[index]
		
		// Reloads the available target books
		do
		{
			let books = try ProjectBooksView.instance.booksQuery(languageId: languages[index].idString, projectId: projectId).resultObjects()
			bookTableController?.update(books: books)
		}
		catch
		{
			print("ERROR: Failed to update book selection. \(error)")
		}
	}
	
	func insertItem(named: String) -> Int?
	{
		// Checks if there already exists a language with the provided name
		if let existingIndex = languages.index(where: { $0.name.lowercased() == named.lowercased() })
		{
			return existingIndex
		}
		else
		{
			do
			{
				let newLanguage = try LanguageView.instance.language(withName: named)
				languages.add(newLanguage)
				// TODO: Sorting is not done correctly here. Consider other options
				return languages.count - 1
			}
			catch
			{
				print("ERROR: Failed to insert a new language")
				return nil
			}
		}
	}
	
	func bookSelected(_ book: Book)
	{
		// Runs a matching algorithm on between the new and previous data, then updates each paragraph and the book
		// TODO: Update book data (commit). Also update bindings
		
		guard let avatarId = Session.instance.avatarId else
		{
			print("ERROR: Cannot save new data without a selected avatar")
			return
		}
		
		guard let newBook = self.book else
		{
			print("ERROR: No new book data available")
			return
		}
		
		do
		{
			let existingParagraphs = try ParagraphView.instance.latestParagraphQuery(bookId: book.idString).resultObjects()
			let matches = match(existingParagraphs, and: paragraphs)
			
			// New paragraphs can be resolved in 3 ways
			var newInserts = [Paragraph]() // Completely new versions
			var commits = [(Paragraph, Paragraph)]() // Old version -> New version
			var merges = [([Paragraph], Paragraph)]() // Old versions -> New independent version
			
			// Existing paragraphs that have already been associated with a new paragraph / paragraphs
			var matchedExisting = [Paragraph]()
			
			for newParagraph in paragraphs
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
					commits.add((matchingExisting.first!, newParagraph))
					matchedExisting.add(matchingExisting.first!)
				}
				else
				{
					merges.add((matchingExisting, newParagraph))
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
				try existingParagraphs.filter { !matchedExisting.containsReference(to: $0) }.forEach { try ParagraphHistoryView.instance.deprecatePath(ofId: $0.idString) }
				
				// Updates book identifier too, if necessary
				if book.identifier != newBook.identifier
				{
					book.identifier = newBook.identifier
					try book.push()
				}
			}
			
			// Updates the paragraph bindings if necessary
			if !newInserts.isEmpty || !merges.isEmpty
			{
				
			}
		}
		catch
		{
			
		}
	}
	
	func insertSelected()
	{
		guard let avatarId = Session.instance.avatarId else
		{
			print("ERROR: Cannot save new data without user being selected")
			return
		}
		
		guard let selectedLanguage = selectedLanguage else
		{
			print("ERROR: Cannot insert a book before language has been selected")
			return
		}
		
		guard book != nil else
		{
			print("ERROR: No book data available")
			return
		}
		
		// Inserts the collected data as a totally new entry
		book?.languageId = selectedLanguage.idString
		
		do
		{
			guard let projectId = Session.instance.projectId, let project = try Project.get(projectId) else
			{
				print("ERROR: Associated project data couldn't be found")
				return
			}
			
			// Creates new bindings for the books
			var newBindings = [ParagraphBinding]()
			for book in try project.targetTranslationQuery(bookCode: book!.code).resultObjects()
			{
				let bindings = match(paragraphs, and: try ParagraphView.instance.latestParagraphQuery(bookId: book.idString).resultObjects()).map { ($0.0.idString, $0.1.idString) }
				newBindings.add(ParagraphBinding(sourceBookId: self.book!.idString, targetBookId: book.idString, bindings: bindings, creatorId: avatarId))
			}
			
			// Saves the new data to the database
			try DATABASE.tryTransaction
			{
				try self.book?.push()
				try self.paragraphs.forEach { try $0.push() }
				try newBindings.forEach { try $0.push() }
			}
			
			dismiss(animated: true, completion: nil)
		}
		catch
		{
			print("ERROR: Couldn't save book data to the database. \(error)")
		}
	}
	
	
	// OTHER METHODS	----
	
	func configure(usxFileURL: URL)
	{
		usxURL = usxFileURL
	}
}

fileprivate class SelectBookTableController: NSObject, UITableViewDataSource, UITableViewDelegate
{
	// ATTRIBUTES	--------
	
	weak var delegate: SelectBookTableControllerDelegate?
	
	private weak var table: UITableView!
	private let newIdentifier: String
	
	private var books = [Book]()
	private var allowInsert = false
	
	
	// INIT	----------------
	
	init(table: UITableView, newIdentifier: String)
	{
		self.table = table
		self.newIdentifier = newIdentifier
		
		super.init()
		
		table.dataSource = self
		table.delegate = self
	}
	
	
	// OTHER METHODS	---
	
	func update(books: [Book])
	{
		self.books = books
		allowInsert = true
		
		table.reloadData()
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func numberOfSections(in tableView: UITableView) -> Int
	{
		return allowInsert ? 2 : 1
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		switch section
		{
		case 0: return "Existing books"
		case 1: return "Insert a new book"
		default: return nil
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if section == 0
		{
			return books.count
		}
		else
		{
			return 1
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
		
		if indexPath.section == 0
		{
			cell.configure(text: books[indexPath.row].identifier)
		}
		else
		{
			cell.configure(text: "NEW: \(newIdentifier)")
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		if indexPath.section == 0
		{
			delegate?.bookSelected(books[indexPath.row])
		}
		else
		{
			delegate?.insertSelected()
		}
	}
}

fileprivate protocol SelectBookTableControllerDelegate: class
{
	// This method is called when an existing book is selected
	func bookSelected(_ book: Book)
	
	// This method is called when the insert book option is selected
	func insertSelected()
}
