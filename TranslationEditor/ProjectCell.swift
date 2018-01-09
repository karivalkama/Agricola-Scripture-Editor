//
//  ProjectCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.3.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This cell displays basic information about a project in the project selection view
class ProjectCell: UITableViewCell
{
	// OUTLETS	------------------
	
	@IBOutlet weak var projectNameLabel: UILabel!
	@IBOutlet weak var languageLabel: UILabel!
	@IBOutlet weak var createdLabel: UILabel!
	
	
	// ATTRIBUTES	--------------
	
	static let identifier = "ProjectCell"
	
	
	// OTHER METHODS	-----------
	
	func configure(name: String, languageName: String, created: Date)
	{
		projectNameLabel.text = name
		languageLabel.text = languageName
		
		let formatter = DateFormatter()
		formatter.dateStyle = .long
		
		createdLabel.text = formatter.string(from: created)
	}
}
