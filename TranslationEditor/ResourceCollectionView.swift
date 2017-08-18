//
//  ResourceCollectionView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

final class ResourceCollectionView: View
{
	// TYPES	-------------------
	
	typealias Queried = ResourceCollection
	typealias MyQuery = Query<ResourceCollectionView>
	
	
	// ATTRIBUTES	---------------
	
	static let KEY_PROJECT = "project"
	static let KEY_BOOK = "book"
	static let KEY_CATEGORY = "category"
	static let KEY_NAME = "name"
	
	static let instance: ResourceCollectionView = ResourceCollectionView()
	static let keyNames = [KEY_PROJECT, KEY_BOOK, KEY_CATEGORY, KEY_NAME]
	
	let view = DATABASE.viewNamed("resource_collection_view")
	
	
	// INIT	-----------------------
	
	private init()
	{
		view.setMapBlock(createMapBlock
		{
			collection, emit in
			
			// Key = project id, book id, category (raw), name
			let key: [Any] = [Book.projectId(fromId: collection.bookId), collection.bookId, collection.category.rawValue, collection.name]
			emit(key, nil)
			
		}, version: "3")
	}
	
	
	// OTHER METHODS	----------
	
	func collectionQuery(bookId: String, category: ResourceCategory? = nil, name: String? = nil) -> MyQuery
	{
		let keys = ResourceCollectionView.makeKeys(from: [Book.projectId(fromId: bookId), bookId, category?.rawValue, name])
		return createQuery(withKeys: keys)
	}
	
	func collectionQuery(projectId: String) -> MyQuery
	{
		return createQuery(withKeys: ResourceCollectionView.makeKeys(from: [projectId]))
	}
}
