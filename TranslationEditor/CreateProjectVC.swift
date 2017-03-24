//
//  CreateProjectVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 23.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This ciew controller handles the user input processing for basic project data. That is, for project name and language as well as the admin avatar.
class CreateProjectVC: UIViewController
{
	// OUTLETS	------------------
	
	@IBOutlet weak var projectNameField: UITextField!
	@IBOutlet weak var targetLanguageField: UITextField!
	@IBOutlet weak var targetLanguageTable: UITableView!
	@IBOutlet weak var createAvatarView: CreateAvatarView!
	// TODO: Add an error label
	
	// INIT	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	
	// ACTIONS	------------------

	@IBAction func continueButtonPressed(_ sender: Any) {
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
