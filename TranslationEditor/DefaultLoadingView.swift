//
//  DefaultLoadingView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 15.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This is the default implementation for a view that displays loading status
@IBDesignable class DefaultLoadingView: CustomXibView
{
	// OUTLETS	--------------------
	
	@IBOutlet weak var titleLabel: UILabel!
	
	
	// COMPUTED PROPERTIES	--------
	
	var title: String
	{
		get { return titleLabel.text ?? "" }
		set { titleLabel.text = NSLocalizedString(newValue, comment: "A label describing loading screen status") }
	}
	
	
	// LOAD	------------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "DefaultLoadingView")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "DefaultLoadingView")
	}
}
