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
	@IBOutlet weak var manageUsersButton: BasicButton!
	@IBOutlet weak var manageSharedAccountButton: BasicButton!
	@IBOutlet weak var bookDataStackView: StatefulStackView!
	
	
	// ATTRIBUTES	--------------
	
	private var queryManager: LiveQueryManager<ProjectBooksView>?
	private var books = [Book]()
	private var progress = [String: BookProgressStatus]()
	
	
	// INIT	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		topBar.configure(hostVC: self, title: "Main Menu")
		
		bookDataStackView.register(bookTableView, for: .data)
		bookDataStackView.registerDefaultNoDataView(heading: "No Books Found", description: "You can add books by:\n1) Using the 'Import Book from Another Project' -feature\n2) Opening USX files using Agricola\n\nPlease note that the structure of a new translation is based on the first read book so add first those which have the best structure.")
		bookDataStackView.setState(.loading)
		
		// Sets up the table
		// bookTableView.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
		bookTableView.dataSource = self
		bookTableView.delegate = self
		
		do
		{
			guard let projectId = Session.instance.projectId else
			{
				print("ERROR: No project selected when in main menu")
				bookDataStackView.errorOccurred()
				return
			}
			
			guard let project = try Project.get(projectId) else
			{
				print("ERROR: Couldn't find correct project data")
				bookDataStackView.errorOccurred()
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
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		// Sets up the top bar
		let title = "Main Menu"
		if let presentingViewController = presentingViewController
		{
			if let presentingViewController = presentingViewController as? SelectAvatarVC
			{
				topBar.configure(hostVC: self, title: title, leftButtonText: presentingViewController.shouldDismissBelow ? "Switch Project" : "Switch User")
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
			topBar.updateUserView()
		}
		
		queryManager?.start()
		
		guard let projectId = Session.instance.projectId else
		{
			print("ERROR: Project must be selected when in main menu")
			return
		}
		
		// Updates the book progress status (asynchronous)
		DispatchQueue.main.async
		{
			do
			{
				self.progress = try BookProgressView.instance.progressForProjectBooks(projectId: projectId)
				self.bookTableView.reloadData()
			}
			catch
			{
				print("ERROR: Failed to read book progress status")
			}
		}
		
		// Admin tools are only enabled for admin users
		var adminToolsEnabled = false
		do
		{
			if let avatarId = Session.instance.avatarId, let avatar = try Avatar.get(avatarId), avatar.isAdmin
			{
				adminToolsEnabled = true
			}
		}
		catch
		{
			print("ERROR: Failed to read avatar data. \(error)")
		}
		manageUsersButton.isEnabled = adminToolsEnabled
		manageSharedAccountButton.isEnabled = adminToolsEnabled
		
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
	
	
	// ACTIONS	-----------------
	
	@IBAction func manageUsersPressed(_ sender: Any)
	{
		displayAlert(withIdentifier: ManageUsersVC.identifier, storyBoardId: "MainMenu")
	}
	
	@IBAction func manageAccountPressed(_ sender: Any)
	{
		displayAlert(withIdentifier: EditSharedAccountVC.identifier, storyBoardId: "Common")
	}
	
	
	// IMPLEMENTED METHODS	-----
	
	func rowsUpdated(rows: [Row<ProjectBooksView>])
	{
		do
		{
			books = try rows.map { try $0.object() }.sorted { $0.code < $1.code}
			bookDataStackView.dataLoaded(isEmpty: books.isEmpty)
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
