//
//  SelectAvatarVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 21.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller handles avatar selection and authorization
class SelectAvatarVC: UIViewController
{
	// OUTLETS	-------------------
	
	@IBOutlet weak var avatarCollectionView: UICollectionView!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var loginButton: BasicButton!
	@IBOutlet weak var passwordView: UIView!
	
	
	// ATTRIBUTES	---------------
	
	private var avatarData = [(Avatar, AvatarInfo)]()
	private var projectId = "test-project" // TODO: This will be provided by the previous view
	private var loggedAccountId = "user/testuser" // TODO: This will be provided by the previous view
	
	
	// LOAD	-----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		// Reads the avatar data from the database
    }
	
	
	// ACTIONS	-------------------
	
	@IBAction func passwordFieldChanged(_ sender: Any)
	{
		// TODO: Enable or disable login button
	}
	
	@IBAction func cancelPressed(_ sender: Any)
	{
		// TODO: Hide password field. Reset selection
	}
	
	@IBAction func loginPressed(_ sender: Any)
	{
		// TODO: Check password, move to next view
	}
	
	
	// IMPLEMENTED METHODS	-------
}
