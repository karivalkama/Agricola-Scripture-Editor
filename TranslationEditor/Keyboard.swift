//
//  Keyboard.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This singular instance keeps track of when the virtual keyboard is displayed and when not
class Keyboard: AppStatusListener
{
	// ATTRIBUTES	-------------
	
	static let instance = Keyboard()
	
	private(set) var isVisible = false
	private(set) var height: CGFloat = 0
	
	private var observers = [Any]()
	
	
	// INIT	---------------------
	
	// Init hidden from other classes
	private init()
	{
		print("STATUS: Keyboard interface initialized")
		startKeyboardListening()
		AppStatusHandler.instance.registerListener(self)
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func appWillClose()
	{
		endKeyboardListening()
	}
	
	func appWillContinue()
	{
		startKeyboardListening()
	}
	
	
	// OTHER METHODS	--------
	
	private func startKeyboardListening()
	{
		if observers.isEmpty
		{
			let didShowObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardDidShow, object: nil, queue: nil)
			{
				notification in
				
				self.isVisible = true
				print("STATUS: Keyboard appeared")
				
				// Retrieves the keyboard's height too
				if let keyboardSize = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? CGRect
				{
					self.height = keyboardSize.height
				}
			}
			let didHideObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardDidHide, object: nil, queue: nil)
			{
				_ in
				self.isVisible = false
				print("STATUS: Keyboard disappeared")
			}
			
			observers = [didShowObserver, didHideObserver]
		}
	}
	
	private func endKeyboardListening()
	{
		observers.forEach { NotificationCenter.default.removeObserver($0) }
		observers = []
	}
}
