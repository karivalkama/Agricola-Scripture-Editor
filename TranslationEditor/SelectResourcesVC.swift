//
//  SelectResourcesVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 2.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is used for determining, which resources are available to the user at which time
class SelectResourcesVC: UIViewController
{
	// OUTLETS	---------------------
	
	@IBOutlet weak var resourceTableView: UITableView!
	
	
	
	// LOAD	-------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

	
	// ACTIONS	---------------------
	
	@IBAction func closeButtonPressed(_ sender: Any) {
	}
	
	@IBAction func backgroundTapped(_ sender: Any) {
	}
	
}
