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
	
	private var completion: (() -> ())?
	
	
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
	
	@IBAction func createAccountPressed(_ sender: Any)
	{
		// Makes sure all the fields are filled
		guard let userName = userNameField.text, !userName.isEmpty else
		{
			errorLabel.text = "Please fill the username field"
			return
		}
		
		guard let password = passwordField.text, !password.isEmpty else
		{
			errorLabel.text = "Please provide a password"
			return
		}
		
		guard let passwordRepeated = repeatPasswordField.text, !passwordRepeated.isEmpty else
		{
			errorLabel.text = "Please repeat the password"
			return
		}
		
		do
		{
			// Makes sure there is no account with the provided name already
			guard try AccountView.instance.accountQuery(name: userName).firstResultRow() == nil else
			{
				errorLabel.text = "Account with a similar name already exists!"
				return
			}
		}
		catch
		{
			errorLabel.text = "Internal error occurred. Please try again."
			print("ERROR: Couldn't check if account exists. \(error)")
			return
		}
		
		// Checks that the passwords match
		guard password == passwordRepeated else
		{
			errorLabel.text = "The passwords don't match!"
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
			
			dismiss(animated: true, completion: completion)
		}
		catch
		{
			errorLabel.text = "Internal error occurred while saving data."
			print("ERROR: Failed to save account data. \(error)")
			return
		}
	}
	
	
	// OTHER METHODS	---------------
	
	func configure(completion: @escaping () -> ())
	{
		self.completion = completion
	}
}
