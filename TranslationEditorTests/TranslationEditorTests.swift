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
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
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
		let book = Book(code: "GAL", identifier: "English: This and This Translation", languageId: language.idString)
		
		let paragraph = Paragraph(bookId: book.idString, chapterIndex: 1, sectionIndex: 1, index: 1, content: [], creatorId: "testuserid")
		
		assert(paragraph.bookCode == "GAL")
		
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
		let query = DATABASE.createAllDocumentsQuery()
		let results = try! query.run()
		
		while let row = results.nextRow(), let doc = row.document
		{
			try! doc.delete()
		}
	}
	
	func testRemoveDataOfType()
	{
		let type = Paragraph.type
		
		let query = DATABASE.createAllDocumentsQuery()
		let results = try! query.run()
		
		while let row = results.nextRow(), let document = row.document
		{
			if document[PROPERTY_TYPE] as? String == type
			{
				print("deleting...")
				try! document.delete()
			}
		}
		
		print("done!")
	}
	
	func testReadDataOfType()
	{
		let type = ParagraphBinding.type
		
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
		for language in languages
		{
			print("Books in \(language.name):")
			
			let books = try! BookView.instance.booksQuery(languageId: language.idString).resultObjects()
			
			for book in books
			{
				let paragraphs = try! ParagraphView.instance.latestParagraphQuery(bookId: book.idString).resultObjects()
				
				print("- \(book.code) - \(book.identifier) (\(paragraphs.count) paragraphs)")
				
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
	}
	
	func testMakeFinnishCopies()
	{
		let userId = "testuserid"
		let sourceLanguageName = "English"
		let targetLanguageName = "Finnish"
		
		// Finds / makes language data
		let sourceLanguage = try! LanguageView.instance.language(withName: sourceLanguageName)
		let targetLanguage = try! LanguageView.instance.language(withName: targetLanguageName)
		
		// Finds source books
		let sourceBooks = try! BookView.instance.booksQuery(languageId: sourceLanguage.idString).resultObjects()
		
		// Makes an empty copy of each, if there isn't one already
		for sourceBook in sourceBooks
		{
			if try! BookView.instance.booksQuery(languageId: targetLanguage.idString, code: sourceBook.code).firstResultRow() == nil
			{
				print("Creating a \(targetLanguageName) copy of \(sourceLanguageName) book \(sourceBook.code): \(sourceBook.identifier)")
				_ = try! sourceBook.makeEmptyCopy(identifier: "Test Version", languageId: targetLanguage.idString, userId: userId)
			}
		}
		
		print("Done")
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
		guard let sourceBookId = try! BookView.instance.booksQuery(languageId: sourceLanguage.idString, code: bookCode).firstResultRow()?.id else
		{
			assertionFailure("TEST: No book \(bookCode) for language \(sourceLanguageName)")
			return
		}
		
		guard let targetBookId = try! BookView.instance.booksQuery(languageId: targetLanguage.idString, code: bookCode).firstResultRow()?.id else
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
		guard let sourceBookId = try! BookView.instance.booksQuery(languageId: sourceLanguage.idString, code: bookCode).firstResultRow()?.id else
		{
			assertionFailure("TEST: No book \(bookCode) for language \(sourceLanguageName)")
			return
		}
		
		guard let targetBookId = try! BookView.instance.booksQuery(languageId: targetLanguage.idString, code: bookCode).firstResultRow()?.id else
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
		guard let url = Bundle.main.url(forResource: "GAL", withExtension: "usx")
		else
		{
			XCTFail("Couldn't find url")
			return
		}
		
		// Finds the target language
		let language = try! LanguageView.instance.language(withName: "English")
		
		// Book finding algorithm
		func findBook(languageId: String, code: String, identifier: String) -> Book?
		{
			// Performs a database query
			return try! BookView.instance.booksQuery(languageId: languageId, code: code, identifier: identifier).firstResultObject()
		}
		
		// Paragraph matching algorithm (incomplete)
		func paragraphMatcher(existingParagraphs: [Paragraph], newParagraphs: [Paragraph]) -> [(Paragraph, Paragraph)]?
		{
			fatalError("Paragraph matcher not implemented")
		}
		
		// Creates the parser first
		let parser = XMLParser(contentsOf: url)!
		let usxParserDelegate = USXParser(userId: "testuserid", languageId: language.idString, findReplacedBook: findBook, matchParagraphs: paragraphMatcher)
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
}
