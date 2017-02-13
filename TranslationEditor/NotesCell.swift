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
	
	
	// ATTRIBUTES	------------
	
	static let identifier = "NoteCell"
	
	private weak var addThreadDelegate: AddNotesDelegate!
	
	private(set) var note: ParagraphNotes!
	private var showStatus = false
	
	
	// COMP. PROPERTIES	--------
	
	var pathId: String? { return note?.pathId }
	
	
	// ACTIONS	----------------
	
	@IBAction func postButtonPressed(_ sender: Any)
	{
		addThreadDelegate?.insertThread(noteId: note.idString, pathId: pathId!)
	}
	
	
	// OTHER METHODS	-------
	
	func setContent(note: ParagraphNotes, name: String, displayHideShowButton: Bool, useShowOption: Bool, addDelegate: AddNotesDelegate)
	{
		self.note = note
		self.showStatus = !useShowOption
		self.addThreadDelegate = addDelegate
		
		nameLabel.text = name
	}
}
