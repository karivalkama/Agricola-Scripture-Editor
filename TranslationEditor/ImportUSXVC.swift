////
////  ImportUSXVC.swift
////  TranslationEditor
////
////  Created by Mikko Hilpinen on 13.4.2017.
////  Copyright © 2017 SIL. All rights reserved.
////
//
//import UIKit
//
//// TODO: Refactor. Also, create a way to name the imported translations
//
//// This VC is used for importing new books / updating existing data from USX files
//class ImportUSXVC: UIViewController, UITableViewDataSource, FilteredSelectionDataSource, SimpleSingleSelectionViewDelegate, SelectBookTableControllerDelegate, StackDismissable
//{
//	// OUTLETS	--------------
//	
//	@IBOutlet weak var bookLabel: UILabel!
//	@IBOutlet weak var paragraphTableView: UITableView!
//	@IBOutlet weak var selectLanguageView: SimpleSingleSelectionView!
//	@IBOutlet weak var selectBookTableView: UITableView!
//	@IBOutlet weak var insertSwitch: UISwitch!
//	@IBOutlet weak var nicknameField: UITextField!
//	@IBOutlet weak var nicknameView: UIView!
//	@IBOutlet weak var selectBookView: UIView!
//	@IBOutlet weak var okButton: BasicButton!
//	@IBOutlet weak var contentView: KeyboardReactiveView!
//	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
//	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
//	@IBOutlet weak var topBar: TopBarUIView!
//	@IBOutlet weak var inputStackView: SquishableStackView!
//	@IBOutlet weak var previewDataStackView: StatefulStackView!
//	
//	
//	// ATTRIBUTES	---------
//	
//	private var usxURL: URL?
//	private var book: Book?
//	
//	private var languages = [Language]()
//	private var selectedLanguage: Language?
//	private var languageName = ""
//	
//	private var paragraphs = [Paragraph]()
//	private var bookTableController: SelectBookTableController?
//	
//	private var bookToOverwrite: Book?
//	private var targetLanguageIsSelected = false
//	private var foundMatchWithIdentifier = false
//	
//	
//	// COMPUTED PROPERTIES	--
//	
//	var numberOfOptions: Int { return languages.count }
//	
//	var shouldDismissBelow: Bool { return foundMatchWithIdentifier }
//	
//	
//	// LOAD	-----------------
//	
//    override func viewDidLoad()
//	{
//        super.viewDidLoad()
//		
//		topBar.configure(hostVC: self, title: "Import USX File", leftButtonText: "Cancel", leftButtonAction: { self.dismiss(animated: true, completion: nil) })
//		contentView.configure(mainView: view, elements: [selectLanguageView, insertSwitch, nicknameField, okButton], topConstraint: contentTopConstraint, bottomConstraint: contentBottomConstraint, style: .squish, squishedElements: [inputStackView])
//		
//		previewDataStackView.register(paragraphTableView, for: .data)
//		previewDataStackView.setState(.loading)
//		
//		// Reads paragraph data first
//		guard let usxURL = usxURL else
//		{
//			fatalError("ImportUSXVC must be configured before use")
//		}
//		
//		guard let projectId = Session.instance.projectId else
//		{
//			print("ERROR: Project must be defined before USX import")
//			previewDataStackView.errorOccurred()
//			return
//		}
//		
//		guard let avatarId = Session.instance.avatarId else
//		{
//			print("ERROR: Avatar must be selected before USX import")
//			previewDataStackView.errorOccurred()
//			return
//		}
//		
//		guard let parser = XMLParser(contentsOf: usxURL) else
//		{
//			print("ERROR: Couldn't create an XML parser")
//			previewDataStackView.errorOccurred()
//			return
//		}
//		
//		// Parses the data asynchronously
//		DispatchQueue.main.async
//		{
//			// Language is set afterwards
//			let usxParserDelegate = USXParser(projectId: projectId, userId: avatarId, languageId: "")
//			parser.delegate = usxParserDelegate
//			parser.parse()
//			
//			guard usxParserDelegate.success else
//			{
//				// TODO: Display error message on failure
//				print("ERROR: USX parsing failed. \(usxParserDelegate.error!)")
//				
//				var message = "Parsing failed for some reason"
//				
//				if let error = usxParserDelegate.error as? USXParseError
//				{
//					switch error
//					{
//					case .verseIndexNotFound: message = "A verse number is missing"
//					case .verseIndexParsingFailed: message = "Verse number parsing failed"
//					case .verseRangeParsingFailed: message = "Verse number parsing failed"
//					case .chapterIndexNotFound: message = "No chapter marker found"
//					case .bookNameNotSpecified: message = "No book name found"
//					case .bookCodeNotFound: message = "Book code is missing"
//					case .attributeMissing: message = "Required usx-attribute is missing"
//					case .unknownNoteStyle: message = "Unrecognized note style"
//					}
//				}
//				
//				self.previewDataStackView.errorOccurred(title: "Couldn't read the USX file", description: message)
//				
//				return
//			}
//			
//			// Only picks the first parsed book
//			// TODO: Add handling for USX files that contain multiple books
//			guard let bookData = usxParserDelegate.parsedBooks.first else
//			{
//				print("ERROR: Couldn't parse any book data")
//				self.previewDataStackView.dataLoaded(isEmpty: true)
//				return
//			}
//			
//			self.previewDataStackView.dataLoaded()
//			
//			if usxParserDelegate.parsedBooks.count > 1
//			{
//				print("WARNING: Multiple books were read. Only the first one is used.")
//			}
//			
//			self.book = bookData.book
//			self.paragraphs = bookData.paragraphs
//			
//			// Checks if there already exists a book with an identical identifier, in which case rest of the next view is presented eventually
//			do
//			{
//				try ProjectBooksView.instance.booksQuery(projectId: projectId).enumerateResultObjects
//				{
//					existingBook in
//					
//					if existingBook.code == bookData.book.code && existingBook.identifier == bookData.book.identifier
//					{
//						print("STATUS: Found a matching identfier")
//						
//						self.bookToOverwrite = existingBook
//						self.book?.languageId = existingBook.languageId
//						self.foundMatchWithIdentifier = true
//						return false
//					}
//					else
//					{
//						return true
//					}
//				}
//				
//				// The view proceeds once the data is read. If it was read before the view appeared, the transition is performed there instead
//				if self.foundMatchWithIdentifier && self.presentingViewController != nil
//				{
//					self.continueToOverwrite()
//				}
//			}
//			catch
//			{
//				print("ERROR: Failed to check if there exists a book with an identical identifier. \(error)")
//			}
//			
//			// Sets up the paragraph table
//			self.paragraphTableView.register(UINib(nibName: "ParagraphCell", bundle: nil), forCellReuseIdentifier: ParagraphCell.identifier)
//			//paragraphTableView.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
//			self.paragraphTableView.rowHeight = UITableViewAutomaticDimension
//			self.paragraphTableView.estimatedRowHeight = 160
//			self.paragraphTableView.dataSource = self
//			
//			// Sets up other views
//			self.bookLabel.text = "\(self.book!.code): \(self.book!.identifier)"
//			self.setInsertStatus(true, lock: true) // Insert mode is used by default. It cannot be changed before language is selected
//			self.updateOkButtonStatus()
//			
//			self.selectBookTableView.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
//			self.bookTableController = SelectBookTableController(table: self.selectBookTableView, newIdentifier: self.book!.identifier)
//			self.bookTableController?.delegate = self
//		}
//		
//		// Also retrieves languages (asynchronously)
//		DispatchQueue.main.async
//		{
//			do
//			{
//				self.languages = try LanguageView.instance.createQuery().resultObjects()
//				self.selectLanguageView.datasource = self
//				self.selectLanguageView.delegate = self
//				self.selectLanguageView.reloadData()
//			}
//			catch
//			{
//				print("ERROR: Couldn't read language data from the database")
//			}
//		}
//    }
//	
//	override func viewWillAppear(_ animated: Bool)
//	{
//		super.viewWillAppear(animated)
//		
//		topBar.updateUserView()
//		
//		if foundMatchWithIdentifier && bookToOverwrite != nil
//		{
//			print("STATUS: Found a a book with identical identifier, moves to overwrite preview.")
//			continueToOverwrite()
//		}
//		
//		contentView.startKeyboardListening()
//	}
//	
//	override func viewDidDisappear(_ animated: Bool)
//	{
//		super.viewDidDisappear(animated)
//		contentView.endKeyboardListening()
//	}
//
//	
//	// ACTIONS	-------------
//	
//	@IBAction func okButtonPressed(_ sender: Any)
//	{
//		if bookToOverwrite != nil
//		{
//			continueToOverwrite()
//		}
//		else
//		{
//			insertBook()
//		}
//	}
//	
//	@IBAction func insertOptionChanged(_ sender: Any)
//	{
//		setInsertStatus(insertSwitch.isOn, lock: false)
//	}
//	
//	@IBAction func nicknameFieldChanged(_ sender: Any)
//	{
//		updateOkButtonStatus()
//	}
//	
//	
//	// IMPLEMENTED METHODS	---
//	
//	override func prepare(for segue: UIStoryboardSegue, sender: Any?)
//	{
//		if let previewVC = segue.destination as? OverwritePreviewVC
//		{
//			previewVC.configure(oldBook: bookToOverwrite!, newBook: book!, newParagraphs: paragraphs)
//		}
//	}
//	
//	func willDissmissBelow()
//	{
//		bookToOverwrite = nil
//	}
//	
//	func onValueChanged(_ newValue: String, selectedAt index: Int?)
//	{
//		languageName = newValue
//		bookToOverwrite = nil
//		
//		guard let projectId = Session.instance.projectId else
//		{
//			print("ERROR: Cannot find project books when project is not selected")
//			return
//		}
//		
//		do
//		{
//			guard let project = try Project.get(projectId) else
//			{
//				print("ERROR: Couldn't find project data from the database")
//				return
//			}
//			
//			selectedLanguage = index.map { languages[$0] } ?? languages.first(where: { $0.name.lowercased() == newValue.lowercased() })
//			
//			// Checks if the selected language was the target language for the project
//			targetLanguageIsSelected = selectedLanguage?.idString == project.languageId
//			
//			if targetLanguageIsSelected
//			{
//				// If the target language is targeted, only allows update for the target translation
//				// If there is no previous version, forces insert
//				if let previousTargetTranslation = try project.targetTranslationQuery(bookCode: book?.code).firstResultObject()
//				{
//					bookToOverwrite = previousTargetTranslation
//					setInsertStatus(false, lock: true)
//				}
//				else
//				{
//					setInsertStatus(true, lock: true)
//				}
//			}
//			else if let selectedLanguage = selectedLanguage
//			{
//				// If some other existing language is targeted, finds the existing books
//				let books = try ProjectBooksView.instance.booksQuery(projectId: projectId, languageId: selectedLanguage.idString, code: book?.code).resultObjects()
//				bookTableController?.update(books: books)
//				
//				// If there are no books, forces insert
//				setInsertStatus(books.isEmpty ? true : insertSwitch.isOn, lock: books.isEmpty)
//			}
//			else
//			{
//				// If a completely new language is used, forces insert
//				setInsertStatus(true, lock: true)
//			}
//			
//			updateOkButtonStatus()
//		}
//		catch
//		{
//			print("ERROR: Failed to update status after language selection. \(error)")
//		}
//	}
//	
//	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
//	{
//		return paragraphs.count
//	}
//	
//	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
//	{
//		let cell = tableView.dequeueReusableCell(withIdentifier: ParagraphCell.identifier, for: indexPath) as! ParagraphCell
//		cell.configure(paragraph: paragraphs[indexPath.row])
//		
//		return cell
//	}
//	
//	func labelForOption(atIndex index: Int) -> String
//	{
//		return languages[index].name
//	}
//	
//	func bookSelected(_ book: Book)
//	{
//		bookToOverwrite = book
//		updateOkButtonStatus()
//	}
//	
//	
//	// OTHER METHODS	----
//	
//	func configure(usxFileURL: URL)
//	{
//		usxURL = usxFileURL
//	}
//	
//	func close()
//	{
//		bookToOverwrite = nil
//		
//		if let presentingViewController = presentingViewController
//		{
//			presentingViewController.dismiss(animated: true, completion: nil)
//		}
//		else
//		{
//			dismiss(animated: true, completion: nil)
//		}
//	}
//	
//	// Updates OK button enabled status
//	private func updateOkButtonStatus()
//	{
//		if insertSwitch.isOn
//		{
//			// If on insert mode, the ok button is available once both language and nickname have been selected
//			// If target language is targeted, doesn't need the nickname for the translation
//			let enabled = !languageName.isEmpty && (targetLanguageIsSelected || !nicknameField.trimmedText.isEmpty)
//			print("STATUS: Updating OK button status. New enabled status: \(enabled)")
//			okButton.isEnabled = enabled
//		}
//		else
//		{
//			// If on overwrite mode, the overwritten book must be selected
//			okButton.isEnabled = bookToOverwrite != nil && selectedLanguage != nil
//		}
//	}
//	
//	private func setInsertStatus(_ isInsertMode: Bool, lock: Bool)
//	{
//		insertSwitch.isOn = isInsertMode
//		// If the target language was selected, doesn't need to provide additional data
//		nicknameView.isHidden = !isInsertMode || targetLanguageIsSelected
//		selectBookView.isHidden = isInsertMode || targetLanguageIsSelected || selectedLanguage == nil
//		insertSwitch.isEnabled = !lock
//	}
//	
//	// Localization added automatically
//	private func displayError(heading: String, message: String)
//	{
//		displayAlert(withIdentifier: "ErrorAlert", storyBoardId: "MainMenu")
//		{
//			// TODO: Add message localization. Problem: The message may be / is an interpolated string
//			($0 as! ErrorAlertVC).configure(heading: NSLocalizedString(heading, comment: "An error heading"), text: message) { self.dismiss(animated: true, completion: nil) }
//		}
//	}
//	
//	private func continueToOverwrite()
//	{
//		// Makes sure there are no conflicts within the target translation(s) for the book
//		do
//		{
//			guard let bookToOverwrite = bookToOverwrite else
//			{
//				print("ERROR: Cannot continue to preview without first selecting book to overwrite")
//				return
//			}
//			
//			// If there are connected target translations that are in a conflicted state, can't perform the update
//			guard let projectId = Session.instance.projectId, let project = try Project.get(projectId) else
//			{
//				print("ERROR: Project must be selected before USX import")
//				return
//			}
//			
//			let targetTranslationIds = try project.targetTranslationQuery(bookCode: bookToOverwrite.code).resultRows().compactMap { $0.id }.filter { $0 != bookToOverwrite.idString }
//			guard try targetTranslationIds.forAll({ try !ParagraphHistoryView.instance.rangeContainsConflicts(bookId: $0) }) else
//			{
//				displayError(heading: "Conflicts in Target Translations", message: "Target translation of \(bookToOverwrite.code) contain conflicts. Please resolve them and try importing again afterwards.")
//				return
//			}
//			
//			// If there are conflicts within the book, merges them before continuing
//			try ParagraphHistoryView.instance.autoCorrectConflictsInRange(bookId: bookToOverwrite.idString)
//			
//			// Displays the preview which allows overwrite
//			performSegue(withIdentifier: "ImportPreview", sender: nil)
//		}
//		catch
//		{
//			print("ERROR: Failed to check for conflicts in target translations. \(error)")
//			displayError(heading: "Internal Error Occurred!", message: "Failed to handle translation conflict state due to an internal error")
//		}
//	}
//	
//	private func insertBook()
//	{
//		guard let avatarId = Session.instance.avatarId else
//		{
//			print("ERROR: Cannot save new data without user being selected")
//			return
//		}
//		
//		guard let selectedLanguage = selectedLanguage else
//		{
//			print("ERROR: Cannot insert a book before language has been selected")
//			return
//		}
//		
//		guard let book = book else
//		{
//			print("ERROR: No book data available")
//			return
//		}
//		
//		// Inserts the collected data as a totally new entry
//		book.languageId = selectedLanguage.idString
//		
//		do
//		{
//			guard let projectId = Session.instance.projectId, let project = try Project.get(projectId) else
//			{
//				print("ERROR: Associated project data couldn't be found")
//				return
//			}
//			
//			// If there are target translations that will be connected to this book, and those translations are in a conflicted state,
//			// The database operations are postponed until the conflicts have been resolved
//			let targetTranslations = try project.targetTranslationQuery(bookCode: book.code).resultObjects()
//			
//			print("STATUS: Found \(targetTranslations.count) existing target translations")
//			
//			guard try targetTranslations.forAll({ try !ParagraphHistoryView.instance.rangeContainsConflicts(bookId: $0.idString) }) else
//			{
//				displayAlert(withIdentifier: "ErrorAlert", storyBoardId: "MainMenu")
//				{
//					vc in
//					
//					let translationString = targetTranslations.dropFirst().reduce("\(targetTranslations.first!.code)", { "\($0), \($1)" })
//					
//					(vc as! ErrorAlertVC).configure(heading: "Conflicts in Target Translation", text: "There are conflicts in target translation of: \(translationString)\nPlease resolve the conflicts and import the file again afterwards") { self.dismiss(animated: true, completion: nil) }
//				}
//				
//				return
//			}
//			
//			print("STATUS: Creating bindings between the new book and target translation(s)")
//			
//			// Creates new bindings for the books
//			var newResources = [ResourceCollection]()
//			var newBindings = [ParagraphBinding]()
//			for targetBook in targetTranslations
//			{
//				let resource = ResourceCollection(languageId: selectedLanguage.idString, bookId: targetBook.idString, category: .sourceTranslation, name: nicknameField.text.or(book.identifier))
//				let bindings = match(paragraphs, and: try ParagraphView.instance.latestParagraphQuery(bookId: targetBook.idString).resultObjects()).map { ($0.0.idString, $0.1.idString) }
//				
//				newResources.add(resource)
//				newBindings.add(ParagraphBinding(resourceCollectionId: resource.idString, sourceBookId: book.idString, targetBookId: targetBook.idString, bindings: bindings, creatorId: avatarId))
//			}
//			
//			print("STATUS: Saving new book data")
//			
//			// Saves the new data to the database
//			try DATABASE.tryTransaction
//			{
//				try book.push()
//				try self.paragraphs.forEach { try $0.push() }
//				try newResources.forEach { try $0.push() }
//				try newBindings.forEach { try $0.push() }
//			}
//			
//			// If there is no target translation for the book yet, creates an empty copy of the just created book
//			// Or, if this book was the first target translation version, creates notes
//			var newBookId: String?
//			if targetTranslations.isEmpty
//			{
//				if book.languageId == project.languageId
//				{
//					let notesResource = ResourceCollection(languageId: book.languageId, bookId: book.idString, category: .notes, name: NSLocalizedString("Notes", comment: "The generated name of the notes resource"))
//					let notes = self.paragraphs.map { ParagraphNotes(collectionId: notesResource.idString, chapterIndex: $0.chapterIndex, pathId: $0.pathId) }
//					
//					try DATABASE.tryTransaction
//					{
//						try notesResource.push()
//						try notes.forEach { try $0.push() }
//					}
//					
//					newBookId = book.idString
//				}
//				else
//				{
//					print("STATUS: Creates a new target translation for the book")
//					newBookId = try book.makeEmptyCopy(projectId: projectId, identifier: project.defaultBookIdentifier, languageId: project.languageId, userId: avatarId, resourceName: nicknameField.text.or(book.identifier)).book.idString
//				}
//			}
//			
//			// The newly update book will be opened afterwards
//			Session.instance.bookId = newBookId ?? targetTranslations.first?.idString
//			dismiss(animated: true, completion: nil)
//		}
//		catch
//		{
//			print("ERROR: Couldn't save book data to the database. \(error)")
//		}
//	}
//}
//
//fileprivate class SelectBookTableController: NSObject, UITableViewDataSource, UITableViewDelegate
//{
//	// ATTRIBUTES	--------
//	
//	weak var delegate: SelectBookTableControllerDelegate?
//	
//	private weak var table: UITableView!
//	private let newIdentifier: String
//	
//	private var books = [Book]()
//	
//	
//	// INIT	----------------
//	
//	init(table: UITableView, newIdentifier: String)
//	{
//		self.table = table
//		self.newIdentifier = newIdentifier
//		
//		super.init()
//		
//		table.dataSource = self
//		table.delegate = self
//	}
//	
//	
//	// OTHER METHODS	---
//	
//	func update(books: [Book])
//	{
//		self.books = books
//		table.selectRow(at: nil, animated: true, scrollPosition: .top)
//		table.reloadData()
//	}
//	
//	
//	// IMPLEMENTED METHODS	---
//	
//	func numberOfSections(in tableView: UITableView) -> Int
//	{
//		return 1
//	}
//	
//	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
//	{
//		return books.count
//	}
//	
//	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
//	{
//		let cell = tableView.dequeueReusableCell(withIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
//		cell.configure(text: books[indexPath.row].identifier)
//		
//		return cell
//	}
//	
//	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
//	{
//		delegate?.bookSelected(books[indexPath.row])
//	}
//}
//
//fileprivate protocol SelectBookTableControllerDelegate: class
//{
//	// This method is called when an existing book is selected
//	func bookSelected(_ book: Book)
//}
