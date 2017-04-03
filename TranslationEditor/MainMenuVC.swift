//
//  MainMenuVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit
import AVFoundation
import QRCodeReader

// This view controller handles the main menu features like connection hosting, and book selection
class MainMenuVC: UIViewController, QRCodeReaderViewControllerDelegate, LiveQueryListener, UITableViewDataSource, UITableViewDelegate, ConnectionListener
{
	// TYPES	------------------
	
	typealias QueryTarget = ProjectBooksView
	
	
	// OUTLETS	------------------
	
	@IBOutlet weak var bookTableView: UITableView!
	@IBOutlet weak var userView: TopUserView!
	@IBOutlet weak var joinButton: UIButton!
	@IBOutlet weak var disconnectButton: UIButton!
	@IBOutlet weak var hostingSwitch: UISwitch!
	@IBOutlet weak var qrImageView: UIImageView!
	@IBOutlet weak var onlineStatusView: OnlineStatusView!
	@IBOutlet weak var qrView: UIView!
	
	
	// ATTRIBUTES	--------------
	
	private var queryManager: LiveQueryManager<ProjectBooksView>?
	private var books = [Book]()
	
	// The reader used for capturing QR codes, initialized only when used
	private lazy var readerVC: QRCodeReaderViewController =
	{
		let builder = QRCodeReaderViewControllerBuilder
		{
			$0.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode], captureDevicePosition: .back)
		}
		
		return QRCodeReaderViewController(builder: builder)
	}()
	
	
	// INIT	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		// Only displays qr view while hosting. Only displays connection status while joined
		qrView.isHidden = P2PHostSession.instance == nil
		onlineStatusView.isHidden = !P2PClientSession.isConnected
		
		// The QR Code scanning feature could be unavailable, which will prevent the use of P2P joining
		updateConnectionButtonAvailability()
		
		// Sets up the table
		bookTableView.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
		bookTableView.dataSource = self
		bookTableView.delegate = self
		
		do
		{
			// Sets up user status
			if let avatarId = Session.instance.avatarId, let avatarInfo = try AvatarInfo.get(avatarId: avatarId)
			{
				userView.configure(userName: try avatarInfo.displayName(), userIcon: avatarInfo.image.or(#imageLiteral(resourceName: "userIcon")))
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
		
		queryManager?.start()
	}
	
	override func viewDidDisappear(_ animated: Bool)
	{
		queryManager?.stop()
	}
	
	
	// ACTIONS	------------------
	
	@IBAction func joinButtonPressed(_ sender: Any)
	{
		// TODO: Presents a join P2P VC
		readerVC.delegate = self
		readerVC.modalPresentationStyle = .formSheet
		present(readerVC, animated: true, completion: nil)
	}
	
	@IBAction func disconnectButtonPressed(_ sender: Any)
	{
		// TODO: Disconnects from the current P2P session
		P2PClientSession.stop()
		updateConnectionButtonAvailability()
		onlineStatusView.isHidden = true
	}
	
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
		
		updateConnectionButtonAvailability()
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
	
	@IBAction func addUserButtonPressed(_ sender: Any)
	{
		displayAlert(withIdentifier: "EditAvatar", storyBoardId: "MainMenu")
	}
	
	// IMPLEMENTED METHODS	-----
	
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult)
	{
		// TODO: Parse result and start P2P session
		reader.stopScanning()
		print("STATUS: Scanned QR code result: \(result.value) (of type \(result.metadataType))")
	}
	
	func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput)
	{
		print("STATUS: Switched camera")
	}
	
	func readerDidCancel(_ reader: QRCodeReaderViewController)
	{
		reader.stopScanning()
		print("STATUS: QR Capture session cancelled")
	}
	
	func rowsUpdated(rows: [Row<ProjectBooksView>])
	{
		do
		{
			books = try rows.map { try $0.object() }
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
		let cell = tableView.dequeueReusableCell(withIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
		
		cell.configure(text: "\(books[indexPath.row].code.uppercased()) - \(books[indexPath.row].identifier)")
		
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
	
	func onConnectionStatusChange(newStatus status: ConnectionStatus)
	{
		onlineStatusView.status = status
	}
	
	func onConnectionProgressUpdate(transferred: Int, of total: Int, progress: Double)
	{
		onlineStatusView.updateProgress(completed: transferred, of: total, progress: progress)
	}
	
	
	// OTHER METHODS	--------
	
	private func updateConnectionButtonAvailability()
	{
		let isClient = P2PClientSession.isConnected
		let isHosting = P2PHostSession.instance != nil
		
		joinButton.isEnabled = !isHosting && !isClient && QRCodeReader.isAvailable()
		disconnectButton.isEnabled = isClient
		hostingSwitch.isEnabled = !isClient
	}
}
