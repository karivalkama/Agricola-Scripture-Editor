//
//  AvatarInfoView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 22.2.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

final class AvatarView: View
{
	// TYPES	----------
	
	typealias Queried = Avatar
	typealias MyQuery = Query<AvatarView>
	
	
	// ATTRIBUTES	------
	
	static let KEY_PROJECT = "project"
	static let KEY_ACCOUNT = "account"
	static let KEY_NAME = "name"
	
	static let instance = AvatarView()
	static let keyNames = [KEY_PROJECT, KEY_ACCOUNT, KEY_NAME]
	
	let view = DATABASE.viewNamed("avatar")
	
	
	// INIT	--------------
	
	init()
	{
		view.setMapBlock(createMapBlock
		{
			avatar, emit in
			
			// Key = project id + account id + name key
			let key: [Any] = [avatar.projectId, avatar.accountId, avatar.name]
			
			emit(key, nil)
		},
		version: "1")
	}
	
	
	// OTHER METHODS	---
	
	// A query for retrieving avatar data for a certain project
	func avatarQuery(projectId: String, accountId: String? = nil) -> MyQuery
	{
		return createQuery(withKeys: AvatarView.makeKeys(from: [projectId, accountId]))
	}
}
