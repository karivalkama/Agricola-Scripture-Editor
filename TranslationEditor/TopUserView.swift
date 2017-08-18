//
//  TopUserView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 24.3.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This view displays basic user data
@IBDesignable class TopUserView: CustomXibView
{
	// OUTLETS	----------------
	
	@IBOutlet weak var userNameField: UILabel!
	@IBOutlet weak var userImage: UIImageView!
	@IBOutlet weak var projectNameLabel: UILabel!
	
	
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
	
	// LOAD	--------------------
	
	override func awakeFromNib()
	{
		if let textColor = textColor
		{
			userNameField.textColor = textColor
			projectNameLabel.textColor = textColor
		}
	}
	
	
	// OTHER METHODS	--------
	
	func configure(projectName: String, username: String, image: UIImage? = nil)
	{
		userNameField.text = username
		projectNameLabel.text = projectName
		userImage.image = image
	}
	
	// Sets up the correct data for the view
	@available(*, deprecated)
	func configure(userName: String, userIcon: UIImage)
	{
		userNameField.text = userName
		userImage.image = userIcon
	}
	
	// Alternative way to configure the view
	@available(*, deprecated)
	func configure(avatarId: String) throws
	{
		if let avatar = try Avatar.get(avatarId)
		{
			configure(userName: avatar.name, userIcon: (try avatar.info()?.image).or(#imageLiteral(resourceName: "userIcon")))
		}
	}
}
