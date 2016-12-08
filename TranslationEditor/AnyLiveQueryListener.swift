//
//  AnyLiveQueryListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This is the erasure implementation for protocol: LiveQueryListener
class AnyLiveQueryListener<T: Storable>: LiveQueryListener
{
	// TYPES	---------
	
	typealias Queried = T
	
	
	// PROPERTIES	-----
	
	private var _rowsUpdated: ([Row<T>], String?) -> ()
	
	
	// INIT	-------------
	
	init<L : LiveQueryListener>(_ listener: L) where L.Queried == T
	{
		_rowsUpdated = listener.rowsUpdated
	}
	
	
	// LISTENER	--------
	
	func rowsUpdated(rows: [Row<T>], forQuery queryId: String?)
	{
		_rowsUpdated(rows, queryId)
	}
}
