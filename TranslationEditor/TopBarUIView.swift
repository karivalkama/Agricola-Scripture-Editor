//
//  TopBarUIView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 19.5.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view is used for basic navigation and info display on multiple different views
// The bar also provides access to P2P and other sharing options
@IBDesignable class TopBarUIView: CustomXibView
{
	// OUTLETS	------------------
	
	@IBOutlet weak var leftSideButton: UIButton!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var userView: TopUserView!
	
	
	// ATTRIBUTES	--------------
	
	// This will be called each time connection view is closed
	var connectionCompletionHandler: (() -> ())?
	
	private weak var viewController: UIViewController?
	private var leftSideAction: (() -> ())?
	
	private var avatar: Avatar?
	private var info: AvatarInfo?
	
	
	// LOAD	----------------------
	
	override init(frame: CGRect)
	{
		super.init(frame: frame)
		setupXib(nibName: "TopBar")
	}
	
	required init?(coder: NSCoder)
	{
		super.init(coder: coder)
		setupXib(nibName: "TopBar")
	}
	
	
	// ACTIONS	------------------
	
	@IBAction func leftSideButtonPressed(_ sender: Any)
	{
		leftSideAction?()
	}
	
	@IBAction func connectButtonPressed(_ sender: Any)
	{
		guard let viewController = viewController else
		{
			print("ERROR: Cannot display connect VC without a view controller")
			return
		}
		
		if let completionHandler = connectionCompletionHandler
		{
			viewController.displayAlert(withIdentifier: ConnectionVC.identifier, storyBoardId: "Common")
			{
				($0 as! ConnectionVC).configure(completion: completionHandler)
			}
		}
		else
		{
			viewController.displayAlert(withIdentifier: ConnectionVC.identifier, storyBoardId: "Common")
		}
	}
	
	@IBAction func userViewTapped(_ sender: Any)
	{
		guard let viewController = viewController else
		{
			print("ERROR: Cannot display user view without a view controller")
			return
		}
		
		guard let avatar = avatar, let info = info else
		{
			print("ERROR: No user data to edit")
			return
		}
		
		viewController.displayAlert(withIdentifier: EditAvatarVC.identifier, storyBoardId: "MainMenu")
		{
			($0 as! EditAvatarVC).configureForEdit(avatar: avatar, avatarInfo: info) { _, _ in self.updateUserView() }
		}
	}
	
	
	// OTHER METHODS	--------------
	
	func configure(hostVC: UIViewController, title: String, leftButtonText: String? = nil, leftButtonAction: (() -> ())? = nil)
	{
		viewController = hostVC
		titleLabel.text = title
		
		if let leftButtonText = leftButtonText
		{
			leftSideButton.setTitle(leftButtonText, for: .normal)
			leftSideButton.isHidden = false
			
			self.leftSideAction = leftButtonAction
			leftSideButton.isEnabled = leftButtonAction != nil
		}
		else
		{
			leftSideButton.isHidden = true
		}
		
		updateUserView()
	}
	
	func setLeftButtonAction(_ action: @escaping () -> ())
	{
		leftSideAction = action
		leftSideButton.isEnabled = true
	}
	
	func updateUserView()
	{
		var foundUserData = false
		
		// Sets up the user view
		if let projectId = Session.instance.projectId, let avatarId = Session.instance.avatarId
		{
			do
			{
				if let project = try Project.get(projectId), let avatar = try Avatar.get(avatarId), let info = try avatar.info()
				{
					self.avatar = avatar
					self.info = info
					userView.configure(projectName: project.name, username: avatar.name, image: info.image ?? #imageLiteral(resourceName: "userIcon"))
					foundUserData = true
				}
			}
			catch
			{
				print("ERROR: Failed to load user information for the top bar. \(error)")
			}
		}
		
		userView.isHidden = !foundUserData
	}
}
