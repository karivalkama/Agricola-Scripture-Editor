//
//  SelectAvatarVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 21.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller handles avatar selection and authorization
class SelectAvatarVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, LiveQueryListener, StackDismissable
{
	// TYPES	-------------------
	
	typealias QueryTarget = AvatarView
	
	
	// OUTLETS	-------------------
	
	@IBOutlet weak var avatarCollectionView: UICollectionView!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var loginButton: BasicButton!
	@IBOutlet weak var passwordView: KeyboardReactiveView!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var topBar: TopBarUIView!
	
	
	// ATTRIBUTES	---------------
	
	private var queryManager: LiveQueryManager<QueryTarget>?
	private var avatarData = [(Avatar, AvatarInfo)]()
	private var selectedData: (Avatar, AvatarInfo)?
	
	private var usesSharedAccount = true
	
	
	// COMPUTED PROPERTIES	-------
	
	var shouldDismissBelow: Bool { return !usesSharedAccount }
	
	
	// LOAD	-----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		topBar.configure(hostVC: self, title: "Select Avatar")
		
		guard let projectId = Session.instance.projectId else
		{
			print("ERROR: No selected project -> No available avatar data")
			return
		}
		
		guard let accountId = Session.instance.accountId else
		{
			print("ERROR: No account information available.")
			return
		}
		
		// If logged in with a non-shared account, uses the only avatar for the project
		// Otherwises reads all avatar data and filters out the non-shared later
		do
		{
			if let project = try Project.get(projectId)
			{
				usesSharedAccount = project.sharedAccountId == accountId
				if usesSharedAccount
				{
					queryManager = AvatarView.instance.avatarQuery(projectId: projectId).liveQueryManager
				}
				else
				{
					queryManager = AvatarView.instance.avatarQuery(projectId: projectId, accountId: accountId).liveQueryManager
				}
			}
		}
		catch
		{
			print("ERROR: Failed to read associated database data. \(error)")
		}
		
		avatarCollectionView.delegate = self
		avatarCollectionView.dataSource = self
		
		queryManager?.addListener(AnyLiveQueryListener(self))
		passwordView.configure(mainView: view, elements: [loginButton, errorLabel, passwordField])
    }
	
	override func viewDidAppear(_ animated: Bool)
	{
		hidePasswordView()
		
		// If the project has not been chosen, doesn't configure anything
		if Session.instance.projectId != nil
		{
			// Sets up the top bar
			let title = "Select Avatar"
			if let presentingViewController = presentingViewController
			{
				if let presentingViewController = presentingViewController as? SelectProjectVC
				{
					topBar.configure(hostVC: self, title: title, leftButtonText: presentingViewController.shouldDismissBelow ? "Log Out" : "Switch Project")
					{
						Session.instance.projectId = nil
						presentingViewController.dismissFromAbove()
					}
				}
				else
				{
					topBar.configure(hostVC: self, title: title, leftButtonText: "Back", leftButtonAction: { self.dismiss(animated: true, completion: nil) })
				}
			}
			
			// If the avatar has already been chosen, skips this phase
			if Session.instance.avatarId != nil
			{
				print("STATUS: Avatar already selected")
				proceed(animated: false)
				return
			}
			
			// Otherwise starts the queries
			queryManager?.start()
			passwordView.startKeyboardListening()
		}
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		passwordView.endKeyboardListening()
		// Doen't need to continue with live queries while the view is not visible
		queryManager?.stop()
	}
	
	
	// ACTIONS	-------------------
	
	@IBAction func passwordFieldChanged(_ sender: Any)
	{
		// Enables or disables login button
		loginButton.isEnabled = passwordField.text.exists { !$0.isEmpty } || selectedData.exists { !$0.1.requiresPassword }
	}
	
	@IBAction func cancelPressed(_ sender: Any)
	{
		// Hide password area. Resets selection
		hidePasswordView()
	}
	
	@IBAction func loginPressed(_ sender: Any)
	{
		guard let (selectedAvatar, selectedInfo) = selectedData else
		{
			print("ERROR: No selected avatar")
			return
		}
		
		// Checks password, moves to next view
		guard (passwordField.text.exists { selectedInfo.authenticate(loggedAccountId: Session.instance.accountId, password: $0) }) else
		{
			errorLabel.isHidden = false
			return
		}
		
		Session.instance.avatarId = selectedAvatar.idString
		proceed()
	}
	
	
	// IMPLEMENTED METHODS	-------
	
	func rowsUpdated(rows: [Row<QueryTarget>])
	{
		do
		{
			// If using a shared account, presents all viable options in the collection view
			if usesSharedAccount
			{
				avatarData = try rows.map { try $0.object() }.flatMap
				{
					avatar in
					
					if let info = try avatar.info(), info.isShared
					{
						return (avatar, info)
					}
					else
					{
						return nil
					}
				}
				
				avatarCollectionView.reloadData()
			}
			// Otherwise just finds the first applicable avatar and uses that
			else
			{
				if let avatarId = rows.first?.id
				{
					print("STATUS: Proceeding with non-shared account avatar")
					Session.instance.avatarId = avatarId
					proceed()
				}
			}
		}
		catch
		{
			print("ERROR: Failed to process avatar data. \(error)")
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		return avatarData.count + 1
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AvatarCell.identifier, for: indexPath) as! AvatarCell
		
		// The last row is used for the avatar addition
		if indexPath.row == avatarData.count
		{
			cell.configure(avatarName: "New Avatar", avatarImage: #imageLiteral(resourceName: "addIcon"))
		}
		else
		{
			let (avatar, info) = avatarData[indexPath.row]
			cell.configure(avatarName: avatar.name, avatarImage: info.image)
		}
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		// Selects an avatar and displays the password view
		if selectedData == nil
		{
			// If the last cell was selected, displays a view for adding a new avatar
			if indexPath.row == avatarData.count
			{
				displayAlert(withIdentifier: "EditAvatar", storyBoardId: "MainMenu")
			}
			else
			{
				selectedData = avatarData[indexPath.row]
				
				if selectedData!.1.requiresPassword
				{
					errorLabel.isHidden = true
					passwordView.isHidden = false
				}
				else
				{
					Session.instance.avatarId = selectedData!.0.idString
					proceed()
				}
			}
		}
	}
	
	func willDissmissBelow()
	{
		// Deselects the project
		Session.instance.projectId = nil
	}
	
	
	// OTHER METHODS	--------
	
	func proceed(animated: Bool = true)
	{
		// Presents the main menu
		let storyboard = UIStoryboard(name: "MainMenu", bundle: nil)
		guard let controller = storyboard.instantiateInitialViewController() else
		{
			print("ERROR: Failed to instantiate VC for the main menu")
			return
		}

		present(controller, animated: animated, completion: nil)
	}
	
	private func hidePasswordView()
	{
		// Hide password area. Resets selection
		passwordField.text = nil
		selectedData = nil
		passwordView.isHidden = true
		avatarCollectionView.selectItem(at: nil, animated: true, scrollPosition: .left)
	}
}
