//
//  AvatarCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 22.2.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This collection view cell is used for displaying and selecting avatar to log in with
class AvatarCell: UICollectionViewCell
{
    // OUTLETS	------------------
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var avatarImageView: UIImageView!
	
	
	// ATTRIBUTES	--------------
	
	static let identifier = "AvatarCell"
	
	
	// OTHER METHODS	----------
	
	func configure(avatarName: String, avatarImage: UIImage?)
	{
		nameLabel.text = avatarName
		avatarImageView.image = avatarImage.or(#imageLiteral(resourceName: "userIcon"))
	}
}
