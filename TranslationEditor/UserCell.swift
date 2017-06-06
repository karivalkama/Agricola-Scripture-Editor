//
//  UserCell.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 6.6.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell
{
	// OUTLETS	---------------------
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var createdLabel: UILabel!
	@IBOutlet weak var isAdminSwitch: UISwitch!
	@IBOutlet weak var clearPasswordButton: BasicButton!
	@IBOutlet weak var deleteButton: BasicButton!
	
	
	// ATTRIBUTES	-----------------
	
	static let identifier = "UserCell"
	
	private var setAdminAction: ((UITableViewCell, Bool) -> ())?
	private var passwordAction: ((UITableViewCell) -> ())?
	private var deleteAction: ((UITableViewCell) -> ())?
	
	
	// ACTIONS	---------------------
	
	@IBAction func adminValueChanged(_ sender: Any)
	{
		setAdminAction?(self, isAdminSwitch.isOn)
	}
	
	@IBAction func clearPasswordPressed(_ sender: Any)
	{
		passwordAction?(self)
	}
	
	@IBAction func deletePressed(_ sender: Any)
	{
		deleteAction?(self)
	}
	
	
	// OTHER METHODS	-------------
	
	func configure(name: String, created: Date, isAdmin: Bool, hasPassword: Bool, deleteEnabled: Bool, setAdminAction: @escaping (UITableViewCell, Bool) -> (), clearPasswordAction: @escaping (UITableViewCell) -> (), deleteAction: @escaping (UITableViewCell) -> ())
	{
		self.passwordAction = clearPasswordAction
		self.deleteAction = deleteAction
		self.setAdminAction = setAdminAction
		
		nameLabel.text = name
		isAdminSwitch.isOn = isAdmin
		clearPasswordButton.isEnabled = hasPassword
		deleteButton.isEnabled = deleteEnabled
		
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		
		createdLabel.text = formatter.string(from: created)
	}
}
