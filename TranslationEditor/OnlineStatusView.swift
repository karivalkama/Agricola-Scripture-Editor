//
//  OnlineStatusView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view is used to display the current online status and transfer progress
class OnlineStatusView: CustomXibView
{
	// OUTLETS	----------
	
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var progressBar: UIProgressView!
	
	
	// ATTRIBUTES	------
	
	private var _status = ConnectionStatus.disconnected
	private var progressTotal = 0
	private var progressComplete = 0
	
	
	// COMP. PROPERTIES	--
	
	var status: ConnectionStatus
	{
		get { return _status }
		set
		{
			_status = newValue
			updateText()
		}
	}
	
	
	// INIT	--------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "OnlineStatusView")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "OnlineStatusView")
	}
	
	
	// OTHER METHODS	--
	
	func updateProgress(completed: Int, of total: Int)
	{
		progressComplete = completed
		progressTotal = total
		updateText()
	}
	
	private func updateText()
	{
		var text = ""
		var ok = true
		
		switch _status
		{
		case .active: text = "Transferring Data"
		case .connecting: text = "Establishing Connection"
		case .disconnected: text = "Not Connected"
		case .offline:
			text = "No Internet Connection"
			ok = false
		case .unauthorized:
			text = "Access Denied"
			ok = false
		case .upToDate: text = "Done"
		}
		
		if progressTotal != progressComplete
		{
			text += " \(progressComplete) / \(progressTotal)"
		}
		
		statusLabel.text = text
		statusLabel.textColor = ok ? Colour.Text.Black.secondary.asColour : Colour.Secondary.asColour
	}
}
