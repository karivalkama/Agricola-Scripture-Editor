//
//  BookProgressUIView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This UIView is used for displaying book progress
@IBDesignable class BookProgressUIView: CustomXibView
{
	// OUTLETS	----------------
	
	@IBOutlet weak var completionLabel: UILabel!
	@IBOutlet weak var versionAmountLabel: UILabel!
	@IBOutlet weak var progressBar: UIProgressView!
	
	
	// INIT	--------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "BookProgressUIView")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "BookProgressUIView")
	}
	
	
	// OTHER METHODS	--------
	
	func configure(status: BookProgressStatus)
	{
		completionLabel.text = "\(Int((status.fullness * 100).rounded())) %"
		versionAmountLabel.text = "~\(Int(status.averageCommitsPerVerse.rounded())) Versions"
		progressBar.progress = Float(status.fullness)
	}
}
