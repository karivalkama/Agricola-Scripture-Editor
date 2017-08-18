//
//  StackDismissable.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 31.3.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This protocol is intended to be used and conformed by view controllers
// Sometimes these views want to be skipped when presenting view controllers deeper in the stack
protocol StackDismissable
{
	// This attribute tells whether the view controller wishes to be skipped instead of being presented
	// when one would present it after dismissing a view above it
	var shouldDismissBelow: Bool { get }
	
	// This method should be called before actually dismissing / skipping this view controller
	func willDissmissBelow()
}

extension StackDismissable where Self: UIViewController
{	
	// Dismisses this view controller and possibly other view controllers below that
	func dismissFromAbove()
	{
		miss(viewController: self)
	}
}

fileprivate func miss(viewController: UIViewController)
{
	// Checks if should dismiss
	if let stackDismissable = viewController as? StackDismissable, stackDismissable.shouldDismissBelow
	{
		// Informs the VC
		stackDismissable.willDissmissBelow()
		
		// Dismisses the presenting view controller, or if this is the bottom, this controller
		if let presentingController = viewController.presentingViewController
		{
			viewController.dismiss(animated: true, completion: nil)
			miss(viewController: presentingController)
		}
		else
		{
			viewController.dismiss(animated: true, completion: nil)
		}
	}
	else
	{
		viewController.dismiss(animated: true, completion: nil)
	}
}
