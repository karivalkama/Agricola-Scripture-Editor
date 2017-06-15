//
//  DefaultLoadingView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 15.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This is the default implementation for a view that displays loading status
class DefaultLoadingView: CustomXibView
{
	// OUTLETS	--------------------
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var progressBar: UIProgressView!
	
	
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
	
	
	// OTHER METHODS	------------
	
	func setTitle(_ title: String)
	{
		titleLabel.text = NSLocalizedString(title, comment: "A label describing loading screen status")
	}
	
	func setProgress(_ progress: Double)
	{
		progressBar.progress = Float(progress)
		progressBar.isHidden = false
	}
}
