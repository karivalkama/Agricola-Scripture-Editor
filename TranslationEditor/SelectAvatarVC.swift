//
//  SelectAvatarVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 21.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller handles avatar selection and authorization
class SelectAvatarVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate
{
	// OUTLETS	-------------------
	
	@IBOutlet weak var avatarCollectionView: UICollectionView!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var loginButton: BasicButton!
	@IBOutlet weak var passwordView: UIView!
	@IBOutlet weak var errorLabel: UILabel!
	
	
	// ATTRIBUTES	---------------
	
	private var avatarData = [(Avatar, AvatarInfo)]()
	private var selectedData: (Avatar, AvatarInfo)?
	
	
	// LOAD	-----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
    }
	
	override func viewDidAppear(_ animated: Bool)
	{
		// If the avatar has already been chosen, skips this phase
		if let avatarId = Session.instance.avatarId
		{
			proceed(avatarId: avatarId, animated: false)
			return
		}
		
		guard let projectId = Session.instance.projectId else
		{
			print("ERROR: No selected project -> No available avatar data")
			return
		}
		
		do
		{
			// TODO: Add handling for cases where logged in with a non-shared account
			// (Extra parameter into query)
			// And when logged in with a shared account (filter results based on shared attribute)
			
			// Reads the avatar data from the database
			let avatarInfo = try AvatarInfoView.instance.avatarQuery(projectId: projectId).resultObjects()
			
			avatarData = try avatarInfo.flatMap
				{
					info in
					
					if let avatar = try Avatar.get(info.avatarId)
					{
						return (avatar, info)
					}
					else
					{
						return nil
					}
			}
		}
		catch
		{
			print("ERROR: Failed to load avatar data. \(error)")
		}
		
		avatarCollectionView.delegate = self
		avatarCollectionView.dataSource = self
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
		passwordField.text = nil
		selectedData = nil
		passwordView.isHidden = true
		avatarCollectionView.selectItem(at: nil, animated: true, scrollPosition: .left)
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
		
		proceed(avatarId: selectedAvatar.idString)
	}
	
	@IBAction func backButtonPressed(_ sender: Any)
	{
		// Deselects the current project
		Session.instance.projectId = nil
		
		// Also, if this was a project account, logs out
		do
		{
			if let accountId = Session.instance.accountId, let account = try AgricolaAccount.get(accountId)
			{
				if account.projectId != nil
				{
					Session.instance.logout()
				}
			}
		}
		catch
		{
			print("ERROR: Couldn't read account data. \(error)")
		}
		
		dismiss(animated: true, completion: nil)
	}
	
	
	
	// IMPLEMENTED METHODS	-------
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
	{
		return avatarData.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AvatarCell.identifier, for: indexPath) as! AvatarCell
		
		let (avatar, info) = avatarData[indexPath.row]
		let avatarName = info.openName.or(avatar.name)
		
		cell.configure(avatarName: avatarName, avatarImage: info.image)
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
	{
		// Selects an avatar and displays the password view
		if selectedData == nil
		{
			selectedData = avatarData[indexPath.row]
			
			if selectedData!.1.requiresPassword
			{
				errorLabel.isHidden = true
				passwordView.isHidden = false
			}
			else
			{
				proceed(avatarId: selectedData!.0.idString)
			}
		}
	}
	
	
	// OTHER METHODS	--------
	
	func proceed(avatarId: String, animated: Bool = true)
	{
		Session.instance.avatarId = avatarId
		
		// Presents the main menu
		let storyboard = UIStoryboard(name: "MainMenu", bundle: nil)
		guard let controller = storyboard.instantiateInitialViewController() else
		{
			print("ERROR: Failed to instantiate VC for the main menu")
			return
		}

		present(controller, animated: animated, completion: nil)
	}
}
