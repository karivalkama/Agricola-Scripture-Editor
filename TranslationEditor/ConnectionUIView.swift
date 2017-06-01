//
//  ConnectionUIView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation
import AVFoundation
import QRCodeReader
import MessageUI

@IBDesignable class ConnectionUIView: CustomXibView, QRCodeReaderViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, ConnectionListener
{
	// OUTLETS	--------------
	
	@IBOutlet weak var hostingSwitch: UISwitch!
	@IBOutlet weak var qrView: UIView!
	@IBOutlet weak var qrImageView: UIImageView!
	@IBOutlet weak var joinSwitch: UISwitch!
	@IBOutlet weak var onlineStatusView: OnlineStatusView!
	@IBOutlet weak var hostInfoView: UIView!
	@IBOutlet weak var hostImageView: UIImageView!
	@IBOutlet weak var hostNameLabel: UILabel!
	@IBOutlet weak var hostProjectLabel: UILabel!
	@IBOutlet weak var sendEmailButton: BasicButton!
	@IBOutlet weak var bookSelectionView: UIView!
	@IBOutlet weak var bookSelectionTableView: UITableView!
	
	
	// ATTRIBUTES	----------
	
	weak var viewController: UIViewController?
	
	private let canSendMail = MFMailComposeViewController.canSendMail()
	private var targetTranslations = [Book]()
	
	// The reader used for capturing QR codes, initialized only when used
	private lazy var readerVC: QRCodeReaderViewController =
	{
		let builder = QRCodeReaderViewControllerBuilder
		{
			$0.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode], captureDevicePosition: .back)
		}
		
		return QRCodeReaderViewController(builder: builder)
	}()
	
	
	// INIT	--------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "Connect")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "Connect")
	}
	
	override func awakeFromNib()
	{
		bookSelectionTableView.register(UINib(nibName: "LabelCell", bundle: nil), forCellReuseIdentifier: LabelCell.identifier)
		bookSelectionTableView.dataSource = self
		bookSelectionTableView.delegate = self
		
		do
		{
			if let projectId = Session.instance.projectId, let project = try Project.get(projectId)
			{
				targetTranslations = try project.targetTranslationQuery().resultObjects()
			}
		}
		catch
		{
			print("ERROR: Failed to read target translation data. \(error)")
		}
		
		updateStatus()
		
		sendEmailButton.isEnabled = canSendMail && !targetTranslations.isEmpty
	}
	
	
	// ACTIONS	--------------
	
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
		
		if let info = P2PConnectionInformation.parse(from: result.value)
		{
			print("STATUS: Starting P2P client session")
			print("STATUS: \(info)")
			
			// TODO: Animate
			P2PClientSession.start(info)
			updateStatus()
		}
		else
		{
			print("ERROR: Failed to parse connection information from \(result.value)")
		}
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
		
		joinSwitch.isOn = false
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
			print("ERROR: No view controller to host the mail view.")
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
			
			let mailVC = MFMailComposeViewController()
			mailVC.mailComposeDelegate = self
			mailVC.addAttachmentData(data, mimeType: "application/xml", fileName: "\(book.code.code).usx")
			mailVC.setSubject("\(book.code.name) - \(book.identifier) \(NSLocalizedString("USX Export", comment: "Part of the default export email subject"))")
			
			sendEmailButton.isEnabled = true
			bookSelectionView.isHidden = true
			
			viewController.present(mailVC, animated: true, completion: nil)
		}
		catch
		{
			print("ERROR: Failed to read translation data. \(error)")
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
	
	private func updateStatus()
	{
		updateHostViewStatus()
		updateJoinViewStatus()
		updateHostInfoViewStatus()
	}
	
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
	}
	
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
