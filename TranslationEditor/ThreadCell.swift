//
//  ThreadCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// Thread cells display notes thread data
class ThreadCell: UITableViewCell, ParagraphAssociated
{
	// OUTLETS	--------------
	
	@IBOutlet weak var flagImageView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var resolveButton: UIButton!
	@IBOutlet weak var hideShowButton: UIButton!
	
	
	// ATTRIBUTES	----------
	
	private var thread: NotesThread?
	private(set) var pathId: String?
	
	
	// ACTIONS	--------------
	
	@IBAction func hideShowButtonPressed(_ sender: Any)
	{
		// TODO: Change the visibility status of the thread (inform listener)
	}
	
	@IBAction func resolveButtonPressed(_ sender: Any)
	{
		// Marks the thread as resolved (this will cause all cells to get updated)
		if let thread = thread
		{
			do
			{
				try thread.resolve()
			}
			catch
			{
				print("ERROR: Couldn't resolve a thread \(error)")
			}
		}
	}
	
	
	// OTHER METHODS	-----
	
	func setContent(thread: NotesThread, pathId: String, displayHideShowButton: Bool, useShowOption: Bool)
	{
		self.pathId = pathId
		self.thread = thread
		
		nameLabel.text = thread.isResolved ? "Resolved: \(thread.name)" : thread.name
		
		resolveButton.isHidden = thread.isResolved
		flagImageView.isHidden = thread.isResolved
		
		hideShowButton.setTitle(useShowOption ? "Show" : "Hide", for: .normal)
		hideShowButton.isHidden = !displayHideShowButton
	}
}
