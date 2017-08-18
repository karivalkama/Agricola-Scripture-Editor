//
//  ParseSuccessCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 22.6.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

class ParseSuccessCell: UITableViewCell
{
	// OUTLETS	---------------------
	
	@IBOutlet weak var bookCodeLabel: UILabel!
	@IBOutlet weak var bookIdentifierLabel: UILabel!
	@IBOutlet weak var foundOlderVersionLabel: UILabel!
	
	
	// ATTRIBUTES	-----------------
	
	static let identifier = "ParseSuccessCell"
	
	
	// OTHER METHODS	-------------
	
	func configure(code: BookCode, identifier: String, didFindOlderVersion: Bool = false)
	{
		bookCodeLabel.text = code.name
		bookIdentifierLabel.text = identifier
		foundOlderVersionLabel.isHidden = !didFindOlderVersion
	}
}
