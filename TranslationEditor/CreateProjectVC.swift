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
	
	@IBAction func backgroundButtonTapped(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func createProjectPressed(_ sender: Any)
	{
		// Makes sure all the fields are filled
		guard let projectName = projectNameField.text, !projectName.isEmpty else
		{
			errorLabel.text = NSLocalizedString("Please provide a project name", comment: "An error displayed when required project name field is left empty")
			return
		}
		
		guard let defaultBookIdentifier = defaultBookIdentifierField.text, !defaultBookIdentifier.isEmpty else
		{
			errorLabel.text = NSLocalizedString("Please provide a default name for the translation", comment: "An error displayed when required translation name field is left empty")
			return
		}
		
		guard let accountName = accountNameField.text, !accountName.isEmpty else
		{
			errorLabel.text = NSLocalizedString("Please provide a name for the shared project account", comment: "An error displayed when required shared account name field is left empty")
			return
		}
		
		guard let password = passwordField.text, !password.isEmpty else
		{
			errorLabel.text = NSLocalizedString("Please provide a password for the shared project account", comment: "An error displayed when required password name field is left empty")
			return
		}
		
		guard let repeatedPassword = repeatPasswordField.text, !repeatedPassword.isEmpty else
		{
			errorLabel.text = NSLocalizedString("Please repeat the password you provided", comment: "An error message displayed when the required repeat password field is left empty")
			return
		}
		
		// Makes sure there is no existing account with a similar name
		do
		{
			guard try AccountView.instance.accountQuery(name: accountName).firstResultRow() == nil else
			{
				errorLabel.text = NSLocalizedString("There already exists an account with a similar name!", comment: "An error message displayed when there already exists an account that has the same name as the provided shared account name")
				return
			}
		}
		catch
		{
			errorLabel.text = NSLocalizedString("Internal error occurred", comment: "An error message displayed when project creation fails due to an unexpected error")
			print("ERROR: Failed to check if account exists. \(error)")
			return
		}
		
		// Makes sure the password is repeated correctly
		guard password == repeatedPassword else
		{
			errorLabel.text = NSLocalizedString("The passwords don't match!", comment: "An error message displayed when the provided account passwords don't match each other")
			repeatPasswordField.text = nil
			return
		}
		
		guard let selectedLanguage = selectedLanguage else
		{
			errorLabel.text = NSLocalizedString("Please select the target language", comment: "An error message when the user hasn't selected project language when trying to create a project")
			return
		}
		
		guard let currentAccountId = Session.instance.accountId else
		{
			errorLabel.text = NSLocalizedString("Cannot create project if not logged in!", comment: "An error message displayed when trying to create a new project without an account")
			print("ERROR: No account selected at create project")
			return
		}
		
		// Creates a new project with a project specific account
		do
		{
			// TODO: Add default book identifier field
			let projectAccount = AgricolaAccount(name: accountName, isShared: true, password: password, firstDevice: UIDevice.current.identifierForVendor?.uuidString)
			let project = Project(name: projectName, languageId: selectedLanguage.idString, ownerId: currentAccountId, contributorIds: [currentAccountId], defaultBookIdentifier: defaultBookIdentifier, sharedAccountId: projectAccount.idString)
			
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
}
