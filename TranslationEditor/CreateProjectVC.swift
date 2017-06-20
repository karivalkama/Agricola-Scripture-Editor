//
//  CreateProjectVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 2.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is used for adding of new projects
class CreateProjectVC: UIViewController, FilteredSelectionDataSource, SimpleSingleSelectionViewDelegate
{
	// OUTLETS	---------------------
	
	@IBOutlet weak var projectNameField: UITextField!
	@IBOutlet weak var defaultBookIdentifierField: UITextField!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var selectLanguageView: SimpleSingleSelectionView!
	@IBOutlet weak var createProjectButton: BasicButton!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var projectNameStackView: UIStackView!
	@IBOutlet weak var translationNameStackView: UIStackView!
	@IBOutlet weak var contentStackView: SquishableStackView!
	@IBOutlet weak var inputStackView: SquishableStackView!
	
	
	// ATTRIBUTES	-----------------
	
	static let identifier = "CreateProject"
	
	private var newSharedAccount: AgricolaAccount?
	private var completion: ((Project?) -> ())?
	
	private var languages = [Language]()
	private var selectedLanguage: Language?
	private var languageName = ""
	
	
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
		
		contentView.configure(mainView: view, elements: [projectNameField, defaultBookIdentifierField, errorLabel, selectLanguageView, createProjectButton], topConstraint: contentTopConstraint, bottomConstraint: contentBottomConstraint, style: .squish, squishedElements: [contentStackView, inputStackView], switchedStackViews: [projectNameStackView, translationNameStackView])
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
		dismiss(animated: true, completion: { self.completion?(nil) })
	}
	
	@IBAction func backgroundButtonTapped(_ sender: Any)
	{
		dismiss(animated: true, completion: { self.completion?(nil) })
	}
	
	@IBAction func projectNameUpdated(_ sender: Any)
	{
		updateCreateButtonStatus()
	}
	
	@IBAction func translationNameUpdated(_ sender: Any)
	{
		updateCreateButtonStatus()
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
		
		guard !languageName.isEmpty else
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
			// May need to insert the language as a new instance
			var language: Language!
			if let selectedLanguage = selectedLanguage
			{
				language = selectedLanguage
			}
			else if let matchingLanguage = languages.first(where: { $0.name.lowercased().contains(languageName.lowercased()) })
			{
				language = matchingLanguage
			}
			else
			{
				language = try LanguageView.instance.language(withName: languageName.capitalized)
			}
			
			let project = Project(name: projectName, languageId: language.idString, ownerId: currentAccountId, contributorIds: [currentAccountId], defaultBookIdentifier: translationName, sharedAccountId: newSharedAccount?.idString)
			
			try DATABASE.tryTransaction
			{
				try self.newSharedAccount?.push()
				try project.push()
			}
			
			dismiss(animated: true, completion: { self.completion?(project) })
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
	
	func onValueChanged(_ newValue: String, selectedAt index: Int?)
	{
		languageName = newValue
		
		if let index = index
		{
			selectedLanguage = languages[index]
		}
		
		updateCreateButtonStatus()
	}
	
	
	// OTHER METHODS	---------
	
	func configure(completion: @escaping (Project?) -> ())
	{
		self.completion = completion
	}
	
	func configureForSharedAccountCreation(newAccount: AgricolaAccount, completion: ((Project?) -> ())? = nil)
	{
		self.newSharedAccount = newAccount
		self.completion = completion
	}
	
	private func updateCreateButtonStatus()
	{
		createProjectButton.isEnabled = !projectNameField.trimmedText.isEmpty && !defaultBookIdentifierField.trimmedText.isEmpty && !languageName.isEmpty
	}
}
