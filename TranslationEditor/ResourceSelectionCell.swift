//
//  ResourceSelectionCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 2.6.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This cell is used for activating / deactivating a certain resource
class ResourceSelectionCell: UITableViewCell
{
	// OUTLETS	------------------
	
	@IBOutlet weak var resourceNameLabel: UILabel!
	@IBOutlet weak var resourceLanguageLabel: UILabel!
	@IBOutlet weak var resourceStateSwitch: UISwitch!
	
	
	// ATTRIBUTES	--------------
	
	static let identifier = "ResourceCell"
	
	private var onStateChange: ((UITableViewCell, Bool) -> ())!
	
	
	// ACTIONS	------------------
	
	@IBAction func resourceStateChanged(_ sender: Any)
	{
		onStateChange(self, resourceStateSwitch.isOn)
	}
	
	
	// OTHER METHODS	----------
	
	func configure(resourceName: String, resourceLanguage: String, resourceState: Bool, onResourceStateChange: @escaping (UITableViewCell, Bool) -> ())
	{
		self.onStateChange = onResourceStateChange
		
		resourceNameLabel.text = resourceName
		resourceLanguageLabel.text = resourceLanguage
		resourceStateSwitch.isOn = resourceState
	}
}
