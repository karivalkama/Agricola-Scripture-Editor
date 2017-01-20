//
//  NotesShowHideListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Classes implementing this protocol are informed about notes hide and show requests
protocol NotesShowHideListener
{
	// This method will be called when either show or hide status is requested by a client
	func showHideStatusRequested(forId id: String, status: Bool)
}
