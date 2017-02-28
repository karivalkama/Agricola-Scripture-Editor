//
//  CustomXibView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 28.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This is a utility class for views that contain views created within xib files
class CustomXibView: UIView
{
	// ATTRIBUTES	--------------
	
	private var view: UIView!
	
	
	// OTHER METHODS	----------
	
	// This function should be called in the view initializers
	func setupXib(nibName: String)
	{
		view = loadViewFromNib(nibName: nibName)
		view.frame = bounds
		view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
		addSubview(view)
	}
	
	private func loadViewFromNib(nibName: String) -> UIView
	{
		let bundle = Bundle(for: type(of: self))
		let nib = UINib(nibName: nibName, bundle: bundle)
		
		return nib.instantiate(withOwner: self, options: nil)[0] as! UIView
	}
}
