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
	
	private var thread: NotesThread!
	private(set) var pathId: String?
	
	private var visibleListener: NotesShowHideListener!
	private var showStatus = false
	
	private weak var addPostDelegate: AddNotesDelegate!
	
	
	// ACTIONS	--------------
	
	@IBAction func postButtonPressed(_ sender: Any)
	{
		print("Post button pressed")
		// TODO: Add a post
		//addPostDelegate.insertThread(noteId: thread.noteId, pathId: pathId!)
	}
	
	@IBAction func hideShowButtonPressed(_ sender: Any)
	{
		// Informs the visibility listener
		visibleListener?.showHideStatusRequested(forId: thread!.idString, status: !showStatus)
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
	
	func setContent(thread: NotesThread, pathId: String, displayHideShowButton: Bool, useShowOption: Bool, listener: NotesShowHideListener, addDelegate: AddNotesDelegate)
	{
		self.pathId = pathId
		self.thread = thread
		self.visibleListener = listener
		self.showStatus = !useShowOption
		self.addPostDelegate = addDelegate
		
		nameLabel.text = thread.isResolved ? "Resolved: \(thread.name)" : thread.name
		
		resolveButton.isEnabled = thread.isResolved
		flagImageView.isHidden = thread.isResolved
		
		hideShowButton.setTitle(useShowOption ? "Show" : "Hide", for: .normal)
		hideShowButton.isHidden = !displayHideShowButton
	}
}
