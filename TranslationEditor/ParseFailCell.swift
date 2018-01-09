//
//  ParseFailCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 22.6.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

class ParseFailCell: UITableViewCell
{
	// OUTLETS	-------------------
	
	@IBOutlet weak var errorDescriptionLabel: UILabel!
	@IBOutlet weak var filenameLabel: UILabel!
	
	// ATTRIBUTES	---------------
	
	static let identifier = "ParseFailCell"
	
	
	// OTHER METHODS	----------
	
	func configure(fileName: String, errorDescription: String? = nil)
	{
		errorDescriptionLabel.text = errorDescription
		filenameLabel.text = fileName
	}
}
