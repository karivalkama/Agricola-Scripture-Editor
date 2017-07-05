//
//  USXImportAlertVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 22.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

final class USXImport
{
	// ATTRIBUTES	-----------------
	
	static let instance = USXImport()
	
	fileprivate var parseSuccesses = [BookData]()
	fileprivate var parseFailures = [(fileName: String, message: String)]()
	fileprivate var parsedFileAmount = 0
	
	private var pendingURLs = [URL]()
	
	private weak var viewController: USXImportAlertVC?
	
	private var preparingToOpen = false
	private var receivedFilesWhileWaiting = false
	
	
	// INIT	-------------------------
	
	private init() {  } // Singular instance
	
	
	// OTHER METHODS	-------------
	
	func open(url: URL)
	{
		pendingURLs.add(url)
		
		if !preparingToOpen
		{
			preparingToOpen = true
			receivedFilesWhileWaiting = false
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1)
			{
				while self.receivedFilesWhileWaiting
				{
					self.receivedFilesWhileWaiting = false
					usleep(100000)
				}
				
				// TODO: This is not very thread safe still
				self.preparingToOpen = false
				_ = self.processPendingURLs()
			}
		}
		else
		{
			receivedFilesWhileWaiting = true
		}
	}
	
	// Returns whether usx import is open after this operation
	func processPendingURLs() -> Bool
	{
		guard !pendingURLs.isEmpty, let projectId = Session.instance.projectId, let avatarId = Session.instance.avatarId else
		{
			return false
		}
		
		let urlBuffer = pendingURLs
		pendingURLs = []
		
		for url in urlBuffer
		{
			parsedFileAmount += 1
			
			do
			{
				if let parser = XMLParser(contentsOf: url)
				{
					let parsedBooks = try parseUSX(parser: parser, projectId: projectId, avatarId: avatarId).filter { !$0.paragraphs.isEmpty }
					
					if parsedBooks.isEmpty
					{
						parseFailures.add((fileName: url.lastPathComponent, message: "No paragraph data found!"))
					}
					else
					{
						parseSuccesses.append(contentsOf: parsedBooks)
					}
				}
				else
				{
					parseFailures.add((fileName: url.lastPathComponent, message: "Couldn't create xml parser for file"))
				}
			}
			catch
			{
				var message = "Internal Error"
				
				if let error = error as? USXParseError
				{
					switch error
					{
					case .verseIndexNotFound: message = "A verse number is missing"
					case .verseIndexParsingFailed: message = "Verse number parsing failed"
					case .verseRangeParsingFailed: message = "Verse range parsing failed"
					case .chapterIndexNotFound: message = "No chapter marker found"
					case .bookNameNotSpecified: message = "No book name found"
					case .bookCodeNotFound: message = "Book code is missing"
					case .attributeMissing: message = "Required usx-attribute is missing"
					case .unknownNoteStyle: message = "Unrecognized note style"
					}
				}
				
				parseFailures.add((fileName: url.lastPathComponent, message: message))
			}
		}
		
		// Either displays or updates the view controller to show the new data
		if let viewController = viewController//, viewController.isBeingPresented
		{
			//print("STATUS: Updates existing VC")
			viewController.update()
		}
		else if let topVC = getTopmostVC()
		{
			topVC.displayAlert(withIdentifier: USXImportAlertVC.identifier, storyBoardId: "Common")
			{
				self.viewController = $0 as? USXImportAlertVC
			}
			
			//print("STATUS: Saved VC \(viewController == nil ? "Not Found" : "Found")")
		}
		
		return true
	}
	
	fileprivate func discardData()
	{
		pendingURLs = []
		parseSuccesses = []
		parseFailures = []
		parsedFileAmount = 0
	}
	
	fileprivate func close()
	{
		discardData()
		viewController?.dismiss(animated: true, completion: nil)
	}
	
	private func parseUSX(parser: XMLParser, projectId: String, avatarId: String) throws -> [BookData]
	{
		// Language is set afterwards
		let usxParserDelegate = USXParser(projectId: projectId, userId: avatarId, languageId: "")
		parser.delegate = usxParserDelegate
		parser.parse()
		
		guard usxParserDelegate.success else
		{
			throw usxParserDelegate.error!
		}
		
		return usxParserDelegate.parsedBooks
	}
	
	private func getTopmostVC() -> UIViewController?
	{
		guard let app = UIApplication.shared.delegate, let rootViewController = app.window??.rootViewController else
		{
			return nil
		}
		
		var currentController = rootViewController
		while let presentedController = currentController.presentedViewController
		{
			currentController = presentedController
		}
		
		return currentController
	}
}

// This view controller is used for parsing and presenting an overview of incoming usx file data
class USXImportAlertVC: UIViewController, UITableViewDataSource, LanguageSelectionHandlerDelegate, FilteredSelectionDataSource, SimpleSingleSelectionViewDelegate
{
	// OUTLETS	---------------------
	
	@IBOutlet weak var fileAmountLabel: UILabel!
	@IBOutlet weak var dataTableView: UITableView!
	@IBOutlet weak var selectLanguageView: SimpleSingleSelectionView!
	@IBOutlet weak var selectNicknameField: SimpleSingleSelectionView!
	@IBOutlet weak var overwriteInfoLabel: UILabel!
	@IBOutlet weak var inputStackView: UIStackView!
	@IBOutlet weak var previewSwitch: UISwitch!
	@IBOutlet weak var okButton: BasicButton!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var previewSwitchStackView: UIStackView!
	@IBOutlet weak var selectionStackView: UIStackView!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var nicknameStackView: UIStackView!
	@IBOutlet weak var isTargetTranslationSwitch: UISwitch!
	@IBOutlet weak var isTargetTranslationStackView: UIStackView!
	@IBOutlet weak var stateView: StatefulStackView!
	
	
	// ATTRIBUTES	-----------------
	
	static let identifier = "USXImportAlert"
	
	private var existingBooks = [Book]()
	private var existingResources = [ResourceCollection]()
	private var existingNicknames = [String]()
	
	private var languageHandler = LanguageSelectionHandler()
	
	private var selectedNickName: String?
	private var newNickname = ""
	
	private var identifierFoundForAll = false
	private var targetLanguageSelected = false
	
	// TODO: Removed the feature that there could be target language resources. It may be added back later (main menu and other features don't support it yet)
	
	
	// COMPUTED PROPERTIES	---------
	
	var numberOfOptions: Int { return existingNicknames.count }
	
	private var containsSuccesses: Bool { return !USXImport.instance.parseSuccesses.isEmpty }
	
	private var containsFailures: Bool { return !USXImport.instance.parseFailures.isEmpty }
	
	private var sectionForSuccess: Int?
	{
		if containsSuccesses
		{
			return containsFailures ? 1 : 0
		}
		else
		{
			return nil
		}
	}
	
	private var sectionForFailure: Int? { return containsFailures ? 0 : nil }
	
	
	// LOAD	-------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		contentView.configure(mainView: view, elements: [fileAmountLabel, dataTableView, selectLanguageView, selectNicknameField, previewSwitch, okButton], topConstraint: contentTopConstraint, bottomConstraint: contentBottomConstraint, style: .squish, switchedStackViews: [inputStackView])
		
		stateView.register(inputStackView, for: .data)
		stateView.registerDefaultLoadingView(title: "Processing...")
		stateView.setState(.loading)
		
		dataTableView.dataSource = self
		selectLanguageView.datasource = languageHandler
		selectLanguageView.delegate = languageHandler
		selectNicknameField.datasource = self
		selectNicknameField.delegate = self
		
		selectLanguageView.setIntrinsicHeight(160)
		selectNicknameField.setIntrinsicHeight(160)
		
		languageHandler.delegate = self
		
		updateNicknameVisibility()
		// update()
    }
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		contentView.startKeyboardListening()
		
		do
		{
			try languageHandler.updateLanguageOptions()
			selectLanguageView.reloadData()
			
			if let projectId = Session.instance.projectId
			{
				existingBooks = try ProjectBooksView.instance.booksQuery(projectId: projectId).resultObjects()
				existingResources = try ResourceCollectionView.instance.collectionQuery(projectId: projectId).resultObjects().filter { $0.category == .sourceTranslation }
				updateNickNames()
				update()
				
				selectNicknameField.reloadData()
			}
		}
		catch
		{
			print("ERROR: USX Import setup failed. \(error)")
		}
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		contentView.endKeyboardListening()
	}
	
	
	// ACTIONS	---------------------
	
	@IBAction func targetTranslationSwitchPressed(_ sender: Any)
	{
		nicknameStackView.isHidden = isTargetTranslationSwitch.isOn
		updateOKButtonStatus()
	}
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		// TODO: Keep data in buffer?
		USXImport.instance.close()
	}
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		USXImport.instance.close()
	}
	
	@IBAction func okButtonPressed(_ sender: Any)
	{
		stateView.setState(.loading)
		
		do
		{
			// Language id is required if not all of the books were matched with identifier
			guard let languageId = identifierFoundForAll ? "" : try languageHandler.getOrInsertLanguage()?.idString else
			{
				print("ERROR: No language selected")
				stateView.setState(.data)
				return
			}
			
			guard identifierFoundForAll || targetLanguageSelected || !newNickname.isEmpty else
			{
				print("ERROR: No nickname selected")
				stateView.setState(.data)
				return
			}
			
			// Versions with an existing identifier are always overwritten
			var booksToOverwrite = [(oldBook: Book, newBookData: BookData)]()
			var remainingBooks = [BookData]()
			
			for bookData in USXImport.instance.parseSuccesses
			{
				if let oldVersion = oldVersion(for: bookData.book)
				{
					booksToOverwrite.add((oldBook: oldVersion, newBookData: bookData))
				}
				else
				{
					remainingBooks.add(bookData)
				}
			}
			
			var booksToInsert = [BookData]()
			
			// If writing target translation, overwrites existing books based on code, inserts the rest
			if targetLanguageSelected
			{
				guard let projectId = Session.instance.projectId, let project = try Project.get(projectId) else
				{
					print("Error: No project data available")
					stateView.errorOccurred(title: "Import Process Failed", description: "There is no project data available", canContinueWithData: false)
					return
				}
				
				for bookData in remainingBooks
				{
					if let oldVersion = try project.targetTranslationQuery(bookCode: bookData.book.code).firstResultObject()
					{
						booksToOverwrite.add((oldBook: oldVersion, newBookData: bookData))
					}
					else
					{
						booksToInsert.add(bookData)
					}
				}
			}
			// If a nickname was selected, also overwrites any books with the provided nickname (+ language + code)
			else if selectedNickName != nil
			{
				let associatedResources = existingResources.filter { $0.name == newNickname && $0.languageId == languageId }
				let associatedSources = try associatedResources.flatMap { try ParagraphBinding.get(resourceCollectionId: $0.idString) }.flatMap { try Book.get($0.sourceBookId) }
				
				for bookData in remainingBooks
				{
					if let oldVersion = associatedSources.first(where: { $0.code == bookData.book.code })
					{
						booksToOverwrite.add((oldBook: oldVersion, newBookData: bookData))
					}
					else
					{
						booksToInsert.add(bookData)
					}
				}
			}
			// Otherwise inserts all remaining books as new
			else
			{
				booksToInsert = remainingBooks
			}
			
			// Presents a preview or just imports all the books
			if previewSwitch.isOn
			{
				displayAlert(withIdentifier: USXImportPreviewVC.idedntifier, storyBoardId: "Common")
				{
					($0 as! USXImportPreviewVC).configure(translationName: self.newNickname, languageId: languageId, booksToOverwrite: booksToOverwrite, booksToInsert: booksToInsert, completion: USXImport.instance.close)
				}
			}
			else
			{
				try booksToOverwrite.forEach { try USXImportPreviewVC.overwrite(oldBook: $0.oldBook, newData: $0.newBookData) }
				booksToInsert.forEach { USXImportPreviewVC.insert(bookData: $0, languageId: languageId, nickName: self.newNickname, hostVC: self) }
				USXImport.instance.close()
			}
		}
		catch
		{
			print("ERROR: USX Import failed. \(error)")
			stateView.errorOccurred(title: "USX Import Failed!", description: "An unexpected internal error caused the import process to (partially) fail", canContinueWithData: false)
		}
	}
	
	
	// IMPLEMENTED METHODS	---------
	
	func numberOfSections(in tableView: UITableView) -> Int
	{
		if containsFailures
		{
			return containsSuccesses ? 2 : 1
		}
		else
		{
			return containsSuccesses ? 1 : 0
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if section == sectionForFailure
		{
			return USXImport.instance.parseFailures.count
		}
		else
		{
			return USXImport.instance.parseSuccesses.count
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		if indexPath.section == sectionForFailure
		{
			let cell = tableView.dequeueReusableCell(withIdentifier: ParseFailCell.identifier, for: indexPath) as! ParseFailCell
			let failureData = USXImport.instance.parseFailures[indexPath.row]
			cell.configure(fileName: failureData.fileName, errorDescription: failureData.message)
			return cell
		}
		else
		{
			let cell = tableView.dequeueReusableCell(withIdentifier: ParseSuccessCell.identifier, for: indexPath) as! ParseSuccessCell
			let book = USXImport.instance.parseSuccesses[indexPath.row].book
			cell.configure(code: book.code, identifier: book.identifier, didFindOlderVersion: oldVersion(for: book) != nil)
			return cell
		}
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		if section == sectionForFailure
		{
			return NSLocalizedString("Failed Cases", comment: "A table heading for failed usx-import cases")
		}
		else
		{
			return NSLocalizedString("Success Cases", comment: "A table heading for succesfull usx-import cases")
		}
	}
	
	func languageSelectionHandler(_ selectionHandler: LanguageSelectionHandler, newLanguageNameInserted languageName: String)
	{
		// print("STATUS: Inserted \(languageName)")
		
		updateNickNames()
		updateNicknameVisibility()
		updateOKButtonStatus()
	}
	
	func languageSelectionHandler(_ selectionHandler: LanguageSelectionHandler, languageSelected: Language)
	{
		// print("STATUS: Selected \(languageSelected.name)")
		
		updateNickNames()
		updateNicknameVisibility()
		updateOKButtonStatus()
	}
	
	func labelForOption(atIndex index: Int) -> String
	{
		return existingNicknames[index]
	}
	
	func onValueChanged(_ newValue: String, selectedAt index: Int?)
	{
		newNickname = newValue
		selectedNickName = index.map { existingNicknames[$0] }
		updateOKButtonStatus()
		
		overwriteInfoLabel.isHidden = selectedNickName == nil
	}
	
	
	// OTHER METHODS	-------------
	
	fileprivate func update()
	{
		dataTableView.reloadData()
		
		// Sets some elements hidden / visible if successful parsing was done
		let hasSuccesses = !USXImport.instance.parseSuccesses.isEmpty
		previewSwitchStackView.isHidden = !hasSuccesses
		
		// Language and nickname selection are also disabled when all books are already recognized
		identifierFoundForAll = USXImport.instance.parseSuccesses.forAll { oldVersion(for: $0.book) != nil }
		selectionStackView.isHidden = !hasSuccesses || identifierFoundForAll
		
		fileAmountLabel.text = "\(USXImport.instance.parsedFileAmount) \(NSLocalizedString("File(s)", comment: "A label presented next to the amount of parsed files in usx import view"))"
		
		updateOKButtonStatus()
		
		stateView.dataLoaded()
	}
	
	private func updateNicknameVisibility()
	{
		targetLanguageSelected = false // default
		//print("STATUS: Updating nick name visibility")
		
		// While language is not selected, just displays the language selection
		if languageHandler.isEmpty
		{
			nicknameStackView.isHidden = true
			// isTargetTranslationStackView.isHidden = true
		}
		else
		{
			do
			{
				// If the selected language is the same as the project language, the role of the books is specified via switch
				if let selectedLanguageId = languageHandler.selectedLanguage?.idString, let projectId = Session.instance.projectId, let project = try Project.get(projectId), project.languageId == selectedLanguageId
				{
					//print("STATUS: Target language selected")
					//isTargetTranslationStackView.isHidden = false
					//nicknameStackView.isHidden = isTargetTranslationSwitch.isOn
					targetLanguageSelected = true
					nicknameStackView.isHidden = true
				}
				else
				{
					//print("STATUS: Shows nickname field")
					// If another language or a new language was selected, displays the nickname field for the resource
					// isTargetTranslationSwitch.isHidden = true
					nicknameStackView.isHidden = false
				}
			}
			catch
			{
				//print("ERROR: Couldn't read project data. \(error)")
				// isTargetTranslationSwitch.isHidden = true
				nicknameStackView.isHidden = false
			}
		}
	}
	
	private func oldVersion(for book: Book) -> Book?
	{
		return existingBooks.first(where: { $0.code == book.code && $0.identifier == book.identifier })
	}
	
	private func updateNickNames()
	{
		if let selectedLanguageId = languageHandler.selectedLanguage?.idString
		{
			existingNicknames = existingResources.filter { $0.languageId == selectedLanguageId }.map { $0.name }.withoutDuplicates
			// print("STATUS: Found nicknames for \(selectedLanguageId):\(existingNicknames.reduce("", { $0 + " " + $1 }))")
		}
		else
		{
			existingNicknames = []
			// print("STATUS: New language -> No nicknames")
		}
		
		selectNicknameField.reloadData()
	}
	
	private func updateOKButtonStatus()
	{
		// For OK-button to be enabled, one must have at least a single successful parse
		// Language and nickname must both be set (non-empty) as well (if they are visible)
		okButton.isEnabled = !USXImport.instance.parseSuccesses.isEmpty && (identifierFoundForAll || (!languageHandler.isEmpty && (targetLanguageSelected || !newNickname.isEmpty)))
	}
}
