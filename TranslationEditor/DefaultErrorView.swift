//
//  DefaultErrorView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.6.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

@IBDesignable class DefaultErrorView: CustomXibView
{
	// OUTLETS	--------------------
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	
	// COMPUTED PROPERTIES	--------
	
	@IBInspectable var title: String
	{
		get { return titleLabel.text ?? "" }
		set { titleLabel.text = NSLocalizedString(newValue, comment: "An error title / heading") }
	}
	
	@IBInspectable var errorDescription: String
	{
		get { return descriptionLabel.text ?? "" }
		set { descriptionLabel.text = NSLocalizedString(newValue, comment: "An error description") }
	}
	
	
	// LOAD	------------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "DefaultErrorView")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "DefaultErrorView")
	}
}
