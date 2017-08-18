//
//  ConnectionUIView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.5.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation
import AVFoundation
import QRCodeReader
import MessageUI


fileprivate enum ConnectionState
{
	case disconnected, joined, hosting
	
	var actionText: String
	{
		var text = ""
		
		switch self
		{
		case .disconnected: text = "Disconnect"
		case .joined: text = "Join"
		case .hosting: text = "Host"
		}
		
		return NSLocalizedString(text, comment: "A label for an action that changes an online state")
	}
	
	var processingText: String
	{
		var text = ""
		
		switch self
		{
		case .disconnected: text = "Disconnecting"
		case .joined: text = "Joining"
		case .hosting: text = "Hosting"
		}
		
		return NSLocalizedString(text, comment: "A label for a processing online state")
	}
	
	var ongoingText: String
	{
		var text = ""
		
		switch self
		{
		case .disconnected: text = "Disconnected"
		case .joined: text = "Joined"
		case .hosting: text = "Hosting"
		}
		
		return NSLocalizedString(text, comment: "A label for an ongoing online state")
	}
}

@IBDesignable class ConnectionUIView: CustomXibView, QRCodeReaderViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, ConnectionListener
{
	// OUTLETS	--------------
	
	//@IBOutlet weak var hostingSwitch: UISwitch!
	@IBOutlet weak var qrView: UIView!
	@IBOutlet weak var qrImageView: UIImageView!
	//@IBOutlet weak var joinSwitch: UISwitch!
	@IBOutlet weak var onlineStatusView: OnlineStatusView!
	@IBOutlet weak var hostInfoView: UIView!
	@IBOutlet weak var hostImageView: UIImageView!
	@IBOutlet weak var hostNameLabel: UILabel!
	@IBOutlet weak var hostProjectLabel: UILabel!
	@IBOutlet weak var sendEmailButton: BasicButton!
	@IBOutlet weak var bookSelectionView: UIView!
	@IBOutlet weak var bookSelectionTableView: UITableView!
	@IBOutlet weak var connectionSegmentedControl: UISegmentedControl!
	@IBOutlet weak var sharingView: UIView!
	
	
	// ATTRIBUTES	----------
	
	weak var viewController: UIViewController?
	
	// private let canSendMail = MFMailComposeViewController.canSendMail()
	private var targetTranslations = [Book]()
	private var joining = false
	
	// The reader used for capturing QR codes, initialized only when used
	private lazy var readerVC: QRCodeReaderViewController =
	{
		let builder = QRCodeReaderViewControllerBuilder
		{
			$0.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObject.ObjectType.qr.rawValue], captureDevicePosition: .back)
		}
		
		return QRCodeReaderViewController(builder: builder)
	}()
	
	private var canHost = false
	private var canJoin = false
	
	
	// COMPUTED PROPERTIES	----
	
	private var availableConnectionStates: [(ConnectionState, Int)]
	{
		var states = [(ConnectionState.disconnected, 0)]
		var nextIndex = 1
		
		if canJoin
		{
			states.add((ConnectionState.joined, nextIndex))
			nextIndex += 1
		}
		if canHost
		{
			states.add((ConnectionState.hosting, nextIndex))
			nextIndex += 1
		}
		
		return states
	}
	
	
	// INIT	--------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "Connect2")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "Connect2")
	}
	
	override func awakeFromNib()
	{
		bookSelectionView.isHidden = true
		
		bookSelectionTableView.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
		bookSelectionTableView.dataSource = self
		bookSelectionTableView.delegate = self
		
		var projectFound = false
		do
		{
			if let projectId = Session.instance.projectId, let project = try Project.get(projectId)
			{
				targetTranslations = try project.targetTranslationQuery().resultObjects()
				targetTranslations.sort(by: { $0.code < $1.code })
				projectFound = true
			}
		}
		catch
		{
			print("ERROR: Failed to read target translation data. \(error)")
		}
		
		canHost = projectFound || P2PHostSession.instance != nil
		canJoin = QRCodeReader.isAvailable()
		
		if !canHost
		{
			connectionSegmentedControl.removeSegment(at: 2, animated: false)
		}
		if !canJoin
		{
			connectionSegmentedControl.removeSegment(at: 1, animated: false)
		}
		
		updateStatus()
		
		sharingView.isHidden = targetTranslations.isEmpty
	}
	
	
	// ACTIONS	--------------
	
	@IBAction func connectionModeChanged(_ sender: Any)
	{
		let newState = stateForIndex(connectionSegmentedControl.selectedSegmentIndex)
		
		// Join
		if newState == .joined
		{
			guard let viewController = viewController else
			{
				print("ERROR: No view controller to host the QR scanner")
				return
			}
			
			if QRCodeReader.isAvailable()
			{
				joining = true
			
				// Presents a join P2P VC
				readerVC.delegate = self
				readerVC.modalPresentationStyle = .formSheet
				viewController.present(readerVC, animated: true, completion: nil)
			}
			else
			{
				connectionSegmentedControl.selectedSegmentIndex = 0
				// TODO: Show some kind of error label
			}
		}
		else
		{
			P2PClientSession.stop()
		}
		
		// Hosting
		if newState == .hosting
		{
			if P2PHostSession.instance == nil
			{
				do
				{
					_ = try P2PHostSession.start(projectId: Session.instance.projectId, hostAvatarId: Session.instance.avatarId)
				}
				catch
				{
					print("ERROR: Failed to start a P2P hosting session")
				}
			}
		}
		else
		{
			P2PHostSession.stop()
		}
		
		// TODO: Animate
		updateStatus()
	}
	
	/*
	@IBAction func hostingSwitchChanged(_ sender: Any)
	{
		// TODO: Animate
		if hostingSwitch.isOn
		{
			if P2PHostSession.instance == nil
			{
				do
				{
					_ = try P2PHostSession.start(projectId: Session.instance.projectId, hostAvatarId: Session.instance.avatarId)
				}
				catch
				{
					print("ERROR: Failed to start a P2P hosting session")
				}
			}
		}
		else
		{
			P2PHostSession.stop()
		}
		
		updateStatus()
	}
	
	@IBAction func joinSwitchChanged(_ sender: Any)
	{
		if joinSwitch.isOn
		{
			guard let viewController = viewController else
			{
				print("ERROR: No view controller to host the QR scanner")
				return
			}
			
			// Presents a join P2P VC
			readerVC.delegate = self
			readerVC.modalPresentationStyle = .formSheet
			viewController.present(readerVC, animated: true, completion: nil)
		}
		else
		{
			P2PClientSession.stop()
			updateStatus()
		}
	}
*/
	
	@IBAction func sendEmailButtonPressed(_ sender: Any)
	{
		// TODO: Animate
		// When send email button is pressed, book selection is displayed
		bookSelectionView.isHidden = false
		sendEmailButton.isEnabled = false
	}
	
	@IBAction func cancelSendButtonPressed(_ sender: Any)
	{
		// TODO: Animate
		// Hides the book selection
		sendEmailButton.isEnabled = true
		bookSelectionView.isHidden = true
	}
	
	
	// IMPLEMENTED METHODS	------
	
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult)
	{
		reader.stopScanning()
		print("STATUS: Scanned QR code result: \(result.value) (of type \(result.metadataType))")
		viewController.or(reader).dismiss(animated: true, completion: nil)
		
		joining = false
		
		if let info = P2PConnectionInformation.parse(from: result.value)
		{
			print("STATUS: Starting P2P client session")
			print("STATUS: \(info)")
			
			P2PClientSession.start(info)
		}
		else
		{
			print("ERROR: Failed to parse connection information from \(result.value)")
		}
		
		// TODO: Animate
		updateStatus()
	}
	
	func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput)
	{
		print("STATUS: Switched camera")
	}
	
	func readerDidCancel(_ reader: QRCodeReaderViewController)
	{
		reader.stopScanning()
		print("STATUS: QR Capture session cancelled")
		viewController.or(reader).dismiss(animated: true, completion: nil)
		
		joining = false
		// connectionSegmentedControl.selectedSegmentIndex = 0
		// joinSwitch.isOn = false
		updateStatus()
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return targetTranslations.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: LabelCell.identifier, for: indexPath) as! LabelCell
		cell.configure(text: targetTranslations[indexPath.row].code.description)
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		guard let viewController = viewController else
		{
			print("ERROR: No view controller to host the share view.")
			return
		}
		
		do
		{
			let book = targetTranslations[indexPath.row]
			let paragraphs = try ParagraphView.instance.latestParagraphQuery(bookId: book.idString).resultObjects()
			
			let usx = USXWriter().writeUSXDocument(book: book, paragraphs: paragraphs)
			
			guard let data = usx.data(using: .utf8) else
			{
				print("ERROR: Failed to generate USX data")
				return
			}
			
			sendEmailButton.isEnabled = true
			bookSelectionView.isHidden = true
			
			let dir = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first!
			let fileurl =  dir.appendingPathComponent("\(book.code.code).usx")
			
			try data.write(to: fileurl, options: Data.WritingOptions.atomic)
			
			let shareVC = UIActivityViewController(activityItems: [fileurl], applicationActivities: nil)
			shareVC.popoverPresentationController?.sourceView = sendEmailButton
			
			/*
			let mailVC = MFMailComposeViewController()
			mailVC.mailComposeDelegate = self
			mailVC.addAttachmentData(data, mimeType: "application/xml", fileName: "\(book.code.code).usx")
			mailVC.setSubject("\(book.code.name) - \(book.identifier) \(NSLocalizedString("USX Export", comment: "Part of the default export email subject"))")
			*/
			
			viewController.present(shareVC, animated: true, completion: nil)
			// viewController.present(mailVC, animated: true, completion: nil)
		}
		catch
		{
			print("ERROR: Failed to read, parse and send translation data. \(error)")
		}
	}
	
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
	{
		controller.dismiss(animated: true, completion: nil)
	}
	
	func onConnectionStatusChange(newStatus status: ConnectionStatus)
	{
		onlineStatusView.status = status
		
		// When in idle mode and client session is active, updates host info
		if (status == .done || status == .upToDate) && P2PClientSession.isConnected
		{
			updateHostInfoViewStatus()
		}
	}
	
	func onConnectionProgressUpdate(transferred: Int, of total: Int, progress: Double)
	{
		onlineStatusView.updateProgress(completed: transferred, of: total, progress: progress)
	}
	
	
	// OTHER METHODS	-----
	
	private func stateForIndex(_ index: Int) -> ConnectionState
	{
		if index <= 0
		{
			return .disconnected
		}
		else if index == 2
		{
			return .hosting
		}
		else
		{
			if canJoin
			{
				return .joined
			}
			else
			{
				return .hosting
			}
		}
	}
	
	private func selectConnectionState(_ selectedState: ConnectionState, isProcessing: Bool = false)
	{
		// Updates labels and selection
		for (state, index) in availableConnectionStates
		{
			if state == selectedState
			{
				connectionSegmentedControl.setTitle(isProcessing ? state.processingText : state.ongoingText, forSegmentAt: index)
				connectionSegmentedControl.selectedSegmentIndex = index
			}
			else
			{
				connectionSegmentedControl.setTitle(state.actionText, forSegmentAt: index)
			}
		}
	}
	
	private func updateStatus()
	{
		if let hostSession = P2PHostSession.instance
		{
			selectConnectionState(.hosting)
			
			// QR view and the QR tag are displayed when there's an active host session
			if qrView.isHidden, let qrImage = hostSession.connectionInformation?.qrCode?.image
			{
				qrImageView.image = qrImage
				qrView.isHidden = false
			}
		}
		else
		{
			qrImageView.image = nil
			qrView.isHidden = true
			
			if P2PClientSession.isConnected
			{
				selectConnectionState(.joined)
				onlineStatusView.isHidden = false
			}
			else
			{
				onlineStatusView.isHidden = true
				
				if joining
				{
					selectConnectionState(.joined, isProcessing: true)
				}
				else
				{
					selectConnectionState(.disconnected)
				}
			}
		}
		
		updateHostInfoViewStatus()
	}
	
	/*
	private func updateHostViewStatus()
	{
		if let hostSession = P2PHostSession.instance
		{
			// QR view and the QR tag are displayed when there's an active host session
			if qrView.isHidden, let qrImage = hostSession.connectionInformation?.qrCode?.image
			{
				qrImageView.image = qrImage
				qrView.isHidden = false
				hostingSwitch.isOn = true
				hostingSwitch.isEnabled = true
			}
		}
		else
		{
			qrImageView.image = nil
			qrView.isHidden = true
			hostingSwitch.isOn = false
			
			// Hosting is disabled while there is an active client session
			hostingSwitch.isEnabled = !P2PClientSession.isConnected
		}
	}
	
	private func updateJoinViewStatus()
	{
		if P2PClientSession.isConnected
		{
			joinSwitch.isOn = true
			joinSwitch.isEnabled = true
			onlineStatusView.isHidden = false
		}
		else
		{
			joinSwitch.isOn = false
			onlineStatusView.isHidden = true
			
			// Join switch is disabled while there's a host session in place. 
			// Camera is required too
			// TODO: Add camera check
			joinSwitch.isEnabled = P2PHostSession.instance == nil
		}
	}*/
	
	private func updateHostInfoViewStatus()
	{
		var infoFound = false
		
		if P2PClientSession.isConnected, let clientSession = P2PClientSession.instance
		{
			// If correct info is already displayed, doesn't bother reading data again
			if hostInfoView.isHidden
			{
				do
				{
					if let projectId = clientSession.projectId, let hostAvatarId = clientSession.hostAvatarId, let project = try Project.get(projectId), let hostAvatar = try Avatar.get(hostAvatarId), let hostInfo = try hostAvatar.info()
					{
						infoFound = true
						hostImageView.image = hostInfo.image ?? #imageLiteral(resourceName: "userIcon")
						hostNameLabel.text = "\(NSLocalizedString("Joined", comment: "Part of host info desciption. Followed by host user name.")) \(hostAvatar.name)"
						hostProjectLabel.text = "\(NSLocalizedString("on project:", comment: "Part of host info description. Followed by project name")) \(project.name)"
						
						// Makes sure the current user also has access to the project
						/*
						if let accountId = Session.instance.accountId
						{
							if !project.contributorIds.contains(accountId)
							{
								project.contributorIds.append(accountId)
								try project.push()
							}
						}
						*/
					}
				}
				catch
				{
					print("ERROR: Failed to read host data from the database. \(error)")
				}
			}
			else
			{
				infoFound = true
			}
		}
		
		hostInfoView.isHidden = !infoFound
	}
}
