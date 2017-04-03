//
//  UIUtilities.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

extension UIButton
{
	// Adjusts the button's color theme
	func setVisualTheme(_ theme: Theme)
	{
		backgroundColor = theme.colour
		
		titleLabel?.textColor = theme.textColour
		tintColor = theme.textColour
		setTitleColor(theme.textColour, for: .normal)
		setTitleColor(theme.textColour, for: .disabled)
	}
}

extension UIViewController
{
	// Displays another view controller modally over this one
	// The configurer function is called before the new view controller is presented
	func displayAlert(withIdentifier alertId: String, storyBoardId: String, using configurer: ((UIViewController) -> ())? = nil)
	{
		let storyboard = UIStoryboard(name: storyBoardId, bundle: nil)
		let myAlert = storyboard.instantiateViewController(withIdentifier: alertId)
		myAlert.modalPresentationStyle = .overCurrentContext
		myAlert.modalTransitionStyle = .crossDissolve
		
		configurer?(myAlert)
		
		present(myAlert, animated: true, completion: nil)
	}
}
