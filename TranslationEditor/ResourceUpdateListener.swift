//
//  ResourceUpdateListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 11.5.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// Objects conforming to this protocol can be informed when available resources are changed / updated
protocol ResourceUpdateListener: class
{
	// This function will be called when the resources get updated
	// The labels describe the new available resource options
	func onResourcesUpdated(optionLabels: [String])
}
