//
//  AnyLiveQueryListener.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 8.12.2016.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// This is the erasure implementation for protocol: LiveQueryListener
class AnyLiveQueryListener<V: View>: LiveQueryListener
{
	// TYPES	---------
	
	typealias QueryTarget = V
	
	
	// PROPERTIES	-----
	
	private var _rowsUpdated: ([Row<V>]) -> ()
	
	
	// INIT	-------------
	
	init<L : LiveQueryListener>(_ listener: L) where L.QueryTarget == V
	{
		_rowsUpdated = listener.rowsUpdated
	}
	
	
	// LISTENER	--------
	
	func rowsUpdated(rows: [Row<V>])
	{
		_rowsUpdated(rows)
	}
}
