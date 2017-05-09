//
//  BookProgressView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

fileprivate typealias ReduceResult = [String: (mostRecentCount: Int, historyCount: Int)]

fileprivate func increment(result: inout ReduceResult, pathId: String, mostRecentCountIncrease: Int = 0, historyCountIncrease: Int = 0)
{
	if let (previousMostRecentCount, previousHistoryCount) = result[pathId]
	{
		result[pathId] = (previousMostRecentCount + mostRecentCountIncrease, previousHistoryCount + historyCountIncrease)
	}
	else
	{
		result[pathId] = (mostRecentCountIncrease, historyCountIncrease)
	}
}

// This view is used for checking the progress of each book
final class BookProgressView: View
{
	// TYPES	----------------
	
	typealias Queried = Paragraph
	typealias MyQuery = Query<BookProgressView>
	
	
	// ATTRIBUTES	------------
	
	static let KEY_PROJECT = "project"
	static let KEY_BOOK = "book"
	static let KEY_CHAPTER = "chapter"
	static let KEY_PATH = "path"
	static let KEY_MOST_RECENT = "most_recent"
	
	static let keyNames = [KEY_PROJECT, KEY_BOOK, KEY_CHAPTER, KEY_PATH, KEY_MOST_RECENT]
	
	static let instance = BookProgressView()
	
	let view = DATABASE.viewNamed("book_progress_view")
	
	
	// INIT	--------------------
	
	private init()
	{
		view.setMapBlock(createMapBlock
		{
			paragraph, emit in
			
			if !paragraph.isDeprecated
			{
				let key: [Any] = [paragraph.projectId, paragraph.bookId, paragraph.chapterIndex, paragraph.pathId]
				let value = paragraph.isMostRecent
				
				emit(key, value)
			}
			
		}, reduce:
		{
			keys, values, rereduce in
			
			if rereduce
			{
				guard let values = values as? [ReduceResult] else
				{
					print("ERROR: Invalid type in BookProgressView rereduce")
					return ReduceResult()
				}
				
				// Merges the results
				return values.reduce(ReduceResult())
				{
					left, right in
					
					var combo = left
					right.forEach { increment(result: &combo, pathId: $0.key, mostRecentCountIncrease: $0.value.mostRecentCount, historyCountIncrease: $0.value.historyCount) }
					
					return combo
				}
			}
			else
			{
				guard let keys = keys as? [[Any]] else
				{
					print("ERROR: Invalid key type in BookProgressView reduce block")
					return ReduceResult()
				}
				
				// Counts the number of most recent (and other) rows for each path id
				var result = ReduceResult()
				
				for i in 0 ..< keys.count
				{
					if let pathId = keys[i][3] as? String, let isMostRecent = values[i] as? Bool
					{
						if isMostRecent
						{
							increment(result: &result, pathId: pathId, mostRecentCountIncrease: 1)
						}
						else
						{
							increment(result: &result, pathId: pathId, historyCountIncrease: 1)
						}
					}
					else
					{
						print("ERROR: Could not parse key '\(keys[i])' and / or value '\(values[i])' at BookProgressView reduce block")
					}
				}
				
				return result
			}
			
		}, version: "1")
	}
	
	
	// OTHER METHODS	----------------
	
	// Retrieves progress status for a single book
	func progressForBook(withId bookId: String) throws -> BookProgressStatus
	{
		if let result = try createProgressQuery(bookId: bookId).firstResultRow()?.rawValue as? ReduceResult
		{
			return statusForResult(result)
		}
		else
		{
			print("ERROR: No reduce result in BookProgressView query")
			return BookProgressStatus(paragraphAmount: 0, emptyParagraphAmount: 0, totalCommits: 0)
		}
	}
	
	// Retrieves progress status for each of the books in a project
	// Resulting dictionary keys are bookIds
	func progressForProjectBooks(projectId: String) throws -> [String: BookProgressStatus]
	{
		return try collectProgressResults(query: createProgressQuery(projectId: projectId), groupByKey: BookProgressView.KEY_BOOK, valueToKey: { $0.string() })
	}
	
	// Retrieves progress status for each chapter in a book
	// The dictionary keys are the chapter indices
	func chapterProgressForBook(withId bookId: String) throws -> [Int: BookProgressStatus]
	{
		return try collectProgressResults(query: createProgressQuery(bookId: bookId), groupByKey: BookProgressView.KEY_CHAPTER, valueToKey: { $0.int() })
	}
	
	private func collectProgressResults<T: Hashable>(query: MyQuery, groupByKey: String, valueToKey: (PropertyValue) -> T) throws -> [T: BookProgressStatus]
	{
		var groupedQuery = query
		groupedQuery.groupByKey = groupByKey
		
		var progress = [T: BookProgressStatus]()
		try groupedQuery.enumerateResult
		{
			row in
			
			guard let result = row.rawValue as? ReduceResult else
			{
				print("ERROR: Couldn't parse reduce result out of \(String(describing: row.rawValue))")
				return false
			}
			
			progress[valueToKey(row[groupByKey])] = statusForResult(result)
			return true
		}
		
		return progress
	}
	
	private func createProgressQuery(projectId: String, bookId: String? = nil, chapterIndex: Int? = nil) -> MyQuery
	{
		return createQuery(ofType: .reduce, withKeys: BookProgressView.makeKeys(from: [projectId, bookId, chapterIndex]))
	}
	
	private func createProgressQuery(bookId: String, chapterIndex: Int? = nil) -> MyQuery
	{
		return createProgressQuery(projectId: Book.projectId(fromId: bookId), bookId: bookId, chapterIndex: chapterIndex)
	}
	
	private func statusForResult(_ result: ReduceResult) -> BookProgressStatus
	{
		let paragraphAmount = result.values.count(where: { $0.mostRecentCount > 0 })
		let emptyParagraphAmount = result.values.count(where: { $0.historyCount == 0 })
		let totalCommits = result.values.reduce(0, { $0 + $1.historyCount })
		
		return BookProgressStatus(paragraphAmount: paragraphAmount, emptyParagraphAmount: emptyParagraphAmount, totalCommits: totalCommits)
	}
}
