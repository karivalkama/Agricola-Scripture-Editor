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
	
	static let KEY_LANGUAGE_NAME = "language_name"
	static let keyNames = [KEY_LANGUAGE_NAME]
	
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
			emit(language.name.lowercased(), nil)
			
		}, version: "2")
	}
	
	
	// OTHER METHODS	----
	
	// Finds or creates a language with the specified name
	func language(withName name: String) throws -> Language
	{
		let query = Query<LanguageView>(range: [LanguageView.KEY_LANGUAGE_NAME : Key(name.lowercased())])
		
		if let language = try query.firstResultObject()
		{
			return language
		}
		else
		{
			let newLanguage = Language(name: name)
			try newLanguage.push()
			return newLanguage
		}
	}
}
