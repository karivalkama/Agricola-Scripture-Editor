//
//  ImportBookCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.5.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This cell represents a single book in another project that can be imported into this one
class ImportBookCell: UITableViewCell
{
	// OUTLETS	-------------------
	
	@IBOutlet weak var languageLabel: UILabel!
	@IBOutlet weak var bookLabel: UILabel!
	@IBOutlet weak var identifierLabel: UILabel!
	@IBOutlet weak var projectLabel: UILabel!
	@IBOutlet weak var progressView: BookProgressUIView!
	
	
	// ATTRIBUTES	---------------
	
	static let identifier = "ImportBookCell"
	
	
	// OTHER METHODS	-----------
	
	func configure(languageName: String, code: BookCode, identifier: String, projectName: String, progress: BookProgressStatus?)
	{
		languageLabel.text = languageName
		bookLabel.text = code.description
		identifierLabel.text = identifier
		projectLabel.text = projectName
		
		if let progress = progress
		{
			progressView.isHidden = false
			progressView.configure(status: progress)
		}
		else
		{
			progressView.isHidden = true
		}
	}
}
