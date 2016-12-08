//
//  TranslationVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

// TranslationVC is the view controller used in the translation / review / work view
class TranslationVC: UIViewController, UITableViewDataSource, LiveQueryListener, CellInputListener
{
	// TYPES	----------
	
	typealias Queried = Paragraph
	
	
	// Outlets	----------
	
	@IBOutlet weak var translationTableView: UITableView!
	
	
	// Vars	--------------
	
	// Temporary test vars
	private var book: Book!
	
	// Current paragraph status in database
	private var currentData = [Paragraph]()
	
	// paragraph data modified, but not committed by user
	// Key = paragraph id
	private var inputData = [String : NSAttributedString]()
	
	// The live query used for retrieving translation data
	private var translationQueryManager: LiveQueryManager<Paragraph>!
	
	private var committing = false
	
	
	// Overridden	-----
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		// Reads necessary data (TEST)
		//let language = try! LanguageView.instance.language(withName: "English")
		//book = try! Book.fromQuery(BookView.instance.createQuery(languageId: language.idString, code: "GAL", identifier: nil))!
		
		// (Epic hack which) Makes table view cells have automatic height
		translationTableView.rowHeight = UITableViewAutomaticDimension
		translationTableView.estimatedRowHeight = 160
		
		//translationTableView.delegate = self
		translationTableView.dataSource = self
		
		// TODO: Use certain ranges, which should be changeable
		//let query = ParagraphView.instance.createQuery(bookId: book.idString, chapterIndex: nil, sectionIndex: nil, paragraphIndex: nil).asLive()
		//translationQueryManager = LiveQueryManager<Paragraph>(query: query)
		//translationQueryManager.addListener(AnyLiveQueryListener(self))
	}
	
	override func viewDidAppear(_ animated: Bool)
	{
		// Starts the database listening process, if not yet started
		//translationQueryManager.start()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		// Ends the database listening process, if present
		//translationQueryManager.stop()
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		
		// Dispose of any resources that can be recreated.
	}
	
	
	// TABLE VIEW DATASOURCE	------
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return currentData.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		// Finds a reusable cell
		let cell = translationTableView.dequeueReusableCell(withIdentifier: "TranslationCell", for: indexPath) as! TranslationCell
		
		// Updates cell content (either from current data or from current input status)
		let paragraph = currentData[indexPath.row]
		
		var stringContents: NSAttributedString!
		if let inputVersion = inputData[paragraph.idString]
		{
			stringContents = inputVersion
		}
		else
		{
			stringContents = paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false])
		}
		
		cell.setContent(to: stringContents, withId: paragraph.idString)
		cell.inputListener = self
		return cell
	}
	
	
	// QUERY LISTENING	-------------
	
	func rowsUpdated(rows: [Row<Paragraph>], forQuery queryId: String?)
	{
		// Updates paragraph data (unless committing is in progress)
		if !committing
		{
			// TODO: Check for conflicts
			currentData = rows.map { $0.object }
			translationTableView.reloadData()
		}
	}
	
	
	// CELL LISTENING	-------------
	
	func cellContentChanged(id: String, newContent: NSAttributedString)
	{
		inputData[id] = newContent
		
		// Resets cell height
		translationTableView.beginUpdates()
		translationTableView.endUpdates()
	}
	
	
	//@available (*, deprecated)
	/*
	private func readTestDataFromUSX()
	{
		guard let url = Bundle.main.url(forResource: "GAL", withExtension: "usx")
			else
		{
			fatalError("Couldn't find url")
		}
		
		// Creates the parser first
		let parser = XMLParser(contentsOf: url)!
		let usxParserDelegate = USXParser()
		parser.delegate = usxParserDelegate
		
		// Parses the xml
		parser.parse()
		
		// Reads the data from the book(s)
		testContent = []
		for book in usxParserDelegate.parsedBooks
		{
			testContent += book.toAttributedStringCollection(displayParagraphRanges: false)
		}
	}
*/
	
	/*
	private func generateTestData()
	{
		let testString = "The first verse is here. #Followed by another.€A new paragraph starts. #asldkalsk dlka #asdjkkaj a#jasdkjadkj€ASdkkddkkdslkskd#asjddjddd€asdjdjdj"
		var paragraphs = [Para]()
		
		var index = 0
		for paraText in testString.components(separatedBy: "€")
		{
			index += 1
			
			var verses = [Verse]()
			for verseText in paraText.components(separatedBy: "#")
			{
				let start = VerseIndex(index)
				let end = VerseIndex(index + 1)
				verses.append(Verse(range: VerseRange(start, end), content: verseText))
				index += 1
			}
			
			paragraphs.append(Para(content: verses))
		}
		
		testContent = paragraphs
	}*/
}



