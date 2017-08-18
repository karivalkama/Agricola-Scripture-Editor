//
//  OnlineStatusView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.2.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This view is used to display the current online status and transfer progress
@IBDesignable class OnlineStatusView: CustomXibView
{
	// OUTLETS	----------
	
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var progressBar: UIProgressView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	
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
			if newValue.isFinal
			{
				activityIndicator.stopAnimating()
				progressComplete = progressTotal
				progressBar.progress = 1
			}
			else
			{
				activityIndicator.startAnimating()
			}
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
	
	func updateProgress(completed: Int, of total: Int, progress: Double)
	{
		progressBar.progress = Float(progress)
		
		progressComplete = completed
		progressTotal = total
		updateText()
	}
	
	private func updateText()
	{
		var text = ""
		
		switch _status
		{
		case .active: text = NSLocalizedString("Transferring", comment: "Online status when data is being transferred between devices")
		case .connecting: text = NSLocalizedString("Establishing Connection", comment: "Online status while the system is connecting")
		case .disconnected: text = NSLocalizedString("Off", comment: "Online status when connection is disconnected and there are no attempts of changing it")
		case .offline: text = NSLocalizedString("No Connection", comment: "Online status when connection is offline")
		case .unauthorized: text = NSLocalizedString("Access Denied", comment: "Online status when provided credentials don't match the required")
		case .upToDate: text = NSLocalizedString("Waiting for Updates", comment: "Online status when the connection is up to date")
		case .done: text = NSLocalizedString("Transfer Complete", comment: "Online status when a single time transaction has been completed")
		case .failed: text = NSLocalizedString("Transfer Failed", comment: "Online status when a single time transaction failed with an error")
		}
		
		if progressTotal != progressComplete
		{
			text += " \(progressComplete) / \(progressTotal)"
		}
		
		statusLabel.text = text
		statusLabel.textColor = _status.isError ? Colour.Secondary.asColour : Colour.Text.Black.secondary.asColour
	}
}
