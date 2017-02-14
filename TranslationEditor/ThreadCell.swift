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
	@IBOutlet weak var showCollapseImageView: UIImageView!
	@IBOutlet weak var openSwitch: UISwitch!
	
	
	// ATTRIBUTES	----------
	
	static let identifier = "ThreadCell"
	
	private(set) var thread: NotesThread!
	private(set) var pathId: String?
	
	
	// ACTIONS	--------------
	
	@IBAction func openStateChanged(_ sender: Any)
	{
		// Marks the thread either as resolved or as unresolved, based on the new state
		do
		{
			try thread.setResolved(!openSwitch.isOn)
		}
		catch
		{
			print("ERROR: Failed to update thread's resolved status")
		}
	}
	
	
	// OTHER METHODS	-----
	
	func setContent(thread: NotesThread, pathId: String, showsPosts: Bool)
	{
		self.pathId = pathId
		self.thread = thread
		
		nameLabel.text = thread.name
		
		openSwitch.setOn(!thread.isResolved, animated: false)
		flagImageView.isHidden = thread.isResolved
		showCollapseImageView.image = showsPosts ? #imageLiteral(resourceName: "arrowdown") : #imageLiteral(resourceName: "arrowright")
	}
}
