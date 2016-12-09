//
//  ProgramStatusListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// App status listeners are informed when the program state changes
protocol AppStatusListener: class
{
	// This method will be called when the program is entering background state or terminating
	func appWillClose()
	
	// This method will be called when the program continues its operation
	func appWillContinue()
}
