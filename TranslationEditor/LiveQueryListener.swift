//
//  LiveQueryListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 7.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This protocol is implemented by objects interested in real time database content changes
protocol LiveQueryListener: class
{
	// The type of the objects the object is using
	associatedtype Queried: Storable
	
	// This method is called each time the results of the live query update
	// The queryId is used for differentiating between different queries
	func rowsUpdated(rows: [Row<Queried>], forQuery queryId: String?)
}
