//
//  USXBookProcessor.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.10.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Some utility functions

// Saves paragraph information by overwriting an old version
fileprivate func handleSingleMatch(existing: Paragraph, newVersion: Paragraph) throws
{
	// Creates a new commit over the existing paragraph version
	_ = try existing.commit(userId: newVersion.creatorId, sectionIndex: newVersion.sectionIndex, paragraphIndex: newVersion.index, content: newVersion.content)
}

// Saves a bunch of single paragraph matches to the database
fileprivate func handleSingleMatches(_ matches: [(Paragraph, Paragraph)]) throws
{
	try matches.forEach{ existing, newVersion in try handleSingleMatch(existing: existing, newVersion: newVersion) }
}

// This USX processor is able to parse contents of a single book based on USX data
class USXBookProcessor: USXContentProcessor
{
	typealias Generated = Book
	typealias Processed = Chapter
	
	
	// ATTRIBUTES	-------
	
	private let userId: String
	private let code: String
	private let languageId: String
	
	// Language + code + identifier -> Book to overwrite
	private let findReplacedBook: FindBook
	private let matchParagraphs: MatchParagraphs
	
	private var introductionParas = [Para]()
	private var identifier: String?
	private var _book: Book?
	
	
	// INIT	---------------
	
	init(userId: String, languageId: String, code: String, findReplacedBook: @escaping FindBook, matchParagraphs: @escaping MatchParagraphs)
	{
		self.userId = userId
		self.languageId = languageId
		self.code = code
		self.findReplacedBook = findReplacedBook
		self.matchParagraphs = matchParagraphs
	}
	
	// Creates a new USX parser for book data
	// The parser should be set to start after a book element start
	// The parser will stop at the next book element start or at the end of usx
	static func createBookParser(caller: XMLParserDelegate, userId: String, languageId: String, bookCode: String, findReplacedBook: @escaping FindBook, matchParagraphs: @escaping MatchParagraphs, targetPointer: UnsafeMutablePointer<[Book]>, using errorHandler: @escaping ErrorHandler) -> USXContentParser<Book, Chapter>
	{
		let parser = USXContentParser<Book, Chapter>(caller: caller, containingElement: .usx, lowestBreakMarker: .book, targetPointer: targetPointer, using: errorHandler)
		parser.processor = AnyUSXContentProcessor(USXBookProcessor(userId: userId, languageId: languageId, code: bookCode, findReplacedBook: findReplacedBook, matchParagraphs: matchParagraphs))
		
		return parser
	}
	
	
	// USX PARSING	-------
	
	func getParser(_ caller: USXContentParser<Book, Chapter>, forElement elementName: String, attributes: [String : String], into targetPointer: UnsafeMutablePointer<[Chapter]>, using errorHandler: @escaping ErrorHandler) -> (XMLParserDelegate, Bool)?
	{
		// On chapter elements, parses using a chapter parser
		if elementName == USXMarkerElement.chapter.rawValue
		{
			// Parses the chapter index from an attribute
			if let numberAttribute = attributes["number"], let index = Int(numberAttribute)
			{
				do
				{
					let book = try getBook()
					return (USXChapterProcessor.createChapterParser(caller: caller, userId: userId, bookId: book.idString, index: index, targetPointer: targetPointer, using: errorHandler), false)
				}
				catch
				{
					errorHandler(error)
					return nil
				}
			}
			else
			{
				errorHandler(USXParseError.chapterIndexNotFound)
				return nil
			}
		}
		// The introduction is parsed using a para parser
		else if elementName == USXContainerElement.para.rawValue
		{
			// TODO: WET WET
			var style = ParaStyle.normal
			if let styleAttribute = attributes["style"]
			{
				style = ParaStyle.value(of: styleAttribute)
			}
			
			return (USXParaProcessor.createParaParser(caller: caller, style: style, targetPointer: &introductionParas, using: errorHandler), true)
		}
		else
		{
			return nil
		}
	}
	
	func getCharacterParser(_ caller: USXContentParser<Book, Chapter>, forCharacters string: String, into targetPointer: UnsafeMutablePointer<[Chapter]>, using errorHandler: @escaping ErrorHandler) -> XMLParserDelegate?
	{
		// Only character data found by this parser is the book name inside the book element
		// this information is parsed here and not delegated
		identifier = string
		return nil
	}
	
	func generate(from content: [Chapter], using errorHandler: @escaping ErrorHandler) -> Book?
	{
		// Creates the introduction paragraphs (TODO: Removed in the current version)
		//let introduction = ParagraphPrev(content: introductionParas)
		
		do
		{
			// Creates the book
			let book = try getBook()
			
			// And stores it to the database
			try book.push()
			
			// Also stores / updates all the collected documents
			var paragraphInsertFailed = false
			var chapterIndex = 0
			for chapter in content
			{
				chapterIndex += 1
				
				// Collects the new paragraphs into a single array
				let chapterParagraphs = chapter.flatMap {(section) in section.flatMap { $0 } }
				
				// Finds all paragraphs already existing in this chapter
				let existingParagraphs = try Paragraph.arrayFromQuery(ParagraphView.instance.latestParagraphQuery(bookId: book.idString, chapterIndex: chapterIndex))
				// TODO: Should fail if there are conflicts in the target group
				
				// If there are no existing paragraphs, simply pushes the new ones to the database
				if existingParagraphs.isEmpty
				{
					try chapterParagraphs.forEach { try $0.push() }
				}
				// Matches existing paragraphs to new paragraphs and operates on those
				else
				{
					var singleMatches = [(Paragraph, Paragraph)]()
					var unmatchedExisting = [Paragraph]()
					var unmatchedNew = [Paragraph]()
					
					// If there are equal number of chapters to match, simply matches them in order
					if chapterParagraphs.count == existingParagraphs.count
					{
						for i in 0 ..< chapterParagraphs.count
						{
							singleMatches.append((existingParagraphs[i], chapterParagraphs[i]))
						}
					}
					// Otherwise tries to map paragraphs with equal content
					else
					{
						var lastStoredNewIndex = -1
						for i in 0 ..< existingParagraphs.count
						{
							let existing = existingParagraphs[i]
							
							var matchingNewIndex: Int?
							for newIndex in lastStoredNewIndex + 1 ..< chapterParagraphs.count
							{
								let newParagraph = chapterParagraphs[newIndex]
								
								if existing.text == newParagraph.text
								{
									matchingNewIndex = newIndex
									singleMatches.append((existing, newParagraph))
								}
							}
							
							// If a match was found but some new paragraphs were left unmatched in between, registers those
							if let matchingNewIndex = matchingNewIndex
							{
								for unmatchedIndex in lastStoredNewIndex + 1 ..< matchingNewIndex
								{
									unmatchedNew.append(chapterParagraphs[unmatchedIndex])
								}
								lastStoredNewIndex = matchingNewIndex
							}
							// If no match was found for an existing paragraph, marks that
							else
							{
								unmatchedExisting.append(existing)
							}
						}
						
						// Finalises the array(s)
						for i in lastStoredNewIndex + 1 ..< chapterParagraphs.count
						{
							unmatchedExisting.append(chapterParagraphs[i])
						}
					}
					
					// A separate algorithm is used if there are still unmatched elements that can be matched with each other
					if !unmatchedExisting.isEmpty && !unmatchedNew.isEmpty
					{
						// Matches the unmatched paragraphs using a special algorithm
						if let matchResults = matchParagraphs(unmatchedExisting, unmatchedNew)
						{
							// Handles the single matches first
							try handleSingleMatches(singleMatches)
							
							var matchedExisting = [Paragraph]()
							
							// Goes through all new paragraphs
							for newParagraph in unmatchedNew
							{
								// Finds out how many connections were made to that paragraph
								let matchingExisting = matchResults.filter { (_, new) in return new === newParagraph }.map { (existing, _) in return existing }
								
								// If there are 0 or if all of the existing paragraphs were already matched, saves as a new paragraph
								if matchedExisting.containsReferences(to: matchingExisting)
								{
									try newParagraph.push()
								}
								// Otherwise, if there is only a single match, overwrites that version
								else if matchingExisting.count == 1
								{
									let existing = matchingExisting.first!
									try handleSingleMatch(existing: existing, newVersion: newParagraph)
									matchedExisting.append(existing)
								}
								// If there are multiple matches, inserts the paragraph as new and removes the old versions
								else
								{
									try newParagraph.push()
									// TODO: Delete whole commit path (or mark as deprecated)
									for existing in matchingExisting
									{
										try existing.delete()
										matchedExisting.append(existing)
									}
								}
							}
							
							// Finally, goes through all of the existing paragraphs and deletes those that weren't matched
							for leftWithoutMatch in unmatchedExisting.filter({ !matchedExisting.containsReference(to: $0) })
							{
								// TODO: Again, delete whole path
								try leftWithoutMatch.delete()
							}
						}
						// Which may fail
						else
						{
							paragraphInsertFailed = true
						}
					}
					else
					{
						try handleSingleMatches(singleMatches)
						
						// TODO: Delete whole path here
						// In case some existing paragraphs were left unmatched, removes them
						try unmatchedExisting.forEach { try $0.delete() }
						// And if some paragraphs were introduced, inserts them
						try unmatchedNew.forEach { try $0.push() }
					}
				}
			}
			
			// Clears status for reuse
			introductionParas = []
			identifier = nil
			_book = nil
			
			if paragraphInsertFailed
			{
				return nil
			}
			else
			{
				return book
			}
		}
		catch
		{
			errorHandler(error)
			return nil
		}
	}
	
	
	// OTHER METHODS	---------
	
	// Function used because computed properties can't throw at this time
	private func getBook() throws -> Book
	{
		if _book == nil
		{
			if let identifier = identifier
			{
				if let existingBook = findReplacedBook(languageId, code, identifier)
				{
					existingBook.identifier = identifier
					existingBook.languageId = languageId
					_book = existingBook
				}
				else
				{
					_book = Book(code: code, identifier: identifier, languageId: languageId)
				}
			}
			else
			{
				throw USXParseError.bookNameNotSpecified
			}
		}
		
		return _book!
	}
}
