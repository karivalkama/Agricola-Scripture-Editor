//
//  ManageUsersVC.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

// This view controller is used for managing, which users / avatars are available in the project and which are considered admins
class ManageUsersVC: UIViewController, UITableViewDataSource
{
	// OUTLETS	----------------------
	
	@IBOutlet weak var userTableView: UITableView!
	@IBOutlet weak var confirmView: UIView!
	
	
	// ATTRIBUTES	------------------
	
	static let identifier = "ManageUsersVC"
	
	private var avatars = [(avatar: Avatar, info: AvatarInfo)]()
	private weak var deleteTargetCell: UITableViewCell?
	
	
	// LOAD	--------------------------
	
    override func viewDidLoad()
	{
        super.viewDidLoad()

		userTableView.dataSource = self
    }
	
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		guard let projectId = Session.instance.projectId, let avatarId = Session.instance.avatarId else
		{
			print("ERROR: Project and avatar must be selected before managing users")
			return
		}
		
		// Loads avatar data
		do
		{
			avatars = try AvatarView.instance.avatarQuery(projectId: projectId).resultObjects().filter { $0.idString != avatarId }.flatMap { avatar in avatar.isDisabled ? nil : try avatar.info().map { (avatar, $0) } }
		}
		catch
		{
			print("ERROR: Failed to read avatar data. \(error)")
		}
	}
	
	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		
		avatars = []
	}
	
	
	// ACTIONS	---------------------
	
	@IBAction func noButtonPressed(_ sender: Any)
	{
		hideConfirm()
	}
	
	@IBAction func yesButtonPressed(_ sender: Any)
	{
		if let deleteTargetCell = deleteTargetCell, let index = userTableView.indexPath(for: deleteTargetCell)?.row
		{
			do
			{
				let avatar = avatars[index].avatar
				avatar.isDisabled = true
				try avatar.push()
				
				// If the avatar is tied to a private account, removes access to the project
				if let account = try AgricolaAccount.get(avatar.accountId), !account.isShared
				{
					if let projectId = Session.instance.projectId, let project = try Project.get(projectId), project.contributorIds.contains(account.idString)
					{
						project.contributorIds = project.contributorIds - account.idString
						try project.push()
					}
				}
				
				avatars.remove(at: index)
				userTableView.reloadData()
			}
			catch
			{
				print("ERROR: Failed to disable the user")
			}
		}
		
		hideConfirm()
	}
	
	@IBAction func closeButtonPressed(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func backgroundTapped(_ sender: Any)
	{
		dismiss(animated: true, completion: nil)
	}
	
	
	// IMPLEMENTED METHODS	---------
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return avatars.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.identifier, for: indexPath) as! UserCell
		
		let (avatar, info) = avatars[indexPath.row]
		cell.configure(name: avatar.name, created: Date(timeIntervalSince1970: avatar.created), isAdmin: avatar.isAdmin, hasPassword: info.requiresPassword, deleteEnabled: cell != deleteTargetCell, setAdminAction: isAdminChanged(at:newState:), clearPasswordAction: clearPasswordPressed(at:), deleteAction: deletePressed(at:))
		
		return cell
	}
	
	
	// OTHER METHODS	-------------
	
	private func isAdminChanged(at cell: UITableViewCell, newState: Bool)
	{
		hideConfirm()
		
		guard let indexPath = userTableView.indexPath(for: cell) else
		{
			(cell as? UserCell)?.isAdminSwitch.isOn = !newState
			return
		}
		
		do
		{
			let avatar = avatars[indexPath.row].avatar
			avatar.isAdmin = newState
			try avatar.push()
			
			print("STATUS: changed admin status to \(newState)")
			userTableView.reloadRows(at: [indexPath], with: .automatic)
		}
		catch
		{
			print("ERROR: Failed to change avatar admin status. \(error)")
		}
	}
	
	private func clearPasswordPressed(at cell: UITableViewCell)
	{
		hideConfirm()
		
		guard let indexPath = userTableView.indexPath(for: cell) else
		{
			return
		}
		
		do
		{
			let info = avatars[indexPath.row].info
			info.resetPassword()
			try info.push()
			
			userTableView.reloadRows(at: [indexPath], with: .automatic)
		}
		catch
		{
			print("ERROR: Failed to reset password. \(error)")
		}
	}
	
	private func deletePressed(at cell: UITableViewCell)
	{
		deleteTargetCell = cell
		(cell as? UserCell)?.deleteButton.isEnabled = false
		confirmView.isHidden = false
	}
	
	private func hideConfirm()
	{
		if let deleteTargetCell = deleteTargetCell
		{
			(deleteTargetCell as? UserCell)?.deleteButton.isEnabled = true
			confirmView.isHidden = true
			self.deleteTargetCell = nil
		}
	}
}
