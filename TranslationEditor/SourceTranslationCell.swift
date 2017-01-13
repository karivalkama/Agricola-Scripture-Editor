//
//  SourceTranslationCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Source translation cells are simpler than target translation cells since they cannot be manually edited
class SourceTranslationCell: TranslationCell
{
	// OUTLETS	---------------
	
	@IBOutlet weak var sourceTextView: UITextView!
	
	
	// IMPLEMENTED METHODS	--
	
	override func awakeFromNib()
	{
		super.awakeFromNib()
		
		textView = sourceTextView
	}
}
