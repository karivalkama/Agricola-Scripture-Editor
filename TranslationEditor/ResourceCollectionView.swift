//
//  ResourceCollectionView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class ResourceCollectionView: View
{
	// TYPES	-------------------
	
	typealias Queried = ResourceCollection
	
	
	// ATTRIBUTES	---------------
	
	static let KEY_BOOK = "book"
	static let KEY_LANGUAGE = "language"
	static let KEY_CATEGORY = "category"
	static let KEY_NAME = "name"
	
	static let instance: ResourceCollectionView = ResourceCollectionView()
	static let keyNames = [KEY_BOOK, KEY_LANGUAGE, KEY_CATEGORY, KEY_NAME]
	
	let view: CBLView
	
	
	// INIT	-----------------------
	
	private init()
	{
		view = DATABASE.viewNamed("resource_collection_view")
		view.setMapBlock(createMapBlock
		{
			collection, emit in
			
			// Key = book id, language id, category (raw), name
			let key: [Any] = [collection.bookId, collection.languageId, collection.category.rawValue, collection.name]
			emit(key, nil)
			
		}, version: "1")
	}
	
	
	// OTHER METHODS	----------
	
	func collectionQuery(bookId: String, languageId: String? = nil, category: ResourceCategory? = nil, name: String? = nil) -> Query<ResourceCollectionView>
	{
		let keys = [
			ResourceCollectionView.KEY_BOOK: Key(bookId),
			ResourceCollectionView.KEY_LANGUAGE: Key(languageId),
			ResourceCollectionView.KEY_CATEGORY: Key(category?.rawValue),
			ResourceCollectionView.KEY_NAME: Key(name)
		]
		
		return createQuery(withKeys: keys)
	}
}
