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
	
	static let identifier = "NoteCell"
	
	private weak var addThreadDelegate: AddNotesDelegate!
	
	private var note: ParagraphNotes!
	private var showStatus = false
	
	
	// COMP. PROPERTIES	--------
	
	var pathId: String? { return note?.pathId }
	
	
	// ACTIONS	----------------
	
	@IBAction func postButtonPressed(_ sender: Any)
	{
		addThreadDelegate?.insertThread(noteId: note.idString, pathId: pathId!)
	}
	
	@IBAction func hideShowButtonPressed(_ sender: Any)
	{
		// Informs the listener that a status change was requested
		// TODO: Remove
		// visibleListener?.showHideStatusRequested(forId: note!.idString, status: !showStatus)
	}
	
	
	// OTHER METHODS	-------
	
	func setContent(note: ParagraphNotes, name: String, displayHideShowButton: Bool, useShowOption: Bool, addDelegate: AddNotesDelegate)
	{
		self.note = note
		self.showStatus = !useShowOption
		self.addThreadDelegate = addDelegate
		
		nameLabel.text = name
		hideShowButton.isEnabled = displayHideShowButton
		hideShowButton.setTitle(useShowOption ? "Show" : "Hide" , for: .normal)
	}
}
