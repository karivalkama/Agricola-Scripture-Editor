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
	
	static let KEY_DEPRECATED = "deprecated"
	static let KEY_TARGET_BOOK = "target"
	static let KEY_SOURCE_BOOK = "souce"
	static let KEY_CREATED = "created"
	
	static let instance = ParagraphBindingView()
	static let keyNames = [KEY_DEPRECATED, KEY_TARGET_BOOK, KEY_SOURCE_BOOK, KEY_CREATED]
	
	let view: CBLView
	
	
	// INIT	------------------------
	
	private init()
	{
		view = DATABASE.viewNamed("paragraph_bindings")
		view.setMapBlock(createMapBlock
		{
			binding, emit in
			
			let key = [binding.isDeprecated, binding.targetBookId, binding.sourceBookId, binding.created] as [Any]
			let value = (binding.idString, binding.created)
			
			emit(key, value)
			
		}, reduce:
		{
			// Finds the most recent id
			keys, values, rereduce in
			
			var mostRecent = values.first as! (String, TimeInterval)
			for value in values
			{
				let value = value as! (String, TimeInterval)
				if value.1 > mostRecent.1
				{
					mostRecent = value
				}
			}
			
			return mostRecent
			
		}, version: "1")
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
		let keys = [ParagraphBindingView.KEY_DEPRECATED: Key(deprecated),
		            ParagraphBindingView.KEY_TARGET_BOOK: Key(targetBookId),
		            ParagraphBindingView.KEY_SOURCE_BOOK: Key(sourceBookId),
		            ParagraphBindingView.KEY_CREATED: Key.undefined]
		
		var query = createQuery(withKeys: keys)
		query.descending = true
		
		return query
	}
}
