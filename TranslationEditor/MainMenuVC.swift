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
class MainMenuVC: UIViewController, QRCodeReaderViewControllerDelegate, LiveQueryListener
{
	// TYPES	------------------
	
	typealias QueryTarget = BookView
	
	
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
	
	// private let queryManager: LiveQueryManager<BookView>
	private var books = [Book]()
	
	// The reader used for capturing QR codes, initialized only when used
	private lazy var readerVC = QRCodeReaderViewController(builder: QRCodeReaderViewControllerBuilder
	{
		$0.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode], captureDevicePosition: .back)
	})
	
	
	// INIT	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		// Some views are hidden initially
		// TODO: Curent hosting status should affect these, naturally
		qrView.isHidden = true
		
		// The QR Code scanning feature could be unavailable, which will prevent the use of P2P joining
		updateConnectionButtonAvailability()
		
		do
		{
			// Sets up user status
			if let avatarId = Session.instance.avatarId, let avatarInfo = try AvatarInfo.get(avatarId: avatarId)
			{
				userView.configure(userName: try avatarInfo.displayName(), userIcon: avatarInfo.image.or(#imageLiteral(resourceName: "userIcon")))
			}
		}
		catch
		{
			print("Failed to load avatar data. \(error)")
		}
		
		// Loads the available book data
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
	
	func rowsUpdated(rows: [Row<BookView>])
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
