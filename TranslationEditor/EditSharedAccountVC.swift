//
//  EditSharedAccountVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is used for creation / password change of the shared project account
class EditSharedAccountVC: UIViewController
{
	// OUTLETS	-------------------
	
	@IBOutlet weak var accountNameField: UITextField!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var repeatPasswordField: UITextField!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var okButton: BasicButton!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	
	
	// ATTRIBUTES	---------------
	
	static let identifier = "EditSharedAccountVC"
	
	private var project: Project!
	private var editedAccount: AgricolaAccount?
	
	
	// LOAD	-----------------------
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		contentView.configure(mainView: view, elements: [accountNameField, passwordField, repeatPasswordField, okButton])
	}
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		// Finds shared account data for edit, if there is one
		do
		{
			if let projectId = Session.instance.projectId, let project = try Project.get(projectId)
			{
				self.project = project
				
				if let sharedAccountId = project.sharedAccountId, let sharedAccount = try AgricolaAccount.get(sharedAccountId)
				{
					editedAccount = sharedAccount
					accountNameField.text = sharedAccount.username
					accountNameField.isEnabled = false
				}
			}
		}
		catch
		{
			print("ERROR: Failed to read project / account data for edit. \(error)")
		}
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		super.viewDidDisappear(animated)
		
		project = nil
		editedAccount = nil
	}

	
	// ACTIONS	------------------
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func okButtonPressed(_ sender: Any)
	{
		// Makes sure all fields are filled
		let name = accountNameField.trimmedText
		let password = passwordField.text ?? ""
		let repeated = repeatPasswordField.text ?? ""
		
		guard !name.isEmpty && !password.isEmpty && !repeated.isEmpty else
		{
			showError(message: "Please fill all the required fields", reasonDescription: "some of the required fields are left empty")
			return
		}
		
		guard password == repeated else
		{
			showError(message: "The passwords don't match!", reasonDescription: "account password was not repeated correctly")
			return
		}
		
		guard project != nil else
		{
			showError(message: "Internal Error, no project data read.", reasonDescription: "for some reason, project data was not read successfully earlier")
			return
		}
		
		do
		{
			// Either creates a new account or edits an existing one
			if let editedAccount = editedAccount
			{
				editedAccount.setPassword(password: password)
				try editedAccount.push()
			}
			else
			{
				// Makes sure there's no account with the same name
				guard try AccountView.instance.accountQuery(name: name).firstResultRow() == nil else
				{
					showError(message: "An account with that name already exists", reasonDescription: "there already exists an account with the provided name")
					return
				}
				
				let newAccount = AgricolaAccount(name: name, isShared: true, password: password, firstDevice: UIDevice.current.identifierForVendor?.uuidString)
				project.sharedAccountId = newAccount.idString
				
				try DATABASE.tryTransaction
				{
					try newAccount.push()
					try self.project.push()
				}
			}
			
			dismiss(animated: true, completion: nil)
		}
		catch
		{
			print("ERROR: Account edit failed. \(error)")
			showError(message: "Internal error occurred :(", reasonDescription: "data read / write fails for some unexpected reason")
		}
	}
	
	
	// OTHER METHODS	-------
	
	private func showError(message: String, reasonDescription: String)
	{
		errorLabel.text = NSLocalizedString(message, comment: "An error message displayed when \(reasonDescription)")
		errorLabel.isHidden = false
	}
}
