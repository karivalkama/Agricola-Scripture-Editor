//
//  TranslationVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.9.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import UIKit

// TranslationVC is the view controller used in the translation / review / work view
class TranslationVC: UIViewController, UITableViewDataSource, LiveQueryListener, CellInputListener, AppStatusListener
{
	// TYPES	----------
	
	typealias Queried = Paragraph
	
	
	// OUTLETS	----------
	
	@IBOutlet weak var translationTableView: UITableView!
	
	
	// PROPERTIES	---------
	
	// Testing data
	private var book: Book?
	private let userId = "testuserid"
	
	// Current paragraph status in database
	private var currentData = [Paragraph]()
	
	// paragraph data modified, but not committed by user
	// Key = paragraph id
	private var inputData = [String : NSAttributedString]()
	private var active = false
	
	// The live query used for retrieving translation data
	private var translationQueryManager: LiveQueryManager<Paragraph>?
	
	private var committing = false
	
	
	// VIEW CONTROLLER	-----
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		// (Epic hack which) Makes table view cells have automatic height
		translationTableView.rowHeight = UITableViewAutomaticDimension
		translationTableView.estimatedRowHeight = 160
		
		//translationTableView.delegate = self
		translationTableView.dataSource = self
		
		// TODO: Use certain ranges, which should be changeable
		// Reads necessary data (TEST)
		let language = try! LanguageView.instance.language(withName: "English")
		if let book = try! Book.fromQuery(BookView.instance.createQuery(languageId: language.idString, code: "GAL", identifier: nil))
		{
			self.book = book
			let query = ParagraphView.instance.createQuery(bookId: book.idString, chapterIndex: nil, sectionIndex: nil, paragraphIndex: nil).asLive()
			translationQueryManager = LiveQueryManager<Paragraph>(query: query)
			translationQueryManager?.addListener(AnyLiveQueryListener(self))
		}
	}
	
	override func viewDidAppear(_ animated: Bool)
	{
		AppStatusHandler.instance.registerListener(self)
		activate()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		AppStatusHandler.instance.removeListener(self)
		deactivate()
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
			print("STATUS: UPDATES ROWS")
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
	
	
	// APP STATUS LISTENING	---------
	
	func appWillClose()
	{
		deactivate()
	}
	
	func appWillContinue()
	{
		activate()
	}
	
	
	// OTHER	---------------------
	
	private func commit()
	{
		// TODO: Prompt the user to handle edit conflicts
		// Makes changes to the actual paragraphs (where edited)
		// And saves new commits
	}
	
	private func activate()
	{
		if !active
		{
			print("STATUS: ACTIVATING")
			active = true
			
			// Retrieves edit data from the database
			// TODO: rework after user data and book data are in place
			if inputData.isEmpty
			{
				let paragraphEdits = try! getParagraphEdits()
				
				print("STATUS: FOUND \(paragraphEdits.count) edits")
				
				for edit in paragraphEdits
				{
					print("STATUS: '\(edit.paragraph.text)'")
					
					inputData[edit.targetId] = edit.paragraph.toAttributedString(options: [Paragraph.optionDisplayParagraphRange : false])
				}
			}
			
			// Starts the database listening process, if not yet started
			translationQueryManager?.start()
		}
	}
	
	private func deactivate()
	{
		if active
		{
			print("STATUS: DEACTIVATING")
			active = false
			
			// Ends the database listening process, if present
			translationQueryManager?.stop()
			
			// Saves paragraph edit status to the database
			do
			{
				// Deletes previous data
				let paragraphEdits = try! getParagraphEdits()
				paragraphEdits.forEach { try? $0.delete() }
				
				for (paragraphId, attString) in inputData
				{
					if let paragraph = try Paragraph.get(paragraphId)
					{
						print("STATUS: SAVING PARAGRAPH EDIT")
						
						paragraph.replaceContents(with: attString)
						
						let edit = ParagraphEdit(userId: userId, paragraph: paragraph)
						
						print("STATUS: SAVED EDIT: \(edit.toPropertySet)")
						
						try edit.push()
						
						print("STATUS: NEW EDIT WITH ID: " + edit.idString)
					}
				}
			}
			catch
			{
				// TODO: Add better error handling
				print("DB: Failed to save edit status \(error)")
			}
		}
	}
	
	private func getParagraphEdits() throws -> [ParagraphEdit]
	{
		guard let book = book else { return [] }
		return try ParagraphEdit.arrayFromQuery(ParagraphEditView.instance.createQuery(userId: userId, bookId: book.idString, chapterIndex: nil, sectionIndex: nil, paragraphIndex: nil))
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



