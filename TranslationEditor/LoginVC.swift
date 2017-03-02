//
//  LoginVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 1.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// Login VC handles user authorization and login (duh)
// The process may be skipped / sped up after the first success
// (user data is stored in the keychain)
class LoginVC: UIViewController, ConnectionListener
{
	// OUTLETS	--------------------
	
	@IBOutlet weak var userNameField: UITextField!
	@IBOutlet weak var onlineStatusView: OnlineStatusView!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var loginButton: BasicButton!
	
	
	// ATTRIBUTES	----------------
	
	private var loginUsername: String?
	private var loginPassword: String?
	

	// INIT	------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		errorLabel.text = nil
		onlineStatusView.isHidden = true

		// If the user is already logged in, just starts the background updates and moves on
		if Session.instance.isAuthorized
		{
			proceed()
		}
    }
	
	
	// ACTIONS	-------------------
	
	@IBAction func loginButtonPressed(_ sender: Any)
	{
		// Makes sure the username and password have been provided first
		guard let userName = userNameField.text, !userName.isEmpty else
		{
			errorLabel.text = "Please provide a username"
			return
		}
		guard let password = passwordField.text, !password.isEmpty else
		{
			errorLabel.text = "Please provide a password"
			return
		}
		
		loginButton.isEnabled = false
		onlineStatusView.isHidden = false
		
		loginUsername = userName
		loginPassword = password
		
		// Tries logging in
		ConnectionManager.instance.registerListener(self)
		// TODO: Use real authorization when it is only available
		ConnectionManager.instance.connect(serverURL: SERVER_ADDRESS, continuous: false)
	}
	
	
	// IMPLEMENTED METHODS	-------
	
	func onConnectionStatusChange(newStatus status: ConnectionStatus)
	{
		// Updates online status
		onlineStatusView.status = status
		
		if status.isFinal
		{
			// Re-enables the login button once done
			loginButton.isEnabled = true
			
			// Also, if the login was successful, proceeds to next view
			if status == .unauthorized
			{
				errorLabel.text = "Invalid username and/or password"
				passwordField.text = nil
			}
			else
			{
				errorLabel.text = nil
				
				if !status.isError
				{
					// Saves the login status to the session
					do
					{
						guard let result = try AccountView.instance.accountQuery(displayName: loginUsername!).firstResultRow() else
						{
							print("ERROR: No account for username: \(loginUsername!)")
							errorLabel.text = "Internal Error: No user data available"
							return
						}
						
						try Session.instance.logIn(accountId: result.id!, userName: loginUsername!.toKey, password: loginPassword!)
						proceed()
					}
					catch
					{
						print("ERROR: Login failed. \(error)")
						errorLabel.text = "Internal Error: Database operation failed"
					}
				}
			}
		}
	}
	
	func onConnectionProgressUpdate(transferred: Int, of total: Int, progress: Double)
	{
		onlineStatusView.updateProgress(completed: transferred, of: total, progress: progress)
	}

	
	// OTHER METHODS	-----------
	
	private func proceed()
	{
		ConnectionManager.instance.removeListener(self)
		
		passwordField.text = nil
		errorLabel.isHidden = true
		onlineStatusView.isHidden = true
		
		// Starts the updates in the background
		// TODO: Add authorization when backed supports it
		ConnectionManager.instance.connect(serverURL: SERVER_ADDRESS)
		
		performSegue(withIdentifier: "SelectProject", sender: nil)
	}
}
