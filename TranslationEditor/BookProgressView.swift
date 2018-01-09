//
//  BookProgressView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.5.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

fileprivate typealias ReduceResult = (mostRecentFilled: Int, mostRecentTotal: Int, historyFilled: Int)

fileprivate func increment(result: inout ReduceResult, filledCountIncrease: Int = 0, totalCountIncrease: Int = 0, isMostRecent: Bool)
{
	if isMostRecent
	{
		result.mostRecentFilled += filledCountIncrease
		result.mostRecentTotal += totalCountIncrease
	}
	else
	{
		result.historyFilled += filledCountIncrease
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
				let key: [Any] = [paragraph.projectId, paragraph.bookId, paragraph.chapterIndex, paragraph.pathId, paragraph.isMostRecent]
				// Value is the amount of filled verses + total number of verses
				let completion = paragraph.completion
				let value = [completion.filledVerses, completion.total]
				
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
					return ReduceResult(0, 0, 0)
				}
				
				// Merges the results
				return values.reduce(ReduceResult(0, 0, 0)) { ReduceResult(mostRecentFilled: $0.mostRecentFilled + $1.mostRecentFilled, mostRecentTotal: $0.mostRecentTotal + $1.mostRecentTotal, historyFilled: $0.historyFilled + $1.historyFilled) }
			}
			else
			{
				guard let keys = keys as? [[Any]] else
				{
					print("ERROR: Invalid key type in BookProgressView reduce block")
					return ReduceResult(0, 0, 0)
				}
				
				// Counts together the number of filled and empty verses. A separate count is used for history paragraphs
				var result = ReduceResult(0, 0, 0)
				
				for i in 0 ..< keys.count
				{
					if let isMostRecent = keys[i][4] as? Bool, let counts = values[i] as? [Int], counts.count >= 2
					{
						increment(result: &result, filledCountIncrease: counts[0], totalCountIncrease: counts[1], isMostRecent: isMostRecent)
					}
					else
					{
						print("ERROR: Could not parse key '\(keys[i])' and / or value '\(values[i])' at BookProgressView reduce block")
					}
				}
				
				return result
			}
			
		}, version: "2")
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
			return BookProgressStatus(totalElementAmount: 0, filledElementAmount: 0, filledHistoryElementAmount: 0)
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
	
	// Retrieves progress status for all books
	func progressForAllBooks() throws -> [String: BookProgressStatus]
	{
		return try collectProgressResults(query: createQuery(ofType: .reduce), groupByKey: BookProgressView.KEY_BOOK, valueToKey: { $0.string() })
	}
	
	private func collectProgressResults<T>(query: MyQuery, groupByKey: String, valueToKey: (PropertyValue) -> T) throws -> [T: BookProgressStatus]
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
		return BookProgressStatus(totalElementAmount: result.mostRecentTotal, filledElementAmount: result.mostRecentFilled, filledHistoryElementAmount: result.historyFilled)
	}
}
