//
//  CreateAccountVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 2.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is used for adding new user accounts
class CreateAccountVC: UIViewController
{
	// OUTLETS	------------------
	
	@IBOutlet weak var userNameField: UITextField!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var repeatPasswordField: UITextField!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var createAccountButton: BasicButton!
	
	
	// ATTRIBUTES	--------------
	
	private var completion: ((AgricolaAccount) -> ())?
	
	
	// LOAD	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		errorLabel.text = nil
		contentView.configure(mainView: view, elements: [userNameField, passwordField, repeatPasswordField, errorLabel, createAccountButton], topConstraint: contentTopConstraint)
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
	
	
	// ACTIONS	------------------
	
	@IBAction func cancelPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func createAccountPressed(_ sender: Any)
	{
		// Makes sure all the fields are filled
		guard let userName = userNameField.text, !userName.isEmpty else
		{
			errorLabel.text = NSLocalizedString("Please fill the account name field", comment: "An error message displayed when the required account name field is empty")
			return
		}
		
		guard let password = passwordField.text, !password.isEmpty else
		{
			errorLabel.text = NSLocalizedString("Please provide a password", comment: "An error message displayed when the required password field is empty")
			return
		}
		
		guard let passwordRepeated = repeatPasswordField.text, !passwordRepeated.isEmpty else
		{
			errorLabel.text = NSLocalizedString("Please repeat the password", comment: "An error message displayed when the required repeat password field is empty")
			return
		}
		
		do
		{
			// Makes sure there is no account with the provided name already
			guard try AccountView.instance.accountQuery(name: userName).firstResultRow() == nil else
			{
				errorLabel.text = NSLocalizedString("Account with a similar name already exists!", comment: "An error message displayed when trying to create a duplicate account")
				return
			}
		}
		catch
		{
			errorLabel.text = NSLocalizedString("Internal error occurred. Please try again.", comment: "An error message displayed when account creation fails due to an unexpected error")
			print("ERROR: Couldn't check if account exists. \(error)")
			return
		}
		
		// Checks that the passwords match
		guard password == passwordRepeated else
		{
			errorLabel.text = NSLocalizedString("The passwords don't match!", comment: "An error message displayed when two passwords fields contents don't match")
			repeatPasswordField.text = nil
			return
		}
		
		do
		{
			// Inserts the new account and moves on
			let newAccount = AgricolaAccount(name: userName, isShared: false, password: password, firstDevice: UIDevice.current.identifierForVendor?.uuidString)
			try newAccount.push()
			
			// Logs in with the new account
			if !Session.instance.isAuthorized
			{
				print("STATUS: Logs in with the new account")
				Session.instance.logIn(accountId: newAccount.idString, userName: userName, password: password)
			}
			
			dismiss(animated: true, completion: { self.completion?(newAccount) })
		}
		catch
		{
			errorLabel.text = NSLocalizedString("Internal error occurred while saving data.", comment: "An error message displayed when account creation fails due to an unexpected error")
			print("ERROR: Failed to save account data. \(error)")
			return
		}
	}
	
	
	// OTHER METHODS	---------------
	
	func configure(completion: @escaping (AgricolaAccount) -> ())
	{
		self.completion = completion
	}
}
