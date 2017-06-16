//
//  ConnectPromptNoDataView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

class ConnectPromptNoDataView: CustomXibView
{
	// OUTLETS	---------------------
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet weak var connectPromptView: ConnectPromptView!
	
	
	// COMPUTED PROPERTIES	---------
	
	var title: String
	{
		get { return titleLabel.text ?? "" }
		set { titleLabel.text = NSLocalizedString(newValue, comment: "A title label for no data situation where connecting with others usually helps") }
	}
	
	var hint: String
	{
		get { return descriptionLabel.text ?? "" }
		set { descriptionLabel.text = NSLocalizedString(newValue, comment: "A descriptive label for no data situation where connecting with others usually helps") }
	}
	
	var connectButtonAction: (() -> ())?
	{
		get { return connectPromptView.connectButtonAction }
		set { connectPromptView.connectButtonAction = newValue }
	}
	
	
	// LOAD	-------------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "ConnectPromptNoDataView")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "ConnectPromptNoDataView")
	}
}
