//
//  ConnectPromptView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.6.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

@IBDesignable class ConnectPromptView: CustomXibView
{
	// ATTRIBUTES	-----------------
	
	var connectButtonAction: (() -> ())?
	
	
	// LOAD	-------------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "ConnectPromptView")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "ConnectPromptView")
	}
	
	
	// ACTIONS	--------------------
	
	@IBAction func connectButtonPressed(_ sender: Any)
	{
		connectButtonAction?()
	}
}
