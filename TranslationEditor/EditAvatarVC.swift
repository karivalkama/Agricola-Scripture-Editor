//
//  EditAvatarVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is used for editing and creation of new project avatars
class EditAvatarVC: UIViewController
{
	// OUTLETS	------------------
	
	@IBOutlet weak var createAvatarView: CreateAvatarView!
	@IBOutlet weak var errorLabel: UILabel!
	
	
	// ATTRIBUTES	--------------
	
	private var targetAccountId: String?
	private var editedInfo: (Avatar, AvatarInfo)?
	
	
	// LOAD	----------------------

    override func viewDidLoad()
	{
        super.viewDidLoad()

		errorLabel.text = nil
		
		// If in editing mode, some fields cannot be edited
		if let (avatar, info) = editedInfo
		{
			createAvatarView.avatarImage = info.image
			
			createAvatarView.avatarName = avatar.name
			createAvatarView.avatarNameField.isEnabled = false
			
			createAvatarView.inProjectName = info.openName
			
			// Sharing can be enabled / disabled for non-shared accounts only
			// (Shared account avatars have always sharing enabled)
			do
			{
				if let account = try AgricolaAccount.get(info.accountId)
				{
					createAvatarView.mustBeShared = account.isShared
				}
			}
			catch
			{
				print("ERROR: Failed to read account data. \(error)")
			}
		}
		// If creating a new avatar, those created for shared accounts must be shared
		else
		{
			do
			{
				let isSharedAccount = try targetAccountId.exists { try (AgricolaAccount.get($0)?.isShared).or(true) }
				createAvatarView.mustBeShared = isSharedAccount
			}
			catch
			{
				print("ERROR: Failed to check whether account is shared. \(error)")
			}
		}
		
		createAvatarView.viewController = self
    }
	
	
	// ACTIONS	------------------
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func saveButtonPressed(_ sender: Any)
	{
		// Checks that all necessary fields are filled
		guard createAvatarView.allFieldsFilled else
		{
			errorLabel.text = "Please fill in the required fields"
			return
		}
		
		// Makes sure the passwords match
		guard createAvatarView.passwordsMatch else
		{
			errorLabel.text = "The passwords don't match!"
			return
		}
		
		do
		{
			// Makes the necessary modifications to the avatar
			if let (_, info) = editedInfo
			{
				if let newImage = createAvatarView.avatarImage, info.image != newImage
				{
					try info.setImage(newImage)
				}
				
				info.openName = createAvatarView.inProjectName
				
				if let newPassword = createAvatarView.offlinePassword
				{
					info.setPassword(newPassword)
				}
			}
			// Or creates a new avatar entirely
			else
			{
				guard let projectId = Session.instance.projectId else
				{
					print("ERROR: No project selected")
					return
				}
				
				// Finds the shared account for the project too
				guard let project = try Project.get(projectId) else
				{
					print("ERROR: Target project doesn't exist")
					return
				}
				
				let avatarName = createAvatarView.avatarName
				
				// Makes sure there is no avatar with the same name yet
				guard try Avatar.get(projectId: projectId, avatarName: avatarName) == nil else
				{
					errorLabel.text = "Avatar with the provided name already exists!"
					return
				}
				
				// Creates the new information
				let avatar = Avatar(name: avatarName, projectId: projectId)
				let info = AvatarInfo(avatarId: avatar.idString, accountId: targetAccountId.or(project.sharedAccountId), openName: createAvatarView.inProjectName, password: createAvatarView.offlinePassword, isShared: createAvatarView.isShared)
				
				// Saves the changes to the database (inlcuding image attachment)
				try DATABASE.tryTransaction
				{
					try avatar.push()
					try info.push()
					
					if let image = self.createAvatarView.avatarImage
					{
						try info.setImage(image)
					}
				}
			}
		}
		catch
		{
			print("ERROR: Failed to perform the required database operations. \(error)")
		}
		
		dismiss(animated: true, completion: nil)
	}
	
	
	// OTHER METHODS	--------------
	
	func configureForEdit(avatar: Avatar, avatarInfo: AvatarInfo)
	{
		self.editedInfo = (avatar, avatarInfo)
	}
}
