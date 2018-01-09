//
//  LiveResource.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This protocol is implemented by all resources and resource managers that use live updating
protocol LiveResource
{
	// (Re)starts the live update actions
	func activate()
	
	// Pauses the live update actions to save resources
	func pause()
}
