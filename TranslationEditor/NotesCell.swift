//
//  NotesCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 19.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

class NotesCell: UITableViewCell, ParagraphAssociated
{
	// OUTLETS	----------------
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var hideShowButton: UIButton!
	
	
	// ATTRIBUTES	------------
	
	var pathId: String?
	
	
	// ACTIONS	----------------
	
	@IBAction func hideShowButtonPressed(_ sender: Any)
	{
		// TODO: Show or hide notes contents
		// (inform listener / content manager)
	}
	
	
	// OTHER METHODS	-------
	
	func setContent(name: String, pathId: String, displayHideShowButton: Bool, useShowOption: Bool)
	{
		nameLabel.text = name
		hideShowButton.isHidden = !displayHideShowButton
		hideShowButton.setTitle(useShowOption ? "Show" : "Hide" , for: .normal)
		self.pathId = pathId
	}
}
