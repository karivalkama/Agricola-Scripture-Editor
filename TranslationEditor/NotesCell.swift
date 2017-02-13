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
	
	private(set) var note: ParagraphNotes!
	
	
	// COMP. PROPERTIES	--------
	
	var pathId: String? { return note?.pathId }
	
	
	// OTHER METHODS	-------
	
	func setContent(note: ParagraphNotes, name: String)
	{
		self.note = note
		nameLabel.text = name
	}
}
