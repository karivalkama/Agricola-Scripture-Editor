//
//  TopUserView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view displays basic user data
@IBDesignable class TopUserView: CustomXibView
{
	// OUTLETS	----------------
	
	@IBOutlet weak var userNameField: UILabel!
	@IBOutlet weak var userImage: UIImageView!
	
	
	// ATTRIBUTES	------------
	
	@IBInspectable var textColor: UIColor?
	
	
	// INIT	--------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "TopUserDisplay")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "TopUserDisplay")
	}
	
	
	// OTHER METHODS	--------
	
	// Sets up the correct data for the view
	func configure(userName: String, userIcon: UIImage)
	{
		userNameField.text = userName
		userImage.image = userIcon
	}
	
	// Alternative way to configure the view
	func configure(avatarId: String) throws
	{
		if let avatar = try Avatar.get(avatarId)
		{
			configure(userName: avatar.name, userIcon: (try avatar.info()?.image).or(#imageLiteral(resourceName: "userIcon")))
		}
	}
}
