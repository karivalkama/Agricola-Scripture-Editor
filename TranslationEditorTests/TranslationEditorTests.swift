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
	
	func testParagraphProperties()
	{
		let language = Language(name: "English")
		let book = Book(code: "GAL", identifier: "English: This and This Translation", languageId: language.idString)
		
		let paragraph = Paragraph(bookId: book.idString, chapterIndex: 1, sectionIndex: 1, index: 1, content: [])
		
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
	
	@available (*, deprecated)
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
			return try! Book.fromQuery(BookView.instance.createQuery(languageId: languageId, code: code, identifier: identifier))
		}
		
		// Paragraph matching algorithm (incomplete)
		func paragraphMatcher(existingParagraphs: [Paragraph], newParagraphs: [Paragraph]) -> [(Paragraph, Paragraph)]?
		{
			fatalError("Paragraph matcher not implemented")
		}
		
		// Creates the parser first
		let parser = XMLParser(contentsOf: url)!
		let usxParserDelegate = USXParser(languageId: language.idString, findReplacedBook: findBook, matchParagraphs: paragraphMatcher)
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
			print("\(book.code): \(book.identifier) (\(book.chapters.count) chapters)")
			
			for chapter in book.chapters
			{
				print("\tChapter \(chapter.index) (\(chapter.sections.count) sections)")
				
				for section in chapter.sections
				{
					var sectionName = "First section"
					if let heading = section.name
					{
						sectionName = heading
					}
					
					var rangeString = "---"
					if let range = section.range
					{
						rangeString = range.name
					}
					
					print("\t\t\(rangeString): \(sectionName)")
				}
			}
		}
		
		// Prints the contents of the first paragraph
		if let firstParagraph = usxParserDelegate.parsedBooks.first?.chapters.first?.sections.first?.content.first
		{
			print("\nThe first paragraph:")
			for para in firstParagraph.content
			{
				if para.verses.isEmpty
				{
					print("\t- \(para.text)")
				}
				else
				{
					print("\t- \(para.range!.name)")
					for verse in para.verses
					{
						print("\t\t- \(verse.range.name): \(verse.text)")
					}
				}
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
