//
//  ProjectBooksView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 29.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class ProjectBooksView: View
{
	// TYPES	------------
	
	typealias Queried = Book
	typealias MyQuery = Query<ProjectBooksView>
	
	
	// ATTRIBUTES	--------
	
	static let instance = ProjectBooksView()
	
	static let KEY_LANGUAGE = "language"
	static let KEY_PROJECT = "project"
	static let KEY_CODE = "code"
	static let KEY_IDENTIFIER = "identifier"
	
	static let keyNames = [KEY_PROJECT, KEY_LANGUAGE, KEY_CODE, KEY_IDENTIFIER]
	
	let view = DATABASE.viewNamed("project_books")
	
	
	// INIT	-----------------
	
	private init()
	{
		view.setMapBlock(createMapBlock
		{
			book, emit in
			
			let key: [Any] = [book.projectId, book.languageId, book.code.code, book.identifier]
			emit(key, nil)
		},
		version: "3")
	}
	
	
	// OTHER METHODS	----
	
	// This query can be used for retrieving books associated with a specific project
	func booksQuery(projectId: String? = nil, languageId: String? = nil, code: BookCode? = nil, identifier: String? = nil) -> MyQuery
	{
		return createQuery(withKeys: ProjectBooksView.makeKeys(from: [projectId, languageId, code?.code, identifier]))
	}
}
