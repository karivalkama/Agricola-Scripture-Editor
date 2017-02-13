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
	
	static let identifier = "ThreadCell"
	
	private var thread: NotesThread!
	private(set) var pathId: String?
	
	private var visibleListener: ThreadShowHideListener!
	private var showStatus = false
	
	private weak var addPostDelegate: AddNotesDelegate!
	
	
	// ACTIONS	--------------
	
	@IBAction func postButtonPressed(_ sender: Any)
	{
		addPostDelegate.insertPost(threadId: thread.idString)
	}
	
	@IBAction func hideShowButtonPressed(_ sender: Any)
	{
		// Informs the visibility listener
		// TODO: Use selection listening instead
		visibleListener?.showHideStatusRequested(forThreadId: thread!.idString, status: !showStatus)
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
	
	func setContent(thread: NotesThread, pathId: String, displayHideShowButton: Bool, useShowOption: Bool, listener: ThreadShowHideListener, addDelegate: AddNotesDelegate)
	{
		self.pathId = pathId
		self.thread = thread
		self.visibleListener = listener
		self.showStatus = !useShowOption
		self.addPostDelegate = addDelegate
		
		nameLabel.text = thread.name
		
		resolveButton.isEnabled = !thread.isResolved
		flagImageView.isHidden = thread.isResolved
		
		hideShowButton.setTitle(useShowOption ? "Show" : "Hide", for: .normal)
		hideShowButton.isHidden = !displayHideShowButton
	}
}
