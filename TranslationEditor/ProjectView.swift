//
//  ProjectView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 1.2.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

final class ProjectView: View
{
	// TYPES	---------------
	
	typealias Queried = Project
	typealias MyQuery = Query<ProjectView>
	
	
	// ATTRIBUTES	-----------
	
	static let KEY_CONTRIBUTOR = "contributor"
	static let KEY_CREATED = "created"
	
	static let instance = ProjectView()
	static let keyNames = [KEY_CONTRIBUTOR, KEY_CREATED]
	
	let view: CBLView
	
	
	// INIT	-------------------
	
	private init()
	{
		view = DATABASE.viewNamed("project_view")
		view.setMapBlock(createMapBlock
		{
			project, emit in
			
			for contributorId in project.contributorIds
			{
				// Key = contributor id + created
				let key: [Any] = [contributorId, project.created]
				emit(key, nil)
			}
		
		}, version: "1")
	}
	
	
	// OTHER METHODS	-------
	
	// Query for all projects the account contributes to
	func projectQuery(forContributorId accountId: String) -> MyQuery
	{
		return MyQuery(range: [ProjectView.KEY_CONTRIBUTOR: Key(accountId)], descending: true)
	}
	
	// Finds all projects the provided account has access to
	func projectsForContributor(withId accountId: String) throws -> [Project]
	{
		return try projectQuery(forContributorId: accountId).resultObjects()
	}
	
	
	/*
	// TYPES	---------------
	
	typealias Queried = Project
	typealias MyQuery = Query<ProjectView>
	
	
	// ATTRIBUTES	-----------
	
	static let KEY_LANGUAGE = "language"
	static let KEY_CREATED = "created"
	
	static let instance = ProjectView()
	static let keyNames = [KEY_LANGUAGE, KEY_CREATED]
	
	let view: CBLView
	
	
	// INIT	-------------------
	
	private init()
	{
		view = DATABASE.viewNamed("project_view")
		view.setMapBlock(createMapBlock
		{
			project, emit in
			
			// Key = Language + created
			let key: [Any] = [project.languageId, project.created]
			// Value = Number of contributors
			let value = project.contributorIds.count
			
			emit(key, value)
			
		}, reduce:
		{
			keys, values, rereduce in
			
			// Counts the number of contributors (stored in value) in total
			return (values as! [Int]).reduce(0, { $0 + $1 })
		
		}, version: "1")
	}
	
	
	// OTHER METHODS	-----
	
	func projectsQuery(forLanguageId languageId: String) -> MyQuery
	{
		return createQuery(withKeys: makeKeys(languageId: languageId))
	}
	
	// The total amount of contributors for a certain language projects
	func contributorsForLanguage(withId languageId: String) throws -> Int
	{
		let query = createQuery(ofType: .reduce, withKeys: makeKeys(languageId: languageId))
		return (try query.firstResultRow()?.value.int).or(0)
	}
	
	// The amount of contributors for each language id
	func languageContributors() throws -> [String: Int]
	{
		let query = MyQuery.reduceQuery(groupBy: ProjectView.KEY_LANGUAGE)
		return try query.resultRows().toDictionary { ($0[ProjectView.KEY_LANGUAGE].string(), $0.value.int()) }
	}
	
	// Total number of contributors between all projects
	func totalContributors() throws -> Int
	{
		return (try createQuery(ofType: .reduce).firstResultRow()?.value.int).or(0)
	}
	
	private func makeKeys(languageId: String) -> [String: Key]
	{
		return [ProjectView.KEY_LANGUAGE: Key(languageId), ProjectView.KEY_CREATED: Key.undefined]
	}
*/
}
