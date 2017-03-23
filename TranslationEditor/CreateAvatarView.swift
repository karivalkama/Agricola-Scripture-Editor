//
//  CreateAvatarView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 15.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view is used for requesting basic avatar information from the user
// This view is not used for defining avatar rights
@IBDesignable class CreateAvatarView: CustomXibView
{
	// OUTLETS	----------------
	
	@IBOutlet weak var avatarImageView: UIImageView!
	@IBOutlet weak var avatarNameField: UITextField!
	@IBOutlet weak var inProjectNameField: UITextField!
	@IBOutlet weak var isSharedSwitch: UISwitch!
	@IBOutlet weak var offlinePasswordField: UITextField!
	@IBOutlet weak var repeatPasswordField: UITextField!
	
	@IBOutlet weak var sharingView: UIView!
	@IBOutlet weak var passwordsView: UIView!
	
	
	// ATTRIBUTES	------------
	
	private var _mustBeShared = false
	var mustBeShared: Bool
	{
		get { return _mustBeShared }
		set
		{
			_mustBeShared = newValue
			
			// Sharing is not asked when it is determined beforehand
			sharingView.isHidden = newValue
			updatePasswordVisibility()
		}
	}
	
	
	// COMPUTED PROPERTIES	----
	
	var avatarName: String { return (avatarNameField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)).or("") }
	
	var inProjectName: String?
	{
		if let rawName = inProjectNameField.text
		{
			let trimmed = rawName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
			
			if trimmed.isEmpty
			{
				return nil
			}
			else
			{
				return trimmed
			}
		}
		else
		{
			return nil
		}
	}
	
	var offlinePassword: String?
	{
		return offlinePasswordField.text
	}
	
	var allFieldsFilled: Bool
	{
		return !avatarName.isEmpty && (!isShared || (fieldIsFilled(offlinePasswordField) && fieldIsFilled(repeatPasswordField)))
	}
	
	var passwordsMatch: Bool
	{
		return !isShared || offlinePasswordField.text == repeatPasswordField.text
	}
	
	var isShared: Bool { return mustBeShared || isSharedSwitch.isOn }
	
	
	// INIT	--------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "CreateAvatar")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "CreateAvatar")
	}
	
	
	// ACTIONS	----------------
	
	@IBAction func sharingChanged(_ sender: Any)
	{
		updatePasswordVisibility()
	}
	
	@IBAction func avatarImageTapped(_ sender: Any)
	{
		// TODO: Request the user to change image
	}
	
	
	// OTHER METHODS	--------
	
	private func fieldIsFilled(_ field: UITextField) -> Bool
	{
		return field.text != nil && !field.text!.isEmpty
	}
	
	private func updatePasswordVisibility()
	{
		// Offline password fields are only displayed while the sharing is on
		passwordsView.isHidden = !isShared
	}
}
