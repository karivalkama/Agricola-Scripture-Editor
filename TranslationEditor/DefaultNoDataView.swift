//
//  DefaultNoDataView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.6.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

@IBDesignable class DefaultNoDataView: CustomXibView
{
	// OUTLETS	--------------------
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	
	// COMPUTED PROPERTIES	--------
	
	@IBInspectable var title: String
	{
		get { return titleLabel.text ?? "" }
		set { titleLabel.text = NSLocalizedString(newValue, comment: "An heading for no available data -message") }
	}
	
	@IBInspectable var extraDescription: String
	{
		get { return descriptionLabel.text ?? "" }
		set { descriptionLabel.text = NSLocalizedString(newValue, comment: "a description for no available data -message") }
	}
	
	
	// LOAD	------------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "DefaultNoDataView")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "DefaultNoDataView")
	}
}
