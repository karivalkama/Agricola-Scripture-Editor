//
//  ImportBookVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is used for importing books from other projects
class ImportBookVC: UIViewController
{
	// OUTLETS	------------------
	
	@IBOutlet weak var languageFilterView: FilteredMultiSelection!
	@IBOutlet weak var bookFilterView: FilteredMultiSelection!
	@IBOutlet weak var bookSelectionTable: UITableView!
	@IBOutlet weak var contentView: KeyboardReactiveView!
	@IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentBottomConstraint: NSLayoutConstraint!
	
	
	// ATTRIBUTES	--------------
	
	
	
	
	// LOAD	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	
	// ACTIONS	------------------
	
	@IBAction func backButtonPressed(_ sender: Any)
	{
		
	}
	
    

	// IMPLEMENTED METHODS	------
	
	
}
