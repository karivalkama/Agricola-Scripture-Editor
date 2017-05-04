//
//  MainMenuVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit
import MessageUI

// TODO: Implement feature that opens mail for usx files. Check: http://stackoverflow.com/questions/29422917/how-to-launch-the-ios-mail-app-in-swift

// This view controller handles the main menu features like connection hosting, and book selection
class MainMenuVC: UIViewController, LiveQueryListener, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate
{
	// TYPES	------------------
	
	typealias QueryTarget = ProjectBooksView
	
	
	// OUTLETS	------------------
	
	@IBOutlet weak var bookTableView: UITableView!
	@IBOutlet weak var userView: TopUserView!
	@IBOutlet weak var hostingSwitch: UISwitch!
	@IBOutlet weak var qrImageView: UIImageView!
	@IBOutlet weak var onlineStatusView: OnlineStatusView!
	@IBOutlet weak var qrView: UIView!
	@IBOutlet weak var joinView: P2PJoinView!
	
	
	// ATTRIBUTES	--------------
	
	private var queryManager: LiveQueryManager<ProjectBooksView>?
	private var books = [Book]()
	
	
	// INIT	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		joinView.viewController = self
		joinView.onlineStatusView = onlineStatusView
		joinView.connectionUpdated = { self.hostingSwitch.isEnabled = !P2PClientSession.isConnected }
		
		// Only displays qr view while hosting. Only displays connection status while joined
		qrView.isHidden = P2PHostSession.instance == nil
		
		// Sets up the table
		// bookTableView.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
		bookTableView.dataSource = self
		bookTableView.delegate = self
		
		do
		{
			// Sets up user status
			if let avatarId = Session.instance.avatarId
			{
				try userView.configure(avatarId: avatarId)
			}
			
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
			queryManager = ProjectBooksView.instance.booksQuery(languageId: project.languageId, projectId: projectId).liveQueryManager
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
		
		ConnectionManager.instance.registerListener(joinView)
		joinView.updateAppearance()
		hostingSwitch.isOn = P2PHostSession.instance != nil
		hostingSwitch.isEnabled = !P2PClientSession.isConnected
		
		queryManager?.start()
		
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
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		ConnectionManager.instance.removeListener(joinView)
		queryManager?.stop()
	}
	
	
	// ACTIONS	------------------
	
	@IBAction func hostingStatusChanged(_ sender: Any)
	{
		// TODO: When hosting, generates the appropriate QR code / hosting session
		qrView.isHidden = !hostingSwitch.isOn
		
		guard let projectId = Session.instance.projectId else
		{
			print("ERROR: No project selected for sharing")
			return
		}
		
		if hostingSwitch.isOn
		{
			do
			{
				let session = try P2PHostSession.start(projectId: projectId)
				
				// Sets the new QR Image based on session information
				if var qrCode = session.connectionInformation?.qrCode
				{
					qrCode.size = CGSize(width: 240, height: 240)
					// qrCode.color = Colour.Text.Black.asColour.ciColor
					qrImageView.image = qrCode.image
				}
				else
				{
					print("ERROR: Failed to generate a QR Code for the session")
				}
			}
			catch
			{
				print("ERROR: Failed to start P2P hosting session")
			}
		}
		else
		{
			P2PHostSession.stop()
		}
		
		joinView.updateAppearance()
	}
	
	@IBAction func backButtonPressed(_ sender: Any)
	{
		// goes back to avatar selection
		Session.instance.avatarId = nil
		
		if let selectAvatarVC = presentingViewController as? SelectAvatarVC
		{
			selectAvatarVC.dismissFromAbove()
		}
		else
		{
			dismiss(animated: true, completion: nil)
		}
	}
	
	@IBAction func userViewPressed(_ sender: Any)
	{
		do
		{
			// Loads avatar data from the database first
			guard let avatarId = Session.instance.avatarId else
			{
				print("ERROR: No avatar selected for editing.")
				return
			}
			
			guard let avatar = try Avatar.get(avatarId), let info = try AvatarInfo.get(avatarId: avatarId) else
			{
				print("ERROR: Couldn't find avatar data")
				return
			}
			
			displayAlert(withIdentifier: "EditAvatar", storyBoardId: "MainMenu")
			{
				newVC in
				
				if let editAvatarVC = newVC as? EditAvatarVC
				{
					editAvatarVC.configureForEdit(avatar: avatar, avatarInfo: info)
				}
			}
		}
		catch
		{
			print("ERROR: Database operation failed. \(error)")
		}
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
		cell.configure(bookCode: book.code, identifier: book.identifier, sendActionAvailable: MFMailComposeViewController.canSendMail(), sendAction: sendAction)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		// Moves to the main translation view
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		guard let controller = storyboard.instantiateInitialViewController() as? TranslationVC else
		{
			print("ERROR: Failed to instantiate the translation view")
			return
		}
		
		// Sets the book ready for the translation VC
		controller.configure(book: books[indexPath.row])
		present(controller, animated: true, completion: nil)
	}
	
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
	{
		print("STATUS: Mail send finished with result \(result)")
		dismiss(animated: true, completion: nil)
	}
	
	
	// OTHER METHODS	--------
	
	private func sendAction(cell: BookCell)
	{
		// Sends book USX data via email
		guard let index = bookTableView.indexPath(for: cell)?.row else
		{
			print("ERROR: No index path for the active cell.")
			return
		}
		
		do
		{
			let book = books[index]
			let paragraphs = try ParagraphView.instance.latestParagraphQuery(bookId: book.idString).resultObjects()
			
			let usx = USXWriter().writeUSXDocument(book: book, paragraphs: paragraphs)
			
			guard let data = usx.data(using: .utf8) else
			{
				print("ERROR: Failed to generate USX data")
				return
			}
			
			let mailVC = MFMailComposeViewController()
			mailVC.mailComposeDelegate = self
			mailVC.addAttachmentData(data, mimeType: "application/xml", fileName: "\(book.code.code).usx")
			mailVC.setSubject("\(book.code.name) - \(book.identifier) USX Export")
			
			present(mailVC, animated: true, completion: nil)
		}
		catch
		{
			print("ERROR: Failed to read translation data. \(error)")
		}
	}
}
