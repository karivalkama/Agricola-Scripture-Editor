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
	@IBOutlet weak var showCollapseImageView: UIImageView!
	
	
	// ATTRIBUTES	----------
	
	static let identifier = "ThreadCell"
	
	private(set) var thread: NotesThread!
	private(set) var pathId: String?
	
	
	// ACTIONS	--------------
	
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
	
	func setContent(thread: NotesThread, pathId: String, showsPosts: Bool)
	{
		self.pathId = pathId
		self.thread = thread
		
		nameLabel.text = thread.name
		
		resolveButton.isEnabled = !thread.isResolved
		flagImageView.isHidden = thread.isResolved
		showCollapseImageView.image = showsPosts ? #imageLiteral(resourceName: "arrowdown") : #imageLiteral(resourceName: "arrowright")
	}
}
