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
	private var visibleListener: NotesShowHideListener?
	private var showStatus = false
	
	
	// COMP. PROPERTIES	--------
	
	var pathId: String? { return note?.pathId }
	
	
	// ACTIONS	----------------
	
	@IBAction func hideShowButtonPressed(_ sender: Any)
	{
		// Informs the listener that a status change was requested
		visibleListener?.showHideStatusRequested(forId: note!.idString, status: !showStatus)
	}
	
	
	// OTHER METHODS	-------
	
	func setContent(note: ParagraphNotes, name: String, displayHideShowButton: Bool, useShowOption: Bool, listener: NotesShowHideListener)
	{
		self.note = note
		self.visibleListener = listener
		self.showStatus = !useShowOption
		
		nameLabel.text = name
		hideShowButton.isEnabled = displayHideShowButton
		hideShowButton.setTitle(useShowOption ? "Show" : "Hide" , for: .normal)
	}
}
