//
//  NotesShowHideListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Classes implementing this protocol are informed about notes thread hide and show requests
protocol ThreadShowHideListener
{
	// This method will be called when either show or hide status is requested by a client
	func showHideStatusRequested(forThreadId id: String, status: Bool)
}
