//
//  MainMenuVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller handles the main menu features like connection hosting, and book selection
class MainMenuVC: UIViewController
{
	// OUTLETS	------------------
	
	@IBOutlet weak var bookTableView: UITableView!
	@IBOutlet weak var userView: TopUserView!
	@IBOutlet weak var joinButton: UIButton!
	@IBOutlet weak var disconnectButton: UIButton!
	@IBOutlet weak var hostingSwitch: UISwitch!
	@IBOutlet weak var qrImageView: UIImageView!
	@IBOutlet weak var onlineStatusView: OnlineStatusView!
	@IBOutlet weak var qrView: UIView!
	
	
	// INIT	----------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		// Some views are hidden initially
		// TODO: Curent hosting status should affect these, naturally
		disconnectButton.isEnabled = false
		qrView.isHidden = true
		
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
    }
	
	
	// ACTIONS	------------------
	
	@IBAction func joinButtonPressed(_ sender: Any)
	{
		// TODO: Presents a join P2P VC
	}
	
	@IBAction func disconnectButtonPressed(_ sender: Any)
	{
		// TODO: Disconnects from the current P2P session
	}
	
	@IBAction func hostingStatusChanged(_ sender: Any)
	{
		// TODO: When hosting, generates the appropriate QR code / hosting session
		qrView.isHidden = !hostingSwitch.isOn
	}
}
