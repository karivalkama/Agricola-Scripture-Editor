//
//  ImportBookVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.5.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This view controller is used for importing books from other projects
class ImportBookVC: UIViewController, UITableViewDataSource, LiveQueryListener, UITableViewDelegate
{
	// OUTLETS	------------------
	
	@IBOutlet weak var bookSelectionTable: UITableView!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var topBar: TopBarUIView!
	@IBOutlet weak var languageFilterField: UITextField!
	@IBOutlet weak var bookFilterField: UITextField!
	@IBOutlet weak var bookDataStackView: StatefulStackView!
	
	
	// TYPES	------------------
	
	typealias QueryTarget = ProjectBooksView
	
	
	// ATTRIBUTES	--------------
	
	private var books = [Book]()
	// Key = book id, value = book progress
	private var progress = [String: BookProgressStatus]()
	// Key = language id, value = language name
	private var languageNames = [String: String]()
	// Key = project id, value = project name
	private var projectNames = [String: String]()
	
	private var alreadyImportedIds = [String]()
	private var languageFilter: String?
	private var bookFilter: String?
	
	private var importedIdsLoaded = false
	private var booksLoaded = false
	
	private var displayedOptions = [(book: Book, languageName: String, projectName: String, progress: BookProgressStatus?)]()
	
	private var bookQueryManager: LiveQueryManager<ProjectBooksView>?
	private var resourceQueryManager: LiveQueryManager<ResourceCollectionView>?
	
	
	// LOAD	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		topBar.configure(hostVC: self, title: "Import Book", leftButtonText: "Cancel", leftButtonAction: { self.dismiss(animated: true, completion: nil) })
		
		bookSelectionTable.dataSource = self
		bookSelectionTable.delegate = self
		
		contentView.configure(mainView: view, elements: [languageFilterField, bookFilterField], topConstraint: contentTopConstraint, bottomConstraint: contentBottomConstraint, style: .squish)
		
		bookDataStackView.register(bookSelectionTable, for: .data)
		bookDataStackView.setState(.loading)
		
		let noDataView = ConnectPromptNoDataView()
		noDataView.title = "No Books to Import"
		noDataView.hint = "Connect with people from other projects to make the data available"
		noDataView.connectButtonAction = { [weak self] in self?.topBar.performConnect(using: self!) }
		bookDataStackView.register(noDataView, for: .empty)
		
		guard let projectId = Session.instance.projectId else
		{
			print("ERROR: No project selected")
			bookDataStackView.errorOccurred()
			return
		}
		
		bookQueryManager = ProjectBooksView.instance.createQuery().liveQueryManager
		resourceQueryManager = ResourceCollectionView.instance.collectionQuery(projectId: projectId).liveQueryManager
    }
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		bookQueryManager?.addListener(AnyLiveQueryListener(self))
		bookQueryManager?.start()
		
		resourceQueryManager?.addListener(calling: resourceRowsUpdated)
		resourceQueryManager?.start()
		
		// Updates the book progress data (asynchronous)
		DispatchQueue.main.async
		{
			do
			{
				self.progress = try BookProgressView.instance.progressForAllBooks()
				self.update()
			}
			catch
			{
				print("ERROR: Failed to retrieve book progress data. \(error)")
			}
		}
		
		contentView.startKeyboardListening()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		bookQueryManager?.stop()
		bookQueryManager?.removeListeners()
		
		resourceQueryManager?.stop()
		resourceQueryManager?.removeListeners()
		
		contentView.endKeyboardListening()
	}
	
	
	// ACTIONS	------------------
    
	@IBAction func languageFilterChanged(_ sender: Any)
	{
		languageFilter = filterFromField(languageFilterField)
		update()
	}
	
	@IBAction func bookFilterChanged(_ sender: Any)
	{
		bookFilter = filterFromField(bookFilterField)
		update()
	}
	

	// IMPLEMENTED METHODS	------
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return displayedOptions.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: ImportBookCell.identifier, for: indexPath) as! ImportBookCell
		
		let data = displayedOptions[indexPath.row]
		cell.configure(languageName: data.languageName, code: data.book.code, identifier: data.book.identifier, projectName: data.projectName, progress: data.progress)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		let book = displayedOptions[indexPath.row].book
		displayAlert(withIdentifier: ImportBookPreviewVC.identifier, storyBoardId: "MainMenu")
		{
			vc in (vc as! ImportBookPreviewVC).configure(bookToImport: book)
			{
				if $0
				{
					self.dismiss(animated: true, completion: nil)
				}
			}
		}
	}
	
	func rowsUpdated(rows: [Row<ProjectBooksView>])
	{
		do
		{
			books = try rows.map { try $0.object() }
			booksLoaded = true
			
			if importedIdsLoaded
			{
				updateDataState()
			}
		}
		catch
		{
			print("ERROR: Failed to read through book data. \(error)")
			bookDataStackView.errorOccurred()
		}
	}
	
	
	// OTHER METHODS	----------
	
	private func resourceRowsUpdated(rows: [Row<ResourceCollectionView>])
	{
		do
		{
			alreadyImportedIds = try rows.compactMap { $0.id }.compactMap { try ParagraphBinding.get(resourceCollectionId: $0)?.sourceBookId }
			importedIdsLoaded = true
			
			if booksLoaded
			{
				updateDataState()
			}
		}
		catch
		{
			print("ERROR: Failed to read through imported resource data. \(error)")
			bookDataStackView.errorOccurred()
		}
	}
	
	private func updateDataState()
	{
		if books.map({ $0.idString }).forAll({ alreadyImportedIds.contains($0) })
		{
			// If no new books were found, displays the no data -view
			bookDataStackView.dataLoaded(isEmpty: true)
		}
		else
		{
			bookDataStackView.dataLoaded()
			update()
		}
	}
	
	private func update()
	{
		guard let projectId = Session.instance.projectId else
		{
			print("ERROR: Project must be selected at this point")
			return
		}
		
		// First filters the books with projectId, code and language filters
		// Also exludes the books that have already been imported
		let filteredBooks = books.filter
		{
			book in
			
			if book.projectId == projectId
			{
				return false
			}
			else if languageFilter != nil && !((try? nameOfLanguage(withId: book.languageId).lowercased().contains(languageFilter!)) ?? false)
			{
				return false
			}
			else if bookFilter != nil && !book.code.code.lowercased().contains(bookFilter!) && !book.code.name.lowercased().contains(bookFilter!)
			{
				return false
			}
			else if alreadyImportedIds.contains(book.idString)
			{
				return false
			}
			else
			{
				return true
			}
		}
		
		do
		{
			// Maps data for the books
			displayedOptions = try filteredBooks.map { return (book: $0, languageName: try nameOfLanguage(withId: $0.languageId), projectName: try nameOfProject(withId: $0.projectId), progress: progress[$0.idString]) }
			
			// Sorts the data (language -> code -> progress -> project name -> identifier)
			displayedOptions.sort
			{
				(first, second) in
				
				if let baseInfoResult = first.languageName.compare(with: second.languageName) ?? first.book.code.compare(with: second.book.code)
				{
					return baseInfoResult
				}
				else if let firstProgress = first.progress, let secondProgress = second.progress, let progressResult = firstProgress.compare(with: secondProgress)
				{
					return !progressResult
				}
				else
				{
					return first.projectName.compare(with: second.projectName) ?? first.book.identifier.compare(with: second.book.identifier) ?? false
				}
			}
			
			bookSelectionTable.reloadData()
		}
		catch
		{
			print("ERROR: Failed to update available book selection. \(error)")
		}
	}
	
	private func nameOfLanguage(withId languageId: String) throws -> String
	{
		if let existingName = languageNames[languageId]
		{
			return existingName
		}
		else if let language = try Language.get(languageId)
		{
			languageNames[languageId] = language.name
			return language.name
		}
		else
		{
			return ""
		}
	}
	
	private func nameOfProject(withId projectId: String) throws -> String
	{
		if let existingName = projectNames[projectId]
		{
			return existingName
		}
		else if let project = try Project.get(projectId)
		{
			projectNames[projectId] = project.name
			return project.name
		}
		else
		{
			return ""
		}
	}
	
	private func filterFromField(_ field: UITextField) -> String?
	{
		let filter = field.text?.lowercased().trimmingCharacters(in: CharacterSet.whitespaces)
		
		if filter == nil || filter!.isEmpty
		{
			return nil
		}
		else
		{
			return filter
		}
	}
	
	/*
	private func importBook(_ book: Book) -> Bool
	{
		do
		{
			// The new book cannot contain any conflicts in order to be imported
			guard try !ParagraphHistoryView.instance.rangeContainsConflicts(bookId: book.idString) else
			{
				displayAlert(withIdentifier: "ErrorAlert", storyBoardId: "MainMenu")
				{
					vc in
					
					if let errorVC = vc as? ErrorAlertVC
					{
						errorVC.configure(heading: "Conflicts in Selected Book", text: "The selected book, \(book.code): \(book.identifier) contains conflicts and cannot be imported at this time.")
					}
				}
				return false
			}
			
			guard let projectId = Session.instance.projectId, let project = try Project.get(projectId) else
			{
				print("ERROR: No project to insert a book into.")
				return false
			}
			
			let targetTranslations = try project.targetTranslationQuery(bookCode: book.code).resultObjects()
			
			// Makes sure there are no conflicts within the target translations
			guard try targetTranslations.forAll({ try !ParagraphHistoryView.instance.rangeContainsConflicts(bookId: $0.idString) }) else
			{
				displayAlert(withIdentifier: "ErrorAlert", storyBoardId: "MainMenu")
				{
					vc in
					
					if let errorVC = vc as? ErrorAlertVC
					{
						errorVC.configure(heading: "Conflicts in Target Translation", text: "Target translation of \(book.code) contains conflicts. Please resolve those conlicts first and then try again.")
					}
				}
				
				return false
			}
			
			guard let avatarId = Session.instance.avatarId else
			{
				print("ERROR: Avatar must be selected before data can be saved")
				return false
			}
			
			// Updates bindings for each of the target translations
			var newResources = [ResourceCollection]()
			var newBindings = [ParagraphBinding]()
			
			for targetTranslation in targetTranslations
			{
				let resource = ResourceCollection(languageId: book.languageId, bookId: targetTranslation.idString, category: .sourceTranslation, name: bookNameField.trimmedText)
				let bindings = match(try ParagraphView.instance.latestParagraphQuery(bookId: book.idString).resultObjects(), and: try ParagraphView.instance.latestParagraphQuery(bookId: targetTranslation.idString).resultObjects()).map { ($0.source.idString, $0.target.idString) }
				
				newResources.add(resource)
				newBindings.add(ParagraphBinding(resourceCollectionId: resource.idString, sourceBookId: book.idString, targetBookId: targetTranslation.idString, bindings: bindings, creatorId: avatarId))
			}
			
			if !newResources.isEmpty
			{
				try DATABASE.tryTransaction
				{
					try newResources.forEach { try $0.push() }
					try newBindings.forEach { try $0.push() }
				}
			}
			
			// If there is no target translation for the book already, creates one by making an empty copy
			if targetTranslations.isEmpty
			{
				_ = try book.makeEmptyCopy(projectId: projectId, identifier: project.defaultBookIdentifier, languageId: project.languageId, userId: avatarId, resourceName: bookNameField.trimmedText)
			}
			
			return true
		}
		catch
		{
			print("ERROR: Book import failed. \(error)")
			return false
		}
	}
*/
}

/*
fileprivate protocol LanguageFilterDelegate: class
{
	func onLanguageFilterChange(languageFilter: [String])
}

fileprivate class LanguageFilterManager: FilteredSelectionDataSource, FilteredMultiSelectionDelegate
{
	// ATTRIBUTES	-------------
	
	private let languages: [Language]
	weak var delegate: LanguageFilterDelegate?
	
	
	// COMPUTED PROPERTIES	----
	
	var numberOfOptions: Int { return languages.count }
	
	
	// INIT	---------------------
	
	init(languages: [Language])
	{
		self.languages = languages
	}
	
	
	// IMPLEMENTED METHODS	-----
	
	func labelForOption(atIndex index: Int) -> String
	{
		return languages[index].name
	}
	
	func onSelectionChange(selectedIndices: [Int])
	{
		delegate?.onLanguageFilterChange(languageFilter: selectedIndices.map { languages[$0].idString })
	}
}

fileprivate protocol BookFilterDelegate: class
{
	func onBookFilterChange(bookFilter: [BookCode])
}

fileprivate class BookFilterManager: FilteredSelectionDataSource, FilteredMultiSelectionDelegate
{
	// ATTRIBUTES	-----------
	
	private let codes = BookCode.oldTestamentBooks + BookCode.newTestamentBooks
	weak var delegate: BookFilterDelegate?
	
	
	// COMPUTED PROPERTIES	---
	
	var numberOfOptions: Int { return codes.count }
	
	
	// IMPLEMENTED METHODS	---
	
	func labelForOption(atIndex index: Int) -> String
	{
		return codes[index].description
	}
	
	func onSelectionChange(selectedIndices: [Int])
	{
		delegate?.onBookFilterChange(bookFilter: selectedIndices.map { codes[$0] })
	}
}
*/
