//
//  LanguageSelectionHandler.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 22.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

protocol LanguageSelectionHandlerDelegate: class
{
	// This method is called whenever language editing ends with a non-recognised language value
	// This may not be the final value since the user may always edit the field
	func languageSelectionHandler(_ selectionHandler: LanguageSelectionHandler, newLanguageNameInserted languageName: String)
	
	// This method is called when the user selects / inserts value that matches an existing language
	func languageSelectionHandler(_ selectionHandler: LanguageSelectionHandler, languageSelected: Language)
}

class LanguageSelectionHandler: FilteredSelectionDataSource, SimpleSingleSelectionViewDelegate
{
	// ATTRIBUTES	-----------------
	
	weak var delegate: LanguageSelectionHandlerDelegate?
	
	private var languages = [Language]()
	private(set) var selectedLanguage: Language? = nil
	private(set) var languageName = ""
	
	
	// COMPUTED PROPERTIES	---------
	
	var numberOfOptions: Int { return languages.count }
	
	var existingLanguageSelected: Bool { return selectedLanguage != nil }
	
	var isEmpty: Bool { return languageName.isEmpty }
	
	
	// IMPLEMENTED METHODS	---------
	
	func labelForOption(atIndex index: Int) -> String
	{
		return languages[index].name
	}
	
	func onValueChanged(_ newValue: String, selectedAt index: Int?)
	{
		print("STATUS: Language selection changed. New value: \(newValue), selected at index: \(index ?? -1)")
		
		if let index = index
		{
			selectedLanguage = languages[index]
			languageName = selectedLanguage!.name
		}
			/*
		else if newValue.isEmpty
		{
			selectedLanguage = nil
			languageName = newValue
			}
		else if let matchingLanguage = languages.first(where: { $0.name.lowercased().contains(newValue.lowercased()) })
		{
			selectedLanguage = matchingLanguage
			languageName = matchingLanguage.name
		}*/
		else
		{
			selectedLanguage = nil
			languageName = newValue
		}
		
		// Informs the delegate too
		if let selectedLanguage = selectedLanguage
		{
			delegate?.languageSelectionHandler(self, languageSelected: selectedLanguage)
		}
		else
		{
			delegate?.languageSelectionHandler(self, newLanguageNameInserted: languageName)
		}
	}
	
	
	// OTHER METHODS	-------------
	
	// Updates available language data. Remember to also reload the selection view
	func updateLanguageOptions() throws
	{
		languages = try LanguageView.instance.createQuery().resultObjects()
	}
	
	// Returns the selected language or inserts a new language to the database. Will return a language instance as long as the field is not empty
	func getOrInsertLanguage() throws -> Language?
	{
		if let selectedLanguage = selectedLanguage
		{
			return selectedLanguage
		}
		else if isEmpty
		{
			return nil
		}
		else
		{
			let newLanguage = try LanguageView.instance.language(withName: languageName.capitalized)
			languages.add(newLanguage)
			
			return newLanguage
		}
	}
}
