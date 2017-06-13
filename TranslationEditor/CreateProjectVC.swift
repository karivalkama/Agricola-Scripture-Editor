//
//  CreateProjectVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 2.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is used for adding of new projects
class CreateProjectVC: UIViewController, FilteredSelectionDataSource, FilteredSingleSelectionDelegate
{
	// OUTLETS	---------------------
	
	@IBOutlet weak var projectNameField: UITextField!
	@IBOutlet weak var defaultBookIdentifierField: UITextField!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var selectLanguageView: FilteredSingleSelection!
	@IBOutlet weak var createProjectButton: BasicButton!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	
	
	// ATTRIBUTES	-----------------
	
	static let identifier = "CreateProject"
	
	private var newSharedAccount: AgricolaAccount?
	private var completion: ((Bool) -> ())?
	
	private var languages = [Language]()
	private var selectedLanguage: Language?
	
	
	// COMPUTED PROPERTIES	---------
	
	var numberOfOptions: Int { return languages.count }
	
	
	// LOAD	-------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		errorLabel.text = nil
		createProjectButton.isEnabled = false
		
		selectLanguageView.delegate = self
		selectLanguageView.datasource = self
		
		contentView.configure(mainView: view, elements: [projectNameField, defaultBookIdentifierField, errorLabel, selectLanguageView, createProjectButton], topConstraint: contentTopConstraint)
    }
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		// Loads the language data
		do
		{
			languages = try LanguageView.instance.createQuery().resultObjects()
			selectLanguageView.reloadData()
		}
		catch
		{
			print("ERROR: Failed to load language data. \(error)")
		}
	}
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		contentView.startKeyboardListening()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		contentView.endKeyboardListening()
		
		languages = []
	}

	
	// ACTIONS	---------------------
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: { self.completion?(false) })
	}
	
	@IBAction func backgroundButtonTapped(_ sender: Any)
	{
		dismiss(animated: true, completion: { self.completion?(false) })
	}
	
	@IBAction func createProjectPressed(_ sender: Any)
	{
		// Makes sure all the fields are filled
		let projectName = projectNameField.trimmedText
		let translationName = defaultBookIdentifierField.trimmedText
		
		guard !projectName.isEmpty && !translationName.isEmpty else
		{
			errorLabel.text = NSLocalizedString("Please fill all required fields", comment: "An error displayed when some required fields are left empty")
			return
		}
		
		guard let selectedLanguage = selectedLanguage else
		{
			errorLabel.text = NSLocalizedString("Please select the target language", comment: "An error message when the user hasn't selected project language when trying to create a project")
			return
		}
		
		guard let currentAccountId = Session.instance.accountId ?? newSharedAccount?.idString else
		{
			errorLabel.text = NSLocalizedString("Cannot create project if not logged in!", comment: "An error message displayed when trying to create a new project without an account")
			print("ERROR: No account selected at create project")
			return
		}
		
		// Creates a new project and sasves the project account, if applicable
		do
		{
			let project = Project(name: projectName, languageId: selectedLanguage.idString, ownerId: currentAccountId, contributorIds: [currentAccountId], defaultBookIdentifier: translationName, sharedAccountId: newSharedAccount?.idString)
			
			try DATABASE.tryTransaction
			{
				try self.newSharedAccount?.push()
				try project.push()
			}
			
			dismiss(animated: true, completion: { self.completion?(true) })
		}
		catch
		{
			print("ERROR: Failed to create project. \(error)")
			errorLabel.text = NSLocalizedString("Internal error occurred!", comment: "An error message displayed when project creation fails due to an unexpected error")
			return
		}
	}
	
	
	// IMPLEMENTED METHODS	--------
	
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
		createProjectButton.isEnabled = true
		selectedLanguage = languages[index]
	}
	
	func insertItem(named: String) -> Int?
	{
		// Checks if there already exists a language with the same name
		if let existingIndex = languages.index(where: { $0.name.lowercased() == named })
		{
			return existingIndex
		}
		else
		{
			do
			{
				let newLanguage = try LanguageView.instance.language(withName: named)
				languages.add(newLanguage)
				return languages.count - 1
			}
			catch
			{
				print("ERROR: Failed to insert a new language. \(error)")
				return nil
			}
		}
	}
	
	
	// OTHER METHODS	---------
	
	func configureForSharedAccountCreation(newAccount: AgricolaAccount, completion: ((Bool) -> ())? = nil)
	{
		self.newSharedAccount = newAccount
		self.completion = completion
	}
}
