//
//  TranslationEditorTests.swift
//  TranslationEditorTests
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//
import XCTest
@testable import TranslationEditor


class TranslationEditorTests: XCTestCase
{
    override func setUp()
	{
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
		useDatabase(named: "agricola")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testString()
	{
		let numberRegex = try! NSRegularExpression(pattern: "[0-9\\-]", options: [])
		let str1 = "M01kk4 -001k222"
		
		let stripped = str1.limited(toExpression: numberRegex)
		
		print("\(str1) -> \(stripped)")
		assert(stripped == "014-001222")
	}
	
	func testPropertyRetrieval()
	{
		let rawProperties = ["a": 1.value, "B": 2.value, "c": 3.value, "C": 3.value]
		let props = PropertySet(rawProperties)
		
		print(props)
		
		assert(props["a"].int == 1)
		assert(props["A"].int == 1)
		assert(props["b"].int == 2)
		assert(props["B"].int == 2)
		assert(props["c"].int == props["C"].int)
	}
	
	func testVerseRanges()
	{
		let range1 = VerseRange(1, 2)
		let range2 = VerseRange(VerseIndex(2), VerseIndex(4))
		
		print("Range 1: \(range1.description) AKA \(range1.simpleName): \(range1.verses)")
		print("Range 2: \(range2.description) AKA \(range2.simpleName): \(range2.verses)")
		
		assert(range1.verses.count == 1)
		assert(range2.verses.count == 2)
		
		let range3 = VerseRange(VerseIndex(4), VerseIndex(5, midVerse: true))
		let range4 = VerseRange(VerseIndex(5, midVerse: true), VerseIndex(8))
		
		print("Range 3: \(range3.description) AKA \(range3.simpleName): \(range3.verses)")
		print("Range 4: \(range4.description) AKA \(range4.simpleName): \(range4.verses)")
		
		assert(range3.verses.count == 2)
		assert(range4.verses.count == 3)
		
		let range5 = VerseRange(VerseIndex(8), VerseIndex(8, midVerse: true))
		let range6 = VerseRange(VerseIndex(8, midVerse: true), VerseIndex(9))
		
		print("Range 5: \(range5.description) AKA \(range5.simpleName): \(range5.verses)")
		print("Range 6: \(range6.description) AKA \(range6.simpleName): \(range6.verses)")
		
		assert(range5.verses.count == 1)
		assert(range6.verses.count == 1)
	}
	
	func testVerseRangeJSONParsing()
	{
		let ranges = [VerseRange(1, 2), VerseRange(2, 4), VerseRange(VerseIndex(4), VerseIndex(5, midVerse: true)), VerseRange(VerseIndex(5, midVerse: true), VerseIndex(8)), VerseRange(VerseIndex(8), VerseIndex(8, midVerse: true)), VerseRange(VerseIndex(8, midVerse: true), VerseIndex(9))]
		
		for range in ranges
		{
			let parsed = try! VerseRange.parse(from: range.toPropertySet)
			assert(parsed == range, "Failed to parse: \(range) -> \(range.toPropertySet) -> \(parsed)")
		}
	}
	
	func testParaParsing()
	{
		let chData1 = CharData(text: "Chardata 1")
		assert(CharData.parse(from: chData1.toPropertySet).text == chData1.text)
		let chData2 = CharData(text: "Chardata 2", style: CharStyle.quotation)
		assert(CharData.parse(from: chData2.toPropertySet).style == CharStyle.quotation)
		
		let verse = Verse(range: VerseRange(1, 2), content: [chData1, chData2])
		assert(try! Verse.parse(from: verse.toPropertySet).range == verse.range)
		
		let para1 = Para(content: [verse], style: .normal)
		let para2 = Para(content: [chData1, chData2], style: .sectionHeading(1))
		
		assert(try! Para.parse(from: para1.toPropertySet).range == para1.range)
		assert(try! Para.parse(from: para2.toPropertySet).style == para2.style)
		
		print(para1.toPropertySet.description)
		print(para2.toPropertySet.description)
	}
	
	func testParagraphAttStrConsistency()
	{
		let verse1 = Verse(range: VerseRange(1, 2), content: "Testing testing")
		let verse23 = Verse(range: VerseRange(2, 4), content: "Testing moar and moar testing")
		let verse4 = Verse(range: VerseRange(VerseIndex(4), VerseIndex(4, midVerse: true)), content: "Testing testing")
		
		var paras = [Para]()
		paras.append(Para(content: [CharData(text: "Ambiguous poetic line")], style: .poeticLine(1)))
		paras.append(Para(content: [verse1, verse23, verse4], style: .normal))
		
		let paragraphOriginal = Paragraph(bookId: "no_book", chapterIndex: 1, sectionIndex: 1, index: 1, content: paras, creatorId: "test")
		var converted = paragraphOriginal.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false])
		
		for i in 0 ..< 10
		{
			let convertedBack = Paragraph(bookId: "no_book", chapterIndex: 1, sectionIndex: 1, index: 1, content: [], creatorId: "test")
			convertedBack.replaceContents(with: converted)
			
			print("TEST: Iteration \(i)")
			assert(convertedBack.paraContentsEqual(with: paragraphOriginal))
			
			converted = convertedBack.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false])
		}
		
		print("TEST: DONE")
	}
	
	func testParagraphProperties()
	{
		let language = Language(name: "English")
		let book = Book(projectId: "test-project", code: "gal", identifier: "English: This and This Translation", languageId: language.idString)
		
		let paragraph = Paragraph(bookId: book.idString, chapterIndex: 1, sectionIndex: 1, index: 1, content: [], creatorId: "testuserid")
		
		assert(paragraph.bookCode == "gal")
		
		let copyParagraph = try! Paragraph.create(from: paragraph.toPropertySet, withId: paragraph.id)
		
		assert(copyParagraph.bookId == paragraph.bookId)
		assert(copyParagraph.chapterIndex == paragraph.chapterIndex)
		assert(copyParagraph.sectionIndex == paragraph.sectionIndex)
		assert(copyParagraph.index == paragraph.index)
	}
	
	func testPropertyValues()
	{
		var set = PropertySet()
		set["first"] = PropertyValue(1)
		set["second"] = PropertyValue("2.0")
		
		var child = PropertySet()
		child["name"] = PropertyValue("Jussi")
		
		set["child"] = PropertyValue(child)
		
		assert(set["second"].string == "2.0")
		assert(set["child"]["name"].string == "Jussi")
		assert(set["second"].double == 2.0)
		
		print(set.toDict)
		print(PropertySet(set.toDict).toDict)
	}
	
	func testParaStyleParsing()
	{
		let paraStyles: [ParaStyle] = [.normal, .other("ip"), .poeticLine(1), .poeticLine(2), .sectionHeading(1), .sectionHeading(2)]
		
		for style in paraStyles
		{
			let code = style.code
			let parsed = ParaStyle.value(of: code)
			
			print("\(style) -> \(code) -> \(parsed)")
			
			assert(style.isHeaderStyle() == parsed.isHeaderStyle())
			assert(style.isParagraphStyle() == parsed.isParagraphStyle())
			assert(style.isSectionHeadingStyle() == parsed.isSectionHeadingStyle())
			
			if style.isHeaderStyle()
			{
				print("\t- Heading")
			}
			if style.isSectionHeadingStyle()
			{
				print("\t- Section heading")
			}
			if style.isParagraphStyle()
			{
				print("\t- Paragraph")
			}
		}
	}
	
	func testRemoveNonTypeData()
	{
		let query = DATABASE.createAllDocumentsQuery()
		let results = try! query.run()
		
		while let row = results.nextRow(), let document = row.document
		{
			if document[PROPERTY_TYPE] == nil
			{
				print("REMOVING TYPELESS INSTANCE \(document.documentID)")
				try! document.delete()
			}
		}
	}
	
	func testClearDatabase()
	{
		try! DATABASE.delete()
	}
	
	func testRemoveDataOfType()
	{
		let types = [NotesThread.type, NotesPost.type]
		
		print("STATUS: Database used: \(DATABASE.name)")
		
		let query = DATABASE.createAllDocumentsQuery()
		let results = try! query.run()
		
		while let row = results.nextRow(), let document = row.document
		{
			//print("STATUS: Row \(row.key)")
			
			if let type = document[PROPERTY_TYPE] as? String
			{
				if types.contains(type)
				{
					print("STATUS: deleting document of type \(type)")
					try! document.delete()
				}
			}
			else
			{
				print("STATUS: Typeless document found!")
			}
		}
		
		print("STATUS: done!")
	}
	
	func testReadDataOfType()
	{
		let type = AgricolaAccount.type
		
		let query = DATABASE.createAllDocumentsQuery()
		let results = try! query.run()
		
		print("TEST: Reading database data")
		
		while let row = results.nextRow(), let properties = row.document?.properties
		{
			if properties[PROPERTY_TYPE] as? String == type
			{
				print("TEST: Row \(row.documentID!): \(properties)")
			}
		}
		
		print("TEST: DONE")
	}
	
	func testQuery()
	{
		print("TEST: Starting")
		let query = AccountView.instance.accountQuery(nameKey: "test")
		
		try! query.resultRows().forEach { print("\($0.keys)") }
		print("TEST: Done")
	}

	func testRemoveEdits()
	{
		let editRows = try! ParagraphEditView.instance.createQuery().resultRows()
		
		print("There are \(editRows.count) edits in total. Deleting.")
		
		editRows.forEach { try! ParagraphEdit.delete($0.id!) }
		
		print("Done")
	}
	
	func testFindEnglish()
	{
		let query = LanguageView.instance.languageQuery(name: "english")
		
		let languages = try! query.resultObjects()
		print("Found \(languages.count) languages named 'english'")
		languages.forEach { print("- \($0.name): \($0.idString)") }
	}
	
	func testReadDatabaseData()
	{
		// Finds all languages first
		let languages = try! LanguageView.instance.createQuery().resultObjects()
		
		print("Languages in database: ")
		for language in languages
		{
			print("- \(language.name) (\(language.idString))")
		}
		
		// Next finds all books
		let books = try! BookView.instance.createQuery().resultObjects()
		
		for book in books
		{
			let paragraphs = try! ParagraphView.instance.latestParagraphQuery(bookId: book.idString).resultObjects()
			
			print("- \(book.code) - \(book.identifier) (\(paragraphs.count) paragraphs)")
			//print("Id: \(book.idString)")
			//book.properties.forEach { print("\($0.key) = \($0.value.string())") }
			
			for paragraph in paragraphs
			{
				let text = paragraph.text
				let maxIndex = text.index(text.startIndex, offsetBy: min(text.characters.count, 32))
				print("\t- \(paragraph.chapterIndex).\(paragraph.sectionIndex).\(paragraph.index): \(paragraph.text.substring(to: maxIndex))")
			}
			
			let editAmount = try! ParagraphEditView.instance.editsForRangeQuery(bookId: book.idString).resultRows().count
			if editAmount != 0
			{
				print("There are also \(editAmount) edits")
			}
		}
	}
	
	func testVerseConsistency()
	{
		let books = try! BookView.instance.createQuery().resultObjects()
		
		for book in books
		{
			print("Testing book \(book.identifier)")
			
			let paragraphs = try! ParagraphView.instance.latestParagraphQuery(bookId: book.idString).resultObjects()
			
			for paragraph in paragraphs
			{
				if let range = paragraph.range
				{
					print("Paragraph: \(range)")
				}
				else
				{
					print("Paragraph: no range")
				}
				
				for para in paragraph.content
				{
					if let range = para.range
					{
						print("\tPara: \(range)")
					}
					else
					{
						print("\tPara: no range")
					}
					
					for verse in para.verses
					{
						print("\t\tVerse: \(verse.range)")
					}
				}
			}
		}
	}
	
	func testMakeFinnishCopy()
	{
		let code = "gal"
		let userId = "testuserid"
		let sourceLanguageName = "English"
		let targetLanguageName = "Finnish"
		
		// Finds / makes language data
		let sourceLanguage = try! LanguageView.instance.language(withName: sourceLanguageName)
		let targetLanguage = try! LanguageView.instance.language(withName: targetLanguageName)
		
		// Finds source book
		guard let sourceBook = try! BookView.instance.booksQuery(code: code, languageId: sourceLanguage.idString).firstResultObject() else
		{
			print("TEST: No source book material with code \(code) and language \(sourceLanguage.name)")
			return
		}
		
		// Makes an empty copy, if there isn't one already
		guard try! BookView.instance.booksQuery(code: sourceBook.code, languageId: targetLanguage.idString).firstResultRow() == nil else
		{
			print("TEST: There already exists a \(targetLanguageName) copy of book \(code)")
			return
		}
		
		print("Creating a \(targetLanguageName) copy of \(sourceLanguageName) book \(sourceBook.code): \(sourceBook.identifier)")
		_ = try! sourceBook.makeEmptyCopy(projectId: "test-project", identifier: "Test Version", languageId: targetLanguage.idString, userId: userId)
		
		print("Done")
	}
	
	func testMakeNotes()
	{
		let code = "gal"
		let languageName = "Finnish"
		let resourceName = "Notes"
		
		let language = try! LanguageView.instance.language(withName: languageName)
		guard let book = try! BookView.instance.booksQuery(code: code, languageId: language.idString).firstResultObject() else
		{
			print("TEST: No book \(code) for language \(languageName)")
			return
		}
		
		// Makes sure there doesn't exist a notes resource already
		guard try! ResourceCollectionView.instance.collectionQuery(bookId: book.idString, languageId: language.idString, category: .notes).firstResultRow() == nil else
		{
			print("TEST: Notes already exist for book \(book.identifier)")
			return
		}
		
		// Creates the resource
		let resource = ResourceCollection(languageId: language.idString, bookId: book.idString, category: .notes, name: resourceName)
		
		// Creates the notes
		let paragraphs = try! ParagraphView.instance.latestParagraphQuery(bookId: book.idString).resultObjects()
		let notes = paragraphs.map { ParagraphNotes(collectionId: resource.idString, chapterIndex: $0.chapterIndex, pathId: $0.pathId) }
		
		// Pushes the new data to the database
		try! DATABASE.tryTransaction
		{
			try resource.push()
			try notes.forEach { try $0.push() }
		}
		
		print("TEST: DONE (inserted \(notes.count) notes)")
	}
	
	func testMakeBind()
	{
		let bookCode = "gal"
		let sourceLanguageName = "English"
		let targetLanguageName = "Finnish"
		let userId = "testuserid"
		
		// Reads language data
		let sourceLanguage = try! LanguageView.instance.language(withName: sourceLanguageName)
		let targetLanguage = try! LanguageView.instance.language(withName: targetLanguageName)
		
		// Finds book data
		guard let sourceBookId = try! BookView.instance.booksQuery(code: bookCode, languageId: sourceLanguage.idString).firstResultRow()?.id else
		{
			assertionFailure("TEST: No book \(bookCode) for language \(sourceLanguageName)")
			return
		}
		
		guard let targetBookId = try! BookView.instance.booksQuery(code: bookCode, languageId: targetLanguage.idString).firstResultRow()?.id else
		{
			assertionFailure("TEST: No book \(bookCode) for language \(targetLanguageName)")
			return
		}
		
		// Checks if there already exists a non-deprecated binding
		guard try! ParagraphBindingView.instance.latestBinding(from: sourceBookId, to: targetBookId) == nil else
		{
			assertionFailure("TEST: Binding already exists")
			return
		}
		
		/*
		// Finds the paragraphs
		let sourceParagraphs = try! ParagraphView.instance.latestParagraphQuery(bookId: sourceBookId).resultObjects()
		let targetParagraphs = try! ParagraphView.instance.latestParagraphQuery(bookId: targetBookId).resultObjects()
		
		guard !sourceParagraphs.isEmpty && !targetParagraphs.isEmpty else
		{
			assertionFailure("Didn't find any paragraphs")
			return
		}
		
		// Makes the binding based on the matched paragraphs
		let bindings = match(sourceParagraphs, and: targetParagraphs).map { (source, target) in return (source.idString, target.idString) }
		*/
		
		// Finds the paragraphs
		let sourceParagraphIds = try! ParagraphView.instance.latestParagraphQuery(bookId: sourceBookId).resultRows().map { $0.id! }
		let targetParagraphIds = try! ParagraphView.instance.latestParagraphQuery(bookId: targetBookId).resultRows().map { $0.id! }
		
		print("TEST: Found \(sourceParagraphIds.count) -> \(targetParagraphIds.count) paragraphs")
		
		guard !sourceParagraphIds.isEmpty && !targetParagraphIds.isEmpty else
		{
			assertionFailure("Didn't didn't find any paragraphs!")
			return
		}
		
		// This simple algorithm only works if there is equal amount of paragraphs on both sides
		guard sourceParagraphIds.count == targetParagraphIds.count else
		{
			assertionFailure("Different amount of paragraphs on different sides -> Can't make a simple binding")
			return
		}
		
		// Creates the binding
		var bindings = [(String, String)]()
		for i in 0 ..< sourceParagraphIds.count
		{
			bindings.append((sourceParagraphIds[i], targetParagraphIds[i]))
		}
		
		let binding = ParagraphBinding(sourceBookId: sourceBookId, targetBookId: targetBookId, bindings: bindings, creatorId: userId)
		try! binding.push()
		
		print("TEST: DONE")
	}
	
	func testReadBind()
	{
		let bookCode = "gal"
		let sourceLanguageName = "English"
		let targetLanguageName = "Finnish"
		
		// Reads language data
		let sourceLanguage = try! LanguageView.instance.language(withName: sourceLanguageName)
		let targetLanguage = try! LanguageView.instance.language(withName: targetLanguageName)
		
		// Finds book data
		guard let sourceBookId = try! BookView.instance.booksQuery(code: bookCode, languageId: sourceLanguage.idString).firstResultRow()?.id else
		{
			assertionFailure("TEST: No book \(bookCode) for language \(sourceLanguageName)")
			return
		}
		
		guard let targetBookId = try! BookView.instance.booksQuery(code: bookCode, languageId: targetLanguage.idString).firstResultRow()?.id else
		{
			assertionFailure("TEST: No book \(bookCode) for language \(targetLanguageName)")
			return
		}

		// Finds the existing binding between the books
		if let binding = try! ParagraphBindingView.instance.latestBinding(from: sourceBookId, to: targetBookId)
		{
			print("TEST: Binding exists")
			print(binding.toPropertySet)
		}
		else
		{
			print("TEST: No binding exists")
		}
	}
	
	// 0456c66d-fd56-43f1-986c-8b8eb538b093
	func testReadBinds()
	{
		print("TEST: STARTED")
		
		let bindings = try! ParagraphBindingView.instance.createQuery().resultObjects()
		for binding in bindings
		{
			print("TEST: \(binding.idString): \(binding.toPropertySet)")
		}
		
		print("TEST: DONE")
	}
	
	func testUSXParsing()
	{
		guard let url = Bundle.main.url(forResource: "TIT_DURI", withExtension: "usx")
		else
		{
			XCTFail("Couldn't find url")
			return
		}
		
		// Finds the target language
		let language = try! LanguageView.instance.language(withName: "Duri")
		
		// Book finding algorithm
		func findBook(projectId: String, languageId: String, code: String, identifier: String) -> Book?
		{
			// Performs a database query
			return try! BookView.instance.booksQuery(code: code, languageId: languageId, identifier: identifier).firstResultObject()
		}
		
		// Paragraph matching algorithm (incomplete)
		func paragraphMatcher(existingParagraphs: [Paragraph], newParagraphs: [Paragraph]) -> [(Paragraph, Paragraph)]?
		{
			fatalError("Paragraph matcher not implemented")
		}
		
		// Creates the parser first
		let parser = XMLParser(contentsOf: url)!
		let usxParserDelegate = USXParser(projectId: "test-project", userId: "testuserid", languageId: language.idString, findReplacedBook: findBook, matchParagraphs: paragraphMatcher)
		parser.delegate = usxParserDelegate
		
		// Parses the xml
		// Counts the performance as well
		self.measure{ parser.parse() }
		
		// Checks the results
		XCTAssertTrue(usxParserDelegate.success, "\(usxParserDelegate.error)")
		
		// Prints the results
		for book in usxParserDelegate.parsedBooks
		{
			print()
			print("\(book.code): \(book.identifier)")
			
			// Finds the first 7 paragraphs and prints them
			let paragraphs = try! ParagraphView.instance.latestParagraphQuery(bookId: book.idString).limitedTo(7).resultObjects()
			
			for paragraph in paragraphs
			{
				print()
				print(paragraph.text)
			}
		}
	}
	/*
	// TODO: WET WET
	func match(_ sources: [Paragraph], and targets: [Paragraph]) -> [(Paragraph, Paragraph)]
	{
		guard !sources.isEmpty && !targets.isEmpty else
		{
			print("ERROR: Nothing to match!")
			return []
		}
		
		var matches = [(Paragraph, Paragraph)]()
		var nextSourceIndex = 0
		var nextTargetIndex = 0
		
		// Matches paragraphs. A single paragraph may be matched with multiple consecutive paragraphs
		while nextSourceIndex < sources.count || nextTargetIndex < targets.count
		{
			// Finds out how many paragraphs without range there are on either side consecutively
			let noRangeSources = sources.take(from: nextSourceIndex, while: { $0.range == nil })
			let noRangeTargets = targets.take(from: nextTargetIndex, while: { $0.range == nil })
			
			// Matches them together, or if there are no matching paragraphs on either side, matches them to the latest paragraph instead
			if noRangeSources.isEmpty
			{
				// If both sides have ranges, matches the paragraphs based on range overlapping
				if noRangeTargets.isEmpty
				{
					// Goes through sources until one is found that doesn't have a range
					var lastConnectedTargetRange: VerseRange?
					var lastConnectedTargetIndex: Int?
					var targetWithoutRangeFound = false
					while nextSourceIndex < sources.count, let sourceRange = sources[nextSourceIndex].range
					{
						// The latest connected target may be connected to multiple sources
						if let lastConnectedTargetIndex = lastConnectedTargetIndex, let lastConnectedTargetRange = lastConnectedTargetRange, sourceRange.overlaps(with: lastConnectedTargetRange)
						{
							matches.append((sources[nextSourceIndex], targets[lastConnectedTargetIndex]))
						}
						else if targetWithoutRangeFound
						{
							break
						}
						
						// Goes through the targets (matching overlaps) until
						// a) No match can be made -> moves to next source
						// b) No target range available -> moves to next source but activates a different state too
						while nextTargetIndex < targets.count
						{
							if let targetRange = targets[nextTargetIndex].range
							{
								if sourceRange.overlaps(with: targetRange)
								{
									matches.append((sources[nextSourceIndex], targets[nextTargetIndex]))
									lastConnectedTargetIndex = nextTargetIndex
									lastConnectedTargetRange = targetRange
									nextTargetIndex += 1
								}
								else
								{
									break
								}
							}
							else
							{
								targetWithoutRangeFound = true
								break
							}
						}
						
						nextSourceIndex += 1
					}
				}
				else
				{
					let matchingSource = nextSourceIndex == 0 ? sources.first! : sources[nextSourceIndex - 1]
					noRangeTargets.forEach { matches.append((matchingSource, $0)) }
					nextTargetIndex += noRangeTargets.count
				}
			}
			else if noRangeTargets.isEmpty
			{
				let matchingTarget = nextTargetIndex == 0 ? targets.first! : targets[nextTargetIndex - 1]
				noRangeSources.forEach { matches.append(($0, matchingTarget)) }
				nextSourceIndex += noRangeSources.count
			}
			else
			{
				// TODO: Should probably let the user match paragraphs when the case is ambiguous (different number of non-verse paragraphs)
				// Now simply binds the first last to many
				let commonIndices = min(noRangeSources.count, noRangeTargets.count)
				for i in 0 ..< commonIndices
				{
					matches.append((noRangeSources[i], noRangeTargets[i]))
				}
				for i in commonIndices ..< noRangeSources.count
				{
					matches.append((noRangeSources[i], noRangeTargets[commonIndices - 1]))
				}
				for i in commonIndices ..< noRangeTargets.count
				{
					matches.append((noRangeSources[commonIndices - 1], noRangeTargets[i]))
				}
				
				nextSourceIndex += noRangeSources.count
				nextTargetIndex += noRangeTargets.count
			}
		}
		
		// And if there happen to be any unmatched elements at the end, connects them to the last available match
		for i in nextTargetIndex ..< targets.count
		{
			matches.append((sources.last!, targets[i]))
		}
		
		return matches
	}
	
	/*
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }*/
*/
}
