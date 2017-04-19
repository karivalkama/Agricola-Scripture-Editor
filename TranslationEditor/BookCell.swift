//
//  BookCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This cell is used for selecting a book in the main menu
// It also contains export feature
class BookCell: UITableViewCell
{
	// OUTLETS	-----------------
	
	@IBOutlet weak var codeLabel: UILabel!
	@IBOutlet weak var bookNameLabel: UILabel!
	@IBOutlet weak var sendButton: UIButton!
	
	
	// ATTRIBUTES	------------
	
	static let identifier = "BookCell"
	
	private var sendAction: ((BookCell) -> ())?
	
	
	// ACTIONS	-----------------
	
	@IBAction func sendButtonPressed(_ sender: Any)
	{
		sendAction?(self)
	}
	
	
	// OTHER METHODS	---------
	
	// Configures the cell to display correct data
	func configure(bookCode: BookCode, identifier: String, sendActionAvailable: Bool, sendAction: @escaping (BookCell) -> ())
	{
		codeLabel.text = bookCode.name
		bookNameLabel.text = identifier
		sendButton.isEnabled = sendActionAvailable
		self.sendAction = sendAction
	}
}
