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
class LoginVC: UIViewController
{
	// OUTLETS	--------------------
	
	@IBOutlet weak var userNameField: UITextField!
	@IBOutlet weak var onlineStatusView: OnlineStatusView!
	
	
	// ATTRIBUTES	----------------

	// INIT	------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	
	// ACTIONS	-------------------
	
	@IBAction func loginButtonPressed(_ sender: Any) {
	}
	
	
	// IMPLEMENTED METHODS	-------

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
