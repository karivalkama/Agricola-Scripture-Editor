//
//  CreateAccountVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 2.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view is used for creating new agricola accounts
class CreateAccountVC: UIViewController, ConnectionListener, LiveQueryListener, MultiSelectionDataSource
{
	// TYPES	----------------------
	
	typealias QueryTarget = LanguageView
	
	
	// OUTLETS	----------------------
	
	@IBOutlet weak var usernameField: UITextField!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var repeatPasswordField: UITextField!
	@IBOutlet weak var isSharedSwitch: UISwitch!
	@IBOutlet weak var languageSelectionView: FilteredMultiSelection!
	@IBOutlet weak var onlineStatusView: OnlineStatusView!
	@IBOutlet weak var createAccountButton: BasicButton!
	@IBOutlet weak var errorMessageLabel: UILabel!
	
	
	// ATTRIBUTES	------------------
	
	private let liveQueryManager = LanguageView.instance.createQuery().liveQueryManager
	private var languages = [Language]()
	
	
	// COMPUTED PROPERTIES	----------
	
	var numberOfOptions: Int { return languages.count }
	
	
	// INIT	--------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		errorMessageLabel.text = nil
		createAccountButton.isEnabled = false
		
		languageSelectionView.dataSource = self
		
		// Listens to language data
		liveQueryManager.addListener(AnyLiveQueryListener(self))
		liveQueryManager.start()
		
		// Starts by making a one-time update request to the server
		ConnectionManager.instance.registerListener(self)
		ConnectionManager.instance.connect(serverURL: SERVER_ADDRESS, continuous: false)
    }
	
	
	// ACTIONS	----------------------
	
	@IBAction func backButtonPressed(_ sender: Any)
	{
		// Closes the view
		close()
	}
	
	@IBAction func createButtonPressed(_ sender: Any)
	{
		// Checks that all information has been provided first
		guard let userName = usernameField.text, !userName.isEmpty else
		{
			errorMessageLabel.text = "Please provide a username"
			return
		}
		
		guard let password = passwordField.text, !password.isEmpty else
		{
			errorMessageLabel.text = "Please provide a password"
			return
		}
		
		guard repeatPasswordField.text == password else
		{
			errorMessageLabel.text = "Passwords don't match"
			return
		}
		
		errorMessageLabel.text = nil
		
		do
		{
			// TODO: Create the couchbase account using a special service
			// (should fail if there already is a matching account)
			
			// Creates the agricola account
			// TODO: Just remove the duplicate check since the service should do that
			guard try AccountView.instance.accountQuery(displayName: userName).firstResultRow() == nil else
			{
				errorMessageLabel.text = "Please provide a unique username"
				return
			}
			
			let account = AgricolaAccount(name: userName, languageIds: languageSelectionView.selectedIndices.map { languages[$0].idString }, isShared: isSharedSwitch.isOn)
			try account.push()
			
			try Session.instance.logIn(accountId: account.idString, userName: account.cbUserName, password: password)
			
			// Closes the view
			close()
		}
		catch
		{
			print("ERROR: Failed to create a new account. \(error)")
			errorMessageLabel.text = "Internal error: account creation failed"
		}
	}
	
	
	// IMPLEMENTED METHODS	-----------
	
	func rowsUpdated(rows: [Row<LanguageView>])
	{
		do
		{
			languages = try rows.map { try $0.object() }
			languageSelectionView.reset()
		}
		catch
		{
			print("ERROR: Failed to update language data. \(error)")
		}
	}
	
	func onConnectionStatusChange(newStatus status: ConnectionStatus)
	{
		onlineStatusView.status = status
		
		if status.isFinal && !status.isError
		{
			createAccountButton.isEnabled = true
		}
	}
	
	func onConnectionProgressUpdate(transferred: Int, of total: Int, progress: Double)
	{
		onlineStatusView.updateProgress(completed: transferred, of: total, progress: progress)
	}
	
	func labelForOption(atIndex index: Int) -> String
	{
		return languages[index].name
	}
	
	func indexIsIncludedInFilter(index: Int, filter: String) -> Bool
	{
		return languages[index].name.lowercased().contains(filter.lowercased())
	}
	
	
	// OTHER METHODS	--------------
	
	private func close()
	{
		liveQueryManager.removeListeners()
		liveQueryManager.stop()
		ConnectionManager.instance.removeListener(self)
		dismiss(animated: true, completion: nil)
	}
}
