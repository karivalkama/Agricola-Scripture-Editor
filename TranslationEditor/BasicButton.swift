//
//  BasicButton.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.12.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

// This is the base class for basic UI buttons
// The class handles basic colour scheme for enabled and disabled buttons
class BasicButton: UIButton
{
	// PROPERTIES	-----------
	
	private var _isAccessory = false
	@IBInspectable var isAccessory: Bool
	{
		get { return _isAccessory }
		set
		{
			_isAccessory = newValue
			setVisualTheme(theme)
		}
	}
	
	
	// COMP. PROPERTIES	-------
	
	override var isEnabled: Bool
	{
		get {return super.isEnabled}
		set
		{
			super.isEnabled = newValue
			setVisualTheme(theme)
		}
	}
	
	var theme: Theme
	{
		if _isAccessory
		{
			return isEnabled ? Themes.Accessory.normal : Themes.Accessory.disabled
		}
		else
		{
			return isEnabled ? Themes.Primary.normal : Themes.Primary.disabled
		}
	}
	
	
	// IMPLEMENTED	----------
	
	override func awakeFromNib()
	{
		super.awakeFromNib()
		
		setVisualTheme(theme)
	}
	
	override func layoutSubviews()
	{
		super.layoutSubviews()
		roundCorners(intensity: 0.2)
	}
}
