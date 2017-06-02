//
//  ResourceSelectionCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 2.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
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
	
	private(set) var resourceId: String!
	private var onStateChange: ((String, Bool) -> ())!
	
	
	// ACTIONS	------------------
	
	@IBAction func resourceStateChanged(_ sender: Any)
	{
		onStateChange(resourceId, resourceStateSwitch.isOn)
	}
	
	
	// OTHER METHODS	----------
	
	func configure(resourceId: String, resourceName: String, resourceLanguage: String, resourceState: Bool, onResourceStateChange: @escaping (String, Bool) -> ())
	{
		self.resourceId = resourceId
		self.onStateChange = onResourceStateChange
		
		resourceNameLabel.text = resourceName
		resourceLanguageLabel.text = resourceLanguage
		resourceStateSwitch.isOn = resourceState
	}
}
