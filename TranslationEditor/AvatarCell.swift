//
//  AvatarCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 22.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This collection view cell is used for displaying and selecting avatar to log in with
class AvatarCell: UICollectionViewCell
{
    // OUTLETS	------------------
	
	@IBOutlet weak var nameLabel: UILabel!
	
	
	// OTHER METHODS	----------
	
	func configure(avatarName: String)
	{
		nameLabel.text = avatarName
	}
}
