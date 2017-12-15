//
//  P2PJoinView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.4.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit
import AVFoundation
import QRCodeReader

// This view displays option to join P2P connection with other users
@available(*, deprecated)
@IBDesignable class P2PJoinView: CustomXibView, QRCodeReaderViewControllerDelegate, ConnectionListener
{
	// OUTLETS	----------------
	
	@IBOutlet weak var joinButton: UIButton!
	@IBOutlet weak var disconnectButton: UIButton!
	
	
	// ATTRIBUTES	------------
	
	weak var viewController: UIViewController?
	
	// This method is called whenever the connection is established or remomved using this interace
	var connectionUpdated: (() -> ())?
	
	private weak var _onlineStatusView: OnlineStatusView?
	var onlineStatusView: OnlineStatusView?
	{
		get { return _onlineStatusView }
		set
		{
			_onlineStatusView = newValue
			_onlineStatusView?.isHidden = !P2PClientSession.isConnected
		}
	}
	
	// The reader used for capturing QR codes, initialized only when used
	private lazy var readerVC: QRCodeReaderViewController =
	{
		let builder = QRCodeReaderViewControllerBuilder
		{
			$0.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObject.ObjectType.qr], captureDevicePosition: .back)
		}
		
		return QRCodeReaderViewController(builder: builder)
	}()
	
	
	// INIT	--------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "P2PJoinView")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "P2PJoinView")
	}
	
	
	// ACTIONS	----------------
	
	@IBAction func joinButtonPressed(_ sender: Any)
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
	
	@IBAction func disconnectButtonPressed(_ sender: Any)
	{
		// Disconnects from the current P2P session
		P2PClientSession.stop()
		updateAppearance()
		connectionUpdated?()
	}
	
	
	// IMPLEMENTED METHODS	-----
	
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult)
	{
		// TODO: Parse result and start P2P session
		reader.stopScanning()
		print("STATUS: Scanned QR code result: \(result.value) (of type \(result.metadataType))")
		viewController.or(reader).dismiss(animated: true, completion: nil)
		
		if let info = P2PConnectionInformation.parse(from: result.value)
		{
			print("STATUS: Starting P2P client session")
			print("STATUS: \(info)")
			
			P2PClientSession.start(info)
			updateAppearance()
			connectionUpdated?()
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
	}
	
	func onConnectionStatusChange(newStatus status: ConnectionStatus)
	{
		onlineStatusView?.status = status
	}
	
	func onConnectionProgressUpdate(transferred: Int, of total: Int, progress: Double)
	{
		onlineStatusView?.updateProgress(completed: transferred, of: total, progress: progress)
	}

	
	
	// OTHER METHODS	---------
	
	func updateAppearance()
	{
		let isConnected = P2PClientSession.isConnected
		joinButton.isEnabled = !isConnected && QRCodeReader.isAvailable()
		disconnectButton.isEnabled = isConnected
		onlineStatusView?.isHidden = !isConnected
	}
}
