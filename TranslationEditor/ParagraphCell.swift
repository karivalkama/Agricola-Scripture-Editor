//
//  ParagraphCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This cell displays text for a single paragraph
class ParagraphCell: UITableViewCell
{
	// OUTLETS	-----------------
	
	@IBOutlet weak var contentTextView: UITextView!
	
	
	// ATTRIBUTES	-------------
	
	static let identifier = "ParagraphCell"
	
	
	// OTHER METHODS	--------
	
	func configure(paragraph: Paragraph)
	{
		contentTextView.display(paragraph: paragraph)
	}
}
