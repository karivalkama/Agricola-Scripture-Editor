//
//  ErrorAlertVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is displayed to inform user of some special situation before the program continues its function
class ErrorAlertVC: UIViewController
{
	// OUTLETS	-------------------
	
	@IBOutlet weak var errorHeadingLabel: UILabel!
	@IBOutlet weak var errorMessageTextView: UITextView!
	
	
	// ATTRIBUTES	---------------
	
	private var configured = false
	private var heading: String!
	private var text: String!
	
	private var completion: (() -> ())?
	
	
	// LOAD	-----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		guard configured else
		{
			fatalError("Error Alert View Controller must be configured before use")
		}
		
		errorHeadingLabel.text = heading
		errorMessageTextView.text = text
    }

	
	// ACTIONS	-------------------
	
	@IBAction func okButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: completion)
	}
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		dismiss(animated: true, completion: completion)
	}
	
	
	// OTHER METHODS	-----------
	
	func configure(heading: String, text: String, completion: (() -> ())? = nil)
	{
		configured = true
		self.heading = heading
		self.text = text
		self.completion = completion
	}
}
