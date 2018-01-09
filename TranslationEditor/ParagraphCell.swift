//
//  ParagraphCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This cell displays text for a single paragraph
class ParagraphCell: UITableViewCell, ParagraphAssociated
{
	// OUTLETS	-----------------
	
	@IBOutlet weak var contentTextView: UITextView!
	
	
	// ATTRIBUTES	-------------
	
	static let identifier = "ParagraphCell"
	
	var pathId: String?
	
	
	// OTHER METHODS	--------
	
	func configure(paragraph: Paragraph)
	{
		pathId = paragraph.pathId
		contentTextView.display(paragraph: paragraph)
	}
}
