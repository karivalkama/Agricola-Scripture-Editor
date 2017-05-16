//
//  ImportBookVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is used for importing books from other projects
class ImportBookVC: UIViewController, UITableViewDataSource
{
	// OUTLETS	------------------
	
	@IBOutlet weak var languageFilterView: FilteredMultiSelection!
	@IBOutlet weak var bookFilterView: FilteredMultiSelection!
	@IBOutlet weak var bookSelectionTable: UITableView!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	
	
	// ATTRIBUTES	--------------
	
	private var books = [Book]()
	private var progress = [String: BookProgressStatus]()
	// Key = language id, value = language name
	private var languageNames = [String: String]()
	// Key = project id, value = project name
	private var projectNames = [String: String]()
	
	private var alreadyImportedIds = [String]()
	private var filterCodes = [BookCode]()
	private var filterLanguageIds = [String]()
	
	private var displayedOptions = [(book: Book, languageName: String, projectName: String, progress: BookProgressStatus?)]()
	
	
	// LOAD	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	
	// ACTIONS	------------------
	
	@IBAction func backButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
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
	
	
	// OTHER METHODS	----------
	
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
			else if !filterCodes.isEmpty && !filterCodes.contains(book.code)
			{
				return false
			}
			else if !filterLanguageIds.isEmpty && !filterLanguageIds.contains(book.languageId)
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
					return progressResult
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
}
