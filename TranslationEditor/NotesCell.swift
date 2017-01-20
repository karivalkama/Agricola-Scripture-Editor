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
	
	private var note: ParagraphNotes?
	
	
	// COMP. PROPERTIES	--------
	
	var pathId: String? { return note?.pathId }
	
	
	// ACTIONS	----------------
	
	@IBAction func hideShowButtonPressed(_ sender: Any)
	{
		// TODO: Show or hide notes contents
		// (inform listener / content manager)
	}
	
	
	// OTHER METHODS	-------
	
	func setContent(note: ParagraphNotes, name: String, displayHideShowButton: Bool, useShowOption: Bool)
	{
		self.note = note
		nameLabel.text = name
		hideShowButton.isHidden = !displayHideShowButton
		hideShowButton.setTitle(useShowOption ? "Show" : "Hide" , for: .normal)
	}
}
