//
//  OnlineStatusView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
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
		case .active: text = "Transferring"
		case .connecting: text = "Establishing Connection"
		case .disconnected: text = "Not Connected"
		case .offline: text = "No Internet Connection"
		case .unauthorized: text = "Access Denied"
		case .upToDate: text = "Waiting for Updates"
		case .done: text = "Transfer Complete"
		case .failed: text = "Transfer Failed"
		}
		
		if progressTotal != progressComplete
		{
			text += " \(progressComplete) / \(progressTotal)"
		}
		
		statusLabel.text = text
		statusLabel.textColor = _status.isError ? Colour.Secondary.asColour : Colour.Text.Black.secondary.asColour
	}
}
