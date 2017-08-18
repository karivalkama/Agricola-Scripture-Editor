//
//  BookCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This cell is used for selecting a book in the main menu
// It also contains export feature
class BookCell: UITableViewCell
{
	// OUTLETS	-----------------
	
	@IBOutlet weak var codeLabel: UILabel!
	@IBOutlet weak var bookNameLabel: UILabel!
	@IBOutlet weak var progressView: BookProgressUIView!
	
	
	// ATTRIBUTES	------------
	
	static let identifier = "BookCell"
	
	
	// OTHER METHODS	---------
	
	// Configures the cell to display correct data
	func configure(bookCode: BookCode, identifier: String, progress: BookProgressStatus?)
	{
		codeLabel.text = bookCode.name
		bookNameLabel.text = identifier
		
		if let progress = progress
		{
			progressView.configure(status: progress)
			progressView.isHidden = false
		}
		else
		{
			progressView.isHidden = true
		}
	}
}
