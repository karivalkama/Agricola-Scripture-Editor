//
//  LabelCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This table view cell simply displays a single label
class LabelCell: UITableViewCell
{
	// OUTLETS	----------------
	
	@IBOutlet weak var contentLabel: UILabel!
	
	
	// ATTRIBUTES	------------
	
	static let identifier = "LabelCell"
	
	
	// OTHER METHODS	--------
	
	func configure(text: String)
	{
		contentLabel.text = text
	}
}
