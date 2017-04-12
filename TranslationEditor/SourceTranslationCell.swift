//
//  SourceTranslationCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Source translation cells are simpler than target translation cells since they cannot be manually edited
class SourceTranslationCell: UITableViewCell, ParagraphAssociated
{
	// OUTLETS	---------------
	
	@IBOutlet weak var sourceTextView: UITextView!
	
	
	// ATTRIBUTES	-----------
	
	static let identifier = "sourceCell"
	private(set) var pathId: String?
	
	
	// IMPLEMENTED METHODS	--
	
	// Configures the cell to display correct paragraph's data
	func configure(paragraph: Paragraph)
	{
		pathId = paragraph.pathId
		sourceTextView.display(paragraph: paragraph)
	}
}
