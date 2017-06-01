//
//  ChapterHeaderCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 1.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

class ChapterHeaderCell: UITableViewCell
{
	// OUTLETS	-------------------
	
	@IBOutlet weak var chapterLabel: UILabel!
	
	static let identifier = "ChapterHeaderCell"
	
	
	// OTHER METHODS	-----------
	
	func configure(chapterIndex: Int)
	{
		chapterLabel.text = "\(NSLocalizedString("Chapter", comment: "A Bible chapter")) \(chapterIndex))"
	}
}
