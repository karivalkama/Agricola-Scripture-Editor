//
//  ParagraphBindingView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 11.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This is the view used for querying paragraph binding data
final class ParagraphBindingView: View
{
	// TYPES	--------------------
	
	typealias Queried = ParagraphBinding
	typealias MyQuery = Query<ParagraphBindingView>
	
	
	// ATTRIBUTES	----------------
	
	static let KEY_TARGET_BOOK = "target"
	static let KEY_SOURCE_BOOK = "souce"
	static let KEY_CREATED = "created"
	
	static let instance = ParagraphBindingView()
	static let keyNames = [KEY_TARGET_BOOK, KEY_SOURCE_BOOK, KEY_CREATED]
	
	let view: CBLView
	
	
	// INIT	------------------------
	
	private init()
	{
		view = DATABASE.viewNamed("paragraph_bindings")
		view.setMapBlock(createMapBlock
		{
			binding, emit in
			
			let key = [binding.targetBookId, binding.sourceBookId, binding.created] as [Any]
			let value = [binding.idString, binding.created] as [Any]
			
			emit(key, value)
			
		}/*, reduce:
		{
			// Finds the most recent id
			keys, values, rereduce in
			
			var mostRecentId = ""
			var mostRecentTime = 0.0
			
			for value in values
			{
				let value = value as! [Any]
				let created = value[1] as! TimeInterval
				
				if created > mostRecentTime
				{
					let id = value[0] as! String
					mostRecentId = id
					mostRecentTime = created
				}
			}
			
			return [mostRecentId, mostRecentTime]
			
		}*/, version: "4")
	}
	
	
	// OTHER METHODS	---------
	
	// Finds the latest existing binding between the two books
	func latestBinding(from sourceBookId: String, to targetBookId: String) throws -> ParagraphBinding?
	{
		return try createQuery(deprecated: false, targetBookId: targetBookId, sourceBookId: sourceBookId).firstResultObject()
	}
	
	// TODO: Add other methods as necessary
	// TODO: Add function for deprecating bindings between two books (called when structure changes)
	
	private func createQuery(deprecated: Bool, targetBookId: String?, sourceBookId: String?) -> MyQuery
	{
		let keys = [ParagraphBindingView.KEY_TARGET_BOOK: Key(targetBookId),
		            ParagraphBindingView.KEY_SOURCE_BOOK: Key(sourceBookId)
		]
		
		var query = createQuery(withKeys: keys)
		query.descending = true
		
		return query
	}
}
