//
//  FileImportStack.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 19.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This stack holds references to files that still need to be operated
class USXImportStack
{
	// ATTRIBUTES	------------
	
	static let instance = USXImportStack()
	
	private var urls = [URL]()
	
	
	// COMPUTED PROPERTIES	----
	
	var isEmpty: Bool { return urls.isEmpty }
	
	var top: URL? { return urls.last }
	
	
	// INIT	--------------------
	
	// Initializer is hidden
	private init() { }
	
	
	// OTHER METHODS	--------
	
	func pop() -> URL?
	{
		return urls.popLast()
	}
	
	func push(_ url: URL)
	{
		urls.add(url)
	}
}
