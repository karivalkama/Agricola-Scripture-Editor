//
//  AutoLoginAlertVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 31.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

class AutoLoginAlertVC: UIViewController
{
	// ATTRIBUTES	---------------
	
	static let identifier = "AutoLoginAlert"
	
	private var completionHandler: ((Bool) -> ())?


	// ACTIONS	-------------------
	
	@IBAction func yesButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: { self.completionHandler?(true) })
	}
	
	@IBAction func noButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: { self.completionHandler?(false) })
	}
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		dismiss(animated: true, completion: { self.completionHandler?(false) })
	}
	
	
	// OTHER METHODS	------------
	
	func configure(completion: @escaping (Bool) -> ())
	{
		self.completionHandler = completion
	}
}
