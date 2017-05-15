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
	@IBOutlet weak var accountNameField: UITextField!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var repeatPasswordField: UITextField!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var selectLanguageView: FilteredSingleSelection!
	@IBOutlet weak var createProjectButton: BasicButton!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	
	
	// ATTRIBUTES	-----------------
	
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
		
		// Loads the language data
		do
		{
			languages = try LanguageView.instance.createQuery().resultObjects()
		}
		catch
		{
			print("ERROR: Failed to load language data. \(error)")
		}
		
		selectLanguageView.delegate = self
		selectLanguageView.datasource = self
		selectLanguageView.reloadData()
		
		contentView.configure(mainView: view, elements: [projectNameField, defaultBookIdentifierField, accountNameField, passwordField, repeatPasswordField, errorLabel, selectLanguageView, createProjectButton], topConstraint: contentTopConstraint)
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
	}

	
	// ACTIONS	---------------------
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func createProjectPressed(_ sender: Any)
	{
		// Makes sure all the fields are filled
		guard let projectName = projectNameField.text, !projectName.isEmpty else
		{
			errorLabel.text = "Please provide a project name"
			return
		}
		
		guard let defaultBookIdentifier = defaultBookIdentifierField.text, !defaultBookIdentifier.isEmpty else
		{
			errorLabel.text = "Please provide a default name for the translation"
			return
		}
		
		guard let accountName = accountNameField.text, !accountName.isEmpty else
		{
			errorLabel.text = "Please provide a name for the shared project account"
			return
		}
		
		guard let password = passwordField.text, !password.isEmpty else
		{
			errorLabel.text = "Please provide a password for the shared project account"
			return
		}
		
		guard let repeatedPassword = repeatPasswordField.text, !repeatedPassword.isEmpty else
		{
			errorLabel.text = "Please repeat the password you provided"
			return
		}
		
		// Makes sure there is no existing account with a similar name
		do
		{
			guard try AccountView.instance.accountQuery(name: accountName).firstResultRow() == nil else
			{
				errorLabel.text = "There already exists an account with a similar name!"
				return
			}
		}
		catch
		{
			errorLabel.text = "Internal error occurred"
			print("ERROR: Failed to check if account exists. \(error)")
			return
		}
		
		// Makes sure the password is repeated correctly
		guard password == repeatedPassword else
		{
			errorLabel.text = "The passwords don't match!"
			repeatPasswordField.text = nil
			return
		}
		
		guard let selectedLanguage = selectedLanguage else
		{
			errorLabel.text = "Please select the target language"
			return
		}
		
		guard let currentAccountId = Session.instance.accountId else
		{
			errorLabel.text = "Cannot create project if not logged in!"
			print("ERROR: No account selected at create project")
			return
		}
		
		// Creates a new project with a project specific account
		do
		{
			// TODO: Add default book identifier field
			let projectAccount = AgricolaAccount(name: accountName, isShared: true, password: password, firstDevice: UIDevice.current.identifierForVendor?.uuidString)
			let project = Project(name: projectName, languageId: selectedLanguage.idString, ownerId: currentAccountId, contributorIds: [currentAccountId], sharedAccountId: projectAccount.idString, defaultBookIdentifier: defaultBookIdentifier)
			
			try DATABASE.tryTransaction
			{
				try projectAccount.push()
				try project.push()
			}
			
			dismiss(animated: true, completion: nil)
		}
		catch
		{
			print("ERROR: Failed to create project. \(error)")
			errorLabel.text = "Internal error occurred!"
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
}
