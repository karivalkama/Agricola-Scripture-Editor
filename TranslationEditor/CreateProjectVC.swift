//
//  CreateProjectVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 2.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is used for adding of new projects
class CreateProjectVC: UIViewController
{
	// OUTLETS	---------------------
	@IBOutlet weak var projectNameField: UITextField!
	@IBOutlet weak var accountNameField: UITextField!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var repeatPasswordField: UITextField!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var selectLanguageView: FilteredSingleSelection!
	@IBOutlet weak var createProjectButton: BasicButton!
	
	
	// LOAD	-------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
    }

	
	// ACTIONS	---------------------
	
	@IBAction func cancelButtonPressed(_ sender: Any) {
	}
	
	@IBAction func createProjectPressed(_ sender: Any) {
	}
}
