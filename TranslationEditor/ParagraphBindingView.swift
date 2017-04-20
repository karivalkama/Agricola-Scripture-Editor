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
	
	static let KEY_CODE = "code"
	static let KEY_TARGET_BOOK = "target"
	static let KEY_SOURCE_BOOK = "source"
	static let KEY_CREATED = "created"
	
	static let instance = ParagraphBindingView()
	static let keyNames = [KEY_CODE, KEY_TARGET_BOOK, KEY_SOURCE_BOOK, KEY_CREATED]
	
	let view: CBLView
	
	
	// INIT	------------------------
	
	private init()
	{
		view = DATABASE.viewNamed("paragraph_bindings")
		view.setMapBlock(createMapBlock
		{
			binding, emit in
			
			let key = [Book.code(fromId: binding.targetBookId).code, binding.targetBookId, binding.sourceBookId, binding.created] as [Any]
			// let value = [binding.idString, binding.created] as [Any]
			
			emit(key, nil)
			
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
			
		}*/, version: "6")
	}
	
	
	// OTHER METHODS	---------
	
	func createQuery(targetBookId: String, sourceBookId: String? = nil) -> MyQuery
	{
		return createQuery(code: Book.code(fromId: targetBookId), targetBookId: targetBookId, sourceBookId: sourceBookId)
	}
	
	// Finds the latest existing binding between the two books
	func latestBinding(from sourceBookId: String, to targetBookId: String) throws -> ParagraphBinding?
	{
		return try createQuery(code: Book.code(fromId: targetBookId), targetBookId: targetBookId, sourceBookId: sourceBookId).firstResultObject()
	}
	
	// Finds all bindings that have the provided book id as either source or target
	func bindings(forBookWithId bookId: String) throws -> [ParagraphBinding]
	{
		return try createQuery(code: Book.code(fromId: bookId), targetBookId: nil, sourceBookId: nil).resultRows().filter { $0.keys[ParagraphBindingView.KEY_TARGET_BOOK]?.string == bookId || $0.keys[ParagraphBindingView.KEY_SOURCE_BOOK]?.string == bookId }.map { try $0.object() }
	}
	
	private func createQuery(code: BookCode?, targetBookId: String?, sourceBookId: String?) -> MyQuery
	{
		let keys = ParagraphBindingView.makeKeys(from: [code?.code, targetBookId, sourceBookId])
		
		var query = createQuery(withKeys: keys)
		query.descending = true
		
		return query
	}
}
