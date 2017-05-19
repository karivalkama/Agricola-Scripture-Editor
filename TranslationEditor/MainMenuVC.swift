//
//  MainMenuVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// TODO: Implement feature that opens mail for usx files. Check: http://stackoverflow.com/questions/29422917/how-to-launch-the-ios-mail-app-in-swift

// This view controller handles the main menu features like connection hosting, and book selection
class MainMenuVC: UIViewController, LiveQueryListener, UITableViewDataSource, UITableViewDelegate
{
	// TYPES	------------------
	
	typealias QueryTarget = ProjectBooksView
	
	
	// OUTLETS	------------------
	
	@IBOutlet weak var topBar: TopBarUIView!
	@IBOutlet weak var bookTableView: UITableView!
	
	
	// ATTRIBUTES	--------------
	
	private var queryManager: LiveQueryManager<ProjectBooksView>?
	private var books = [Book]()
	private var progress = [String: BookProgressStatus]()
	
	
	// INIT	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		// Sets up the table
		// bookTableView.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
		bookTableView.dataSource = self
		bookTableView.delegate = self
		
		// Sets up the top bar
		let title = "Main Menu"
		if let presentingViewController = presentingViewController
		{
			if let presentingViewController = presentingViewController as? SelectAvatarVC
			{
				topBar.configure(hostVC: self, title: title, leftButtonText: presentingViewController.shouldDismissBelow ? "Switch Project" : "Switch Avatar")
				{
					Session.instance.avatarId = nil
					presentingViewController.dismissFromAbove()
				}
			}
			else
			{
				topBar.configure(hostVC: self, title: title, leftButtonText: "Back")
				{
					self.dismiss(animated: true, completion: nil)
				}
			}
		}
		else
		{
			topBar.configure(hostVC: self, title: title)
		}
		
		do
		{
			guard let projectId = Session.instance.projectId else
			{
				print("ERROR: No project selected when in main menu")
				return
			}
			
			guard let project = try Project.get(projectId) else
			{
				print("ERROR: Couldn't find correct project data")
				return
			}
			
			// Loads the available book data
			queryManager = ProjectBooksView.instance.booksQuery(projectId: projectId, languageId: project.languageId).liveQueryManager
			queryManager?.addListener(AnyLiveQueryListener(self))
		}
		catch
		{
			print("ERROR: Failed to setup data for the main menu. \(error)")
		}
    }
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		
		queryManager?.start()
		
		guard let projectId = Session.instance.projectId else
		{
			print("ERROR: Project must be selected when in main menu")
			return
		}
		
		// Updates the book progress status
		do
		{
			progress = try BookProgressView.instance.progressForProjectBooks(projectId: projectId)
			bookTableView.reloadData()
		}
		catch
		{
			print("ERROR: Failed to read book progress status")
		}
		
		// If there are USX files waiting for processing, displays import view
		if let usxUrl = USXImportStack.instance.pop()
		{
			if let controller = UIStoryboard(name: "MainMenu", bundle: nil).instantiateViewController(withIdentifier: "ImportUSX") as? ImportUSXVC
			{
				controller.configure(usxFileURL: usxUrl)
				present(controller, animated: true, completion: nil)
			}
			else
			{
				print("ERROR: Failed to open USX import view")
			}
		}
		else if let bookId = Session.instance.bookId
		{
			// If a book has already been selected, moves to the translation view
			do
			{
				if let book = try Book.get(bookId)
				{
					moveToTranslation(book: book)
				}
				else
				{
					print("ERROR: No data available for the selected book")
				}
			}
			catch
			{
				print("ERROR: Failed to read book data. \(error)")
			}
		}
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		queryManager?.stop()
	}
	
	
	// IMPLEMENTED METHODS	-----
	
	func rowsUpdated(rows: [Row<ProjectBooksView>])
	{
		do
		{
			books = try rows.map { try $0.object() }.sorted { $0.0.code < $0.1.code}
			bookTableView.reloadData()
		}
		catch
		{
			print("ERROR: Failed to read through book data")
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return books.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: BookCell.identifier, for: indexPath) as! BookCell
		
		let book = books[indexPath.row]
		cell.configure(bookCode: book.code, identifier: book.identifier, progress: progress[book.idString])
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		let book = books[indexPath.row]
		Session.instance.bookId = book.idString
		moveToTranslation(book: book)
	}
	
	
	// OTHER METHODS	--------
	
	private func moveToTranslation(book: Book)
	{
		// Moves to the main translation view
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		guard let controller = storyboard.instantiateInitialViewController() as? TranslationVC else
		{
			print("ERROR: Failed to instantiate the translation view")
			return
		}
		
		// Sets the book ready for the translation VC
		controller.configure(book: book)
		present(controller, animated: true, completion: nil)
	}
}
