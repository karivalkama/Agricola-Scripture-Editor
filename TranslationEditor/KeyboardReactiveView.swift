//
//  KeyboardReactiveView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 12.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

enum ReactionStyle
{
	case slide
	case squish
}

// TODO: On slide mode, activate height constraint

class KeyboardReactiveView: UIView
{
	// ATTRIBUTES	-------------
	
	private weak var mainView: UIView!
	private var _importantElements = [Weak<UIView>]()
	private var importantElements: [UIView]
	{
		get
		{
			return _importantElements.flatMap { $0.value }
		}
		set
		{
			_importantElements = newValue.weakReference
		}
	}
	
	private var margin: CGFloat = 16
	private weak var topConstraint: NSLayoutConstraint?
	private weak var bottomConstraint: NSLayoutConstraint?
	
	private var observers = [Any]()
	private var totalRaise: CGFloat = 0
	private var style = ReactionStyle.slide
	
	private var keyboardIsShown = false
	
	private var topMarginBeforeSquish: CGFloat?
	private var disabledTopConstraint: NSLayoutConstraint? // Strong temporary storage for disabled constraint
	
	
	// COPUTED PROPERTIES	-----
	
	private var firstResponderElement: UIView? { return importantElements.first(where: { $0.isFirstResponder }) }
	
	
	// IMPLEMENTED METHODS	----
	
	deinit
	{
		endKeyboardListening()
	}
	
	
	// OTHER METHODS	--------
	
	func configure(mainView: UIView, elements: [UIView], topConstraint: NSLayoutConstraint? = nil, bottomConstraint: NSLayoutConstraint? = nil, style: ReactionStyle = .slide, margin: CGFloat = 16)
	{
		self.mainView = mainView
		self.importantElements = elements
		self.topConstraint = topConstraint
		self.bottomConstraint = bottomConstraint
		self.margin = margin
		self.style = style
	}
	
	// Starts listening to keyboard state changes
	func startKeyboardListening()
	{
		if observers.isEmpty
		{
			let didShowObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: nil, using: onKeyboardShow)
			
			let didHideObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardDidHide, object: nil, queue: nil)
			{
				_ in
				self.keyboardIsShown = false
				self.lowerView()
			}
			
			observers = [didShowObserver, didHideObserver]
		}
	}
	
	// Stops listening for keyboard state changes
	func endKeyboardListening()
	{
		observers.forEach { NotificationCenter.default.removeObserver($0) }
		observers = []
	}
	
	private func onKeyboardShow(_ notification: Notification)
	{
		guard !keyboardIsShown else
		{
			return
		}
		
		keyboardIsShown = true
		
		guard let keyboardSize = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? CGRect else
		{
			return
		}
		
		// If there are no important elements to display, doesn't need to react to keyboard display
		guard !importantElements.isEmpty else
		{
			return
		}
		
		// let originalY = mainView.frame.origin.y - totalRaise
		let keyboardY = mainView.frame.height - keyboardSize.height
		let visibleAreaHeight = keyboardY
		
		let contentBottomY = importantElements.map { $0.frame(in: mainView).maxY }.max()!
		// print("STATUS: Content bottom Y: \(contentBottomY)")
		
		// In case all the elements are above the keyboard treshold, doesn't need to have the view raised
		guard contentBottomY > visibleAreaHeight else
		{
			// print("STATUS: All content fits into view naturally -> lowers view")
			lowerView()
			return
		}
		
		// Next tries to fit all elements to the remaining visible area
		let contentTopY = importantElements.map { $0.frame(in: mainView).minY }.min()!
		let contentHeight = contentBottomY - contentTopY
		
		if visibleAreaHeight > contentHeight
		{
			// If all elements could fit, checks if there is enough room for margins
			if visibleAreaHeight > contentHeight + 2 * margin
			{
				// In which case leaves a margin below the bottom element
				setRaise(to: contentBottomY + margin - keyboardY)
			}
			else
			{
				// If there wasn't enough room for margins, centers the important area on the visible view
				setRaise(to: contentBottomY - keyboardY + (visibleAreaHeight - contentHeight) / 2)
			}
		}
		else
		{
			// If the components cannot be fit, either
			// a) slides so that some of the elements are outside of visible area
			// or b) Just squishes the top and slides as much as necessary to show the lowest components
			if style == .slide
			{
				// If all the components cannot be fit on the visible area checks if any of the views is currently in focus / first reponder
				if let firstResponderElement = firstResponderElement
				{
					let firstResponderTop = firstResponderElement.frame(in: mainView).minY
					let firstResponderBottom = firstResponderElement.frame(in: mainView).maxX
					let maxRaise = firstResponderTop - margin
					
					// If there is a first responder element, checks whether the first responder element should be made more visible
					if firstResponderBottom + margin > visibleAreaHeight + totalRaise
					{
						// Moves the view until the element is visible. Makes sure the top of the element stays visible too
						setRaise(to: max(firstResponderBottom + margin, maxRaise))
					}
						// Also checks if the view is raised too much for the element to show properly
					else if totalRaise > maxRaise
					{
						setRaise(to: maxRaise)
					}
				}
				else
				{
					// If any of the views wasn't the first responder, raises the view as much as possible without hiding the top element(s)
					let minRaise = contentTopY - margin
					if totalRaise < minRaise
					{
						setRaise(to: minRaise)
					}
				}
			}
			else
			{
				setRaise(to: contentBottomY - keyboardY + margin)
			}
		}
	}
	
	private func setRaise(to raise: CGFloat)
	{
		raiseView(by: raise - totalRaise)
	}
	
	private func raiseView(by raise: CGFloat)
	{
		totalRaise += raise
		
		UIView.animate(withDuration: 0.5)
		{
			if let bottomConstraint = self.bottomConstraint
			{
				bottomConstraint.constant += raise
				
				if let topConstraint = self.topConstraint ?? self.disabledTopConstraint
				{
					// When on squish style, also alters the top constraint
					if self.style == .squish
					{
						// When lowered, returns the original form
						if self.totalRaise <= 0, let originalTopMargin = self.topMarginBeforeSquish
						{
							topConstraint.constant = originalTopMargin
							self.topMarginBeforeSquish = nil
						}
						else if self.topMarginBeforeSquish == nil
						{
							self.topMarginBeforeSquish = topConstraint.constant
							topConstraint.constant = self.margin
						}
					}
					else
					{
						// On slide style, the top constraint is disabled while sliding
						if self.totalRaise <= 0, let disabledTopConstraint = self.disabledTopConstraint
						{
							NSLayoutConstraint.activate([disabledTopConstraint])
							self.topConstraint = disabledTopConstraint
							self.disabledTopConstraint = nil
						}
						else if self.disabledTopConstraint == nil
						{
							self.disabledTopConstraint = topConstraint
							NSLayoutConstraint.deactivate([topConstraint])
						}
					}
				}
			}
			else
			{
				self.topConstraint?.constant -= raise
			}
			self.mainView.layoutIfNeeded()
		}
	}
	
	private func lowerView()
	{
		//print("STATUS: Setting view to original state")
		setRaise(to: 0)
	}
}
