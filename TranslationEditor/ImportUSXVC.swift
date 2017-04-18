//
//  ImportUSXVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 13.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This VC is used for importing new books / updating existing data from USX files
class ImportUSXVC: UIViewController
{
	// OUTLETS	--------------
	
	@IBOutlet weak var topUserView: TopUserView!
	@IBOutlet weak var bookLabel: UILabel!
	@IBOutlet weak var paragraphTableView: UITableView!
	@IBOutlet weak var selectLanguageView: FilteredSingleSelection!
	@IBOutlet weak var selectBookTableView: UITableView!
	
	
	// ATTRIBUTES	---------
	
	private var usxURL: URL?
	private var book: Book?
	private var paragraphs = [Paragraph]()
	
	
	// LOAD	-----------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		// Reads paragraph data first
		guard let usxURL = usxURL else
		{
			fatalError("ImportUSXVC must be configured before use")
		}
		
		guard let projectId = Session.instance.projectId else
		{
			print("ERROR: Project must be defined before USX import")
			return
		}
		
		guard let avatarId = Session.instance.avatarId else
		{
			print("ERROR: Avatar must be selected before USX import")
			return
		}
		
		guard let parser = XMLParser(contentsOf: usxURL) else
		{
			print("ERROR: Couldn't create an XML parser")
			return
		}
		
		// Language is set afterwards
		let usxParserDelegate = USXParser(projectId: projectId, userId: avatarId, languageId: "")
		parser.delegate = usxParserDelegate
		parser.parse()
		
		guard usxParserDelegate.success else
		{
			print("ERROR: USX parsing failed. \(usxParserDelegate.error!)")
			return
		}
		
		// Only picks the first parsed book
		// TODO: Add handling for USX files that contain multiple books
		guard let bookData = usxParserDelegate.parsedBooks.first else
		{
			print("ERROR: Couldn't parse any book data")
			return
		}
		
		if usxParserDelegate.parsedBooks.count > 1
		{
			print("WARNING: Multiple books were read. Only the first one is used.")
		}
		
		book = bookData.book
		paragraphs = bookData.paragraphs
		
		// Sets up the paragraph table
		paragraphTableView.register(UINib(nibName: "ParagraphCell", bundle: nil), forCellReuseIdentifier: ParagraphCell.identifier)
		paragraphTableView.rowHeight = UITableViewAutomaticDimension
		paragraphTableView.estimatedRowHeight = 160
		
		// Sets up other views
		bookLabel.text = "\(book!.code): \(book!.identifier)"
		
		do
		{
			try topUserView.configure(avatarId: avatarId)
		}
		catch
		{
			print("ERROR: Failed to setup the view properly. \(error)")
		}
    }

	
	// ACTIONS	-------------
	
	@IBAction func cancelButtonPressed(_ sender: Any)
	{
		
	}
	
	
	// OTHER METHODS	----
	
	func configure(usxFileURL: URL)
	{
		usxURL = usxFileURL
	}
}

fileprivate class SelectBookTableController: NSObject, UITableViewDataSource
{
	// ATTRIBUTES	--------
	
	weak var delegate: SelectBookTableControllerDelegate?
	
	private weak var table: UITableView!
	private let newIdentifier: String
	
	private var books = [Book]()
	private var allowInsert = false
	
	
	// INIT	----------------
	
	init(table: UITableView, newIdentifier: String)
	{
		self.table = table
		self.newIdentifier = newIdentifier
		
		super.init()
		
		table.dataSource = self
	}
	
	
	// OTHER METHODS	---
	
	func update(books: [Book])
	{
		self.books = books
		allowInsert = true
		
		table.reloadData()
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func numberOfSections(in tableView: UITableView) -> Int
	{
		return allowInsert ? 2 : 1
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		switch section
		{
		case 0: return "Existing books"
		case 1: return "Insert a new book"
		default: return nil
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if section == 0
		{
			return books.count
		}
		else
		{
			return 1
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
		
		if indexPath.section == 0
		{
			cell.configure(text: books[indexPath.row].identifier)
		}
		else
		{
			cell.configure(text: "NEW: \(newIdentifier)")
		}
		
		return cell
	}
}

fileprivate protocol SelectBookTableControllerDelegate: class
{
	// This method is called when an existing book is selected
	func bookSelected(_ book: Book)
	
	// This method is called when the insert book option is selected
	func insertSelected()
}
