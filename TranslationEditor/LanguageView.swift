//
//  LanguageView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.11.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This view is used for querying language data
final class LanguageView: View
{
	// TYPES	------------
	
	typealias Queried = Language
	
	
	// ATTRIBUTES	---------
	
	static let instance = LanguageView()
	
	let view: CBLView
	
	
	// INIT	----------------
	
	private init()
	{
		view = DATABASE.viewNamed("languages")
		view.setMapBlock(createMapBlock
		{
			(language, emit) in
			
			// Key = language name (lowercase)
			emit(language.name, nil)
			
		}, version: "1")
	}
	
	
	// OTHER METHODS	----
	
	func language(withName name: String) throws -> Language?
	{
		let query = createQuery(forKeys: [name.lowercased()])
		query.limit = 1
		
		let result = try query.run()
		if let rawRow = result.nextRow()
		{
			let row = try Row<Language>(rawRow)
			return row.object
		}
		else
		{
			return nil
		}
	}
}
