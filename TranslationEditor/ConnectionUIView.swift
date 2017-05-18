//
//  ConnectionUIView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 17.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

class ConnectionUIView: UIView
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
	
	
	// ACTIONS	--------------
	
	@IBAction func hostingSwitchChanged(_ sender: Any)
	{
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
		
		updateHostViewStatus()
		updateJoinViewStatus()
		updateHostInfoViewStatus()
	}
	
	@IBAction func joinSwitchChanged(_ sender: Any)
	{
		
	}
	
	@IBAction func sendEmailButtonPressed(_ sender: Any)
	{
		
	}
	
	@IBAction func closeButtonPressed(_ sender: Any)
	{
		
	}
	
	@IBAction func cancelSendButtonPressed(_ sender: Any)
	{
		
	}
	
	
	// OTHER METHODS	-----
	
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
			do
			{
				if let projectId = clientSession.projectId, let hostAvatarId = clientSession.hostAvatarId, let project = try Project.get(projectId), let hostAvatar = try Avatar.get(hostAvatarId), let hostInfo = try hostAvatar.info()
				{
					infoFound = true
					hostImageView.image = hostInfo.image ?? #imageLiteral(resourceName: "userIcon")
					hostNameLabel.text = "Joined \(hostAvatar.name)"
					hostProjectLabel.text = "on project: \(project.name)"
				}
			}
			catch
			{
				print("ERROR: Failed to read host data from the database. \(error)")
			}
		}
		
		hostInfoView.isHidden = !infoFound
	}
}
