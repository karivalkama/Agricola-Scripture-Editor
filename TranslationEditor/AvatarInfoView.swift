//
//  AvatarInfoView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 22.2.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class AvatarInfoView: View
{
	// TYPES	----------
	
	typealias Queried = AvatarInfo
	typealias MyQuery = Query<AvatarInfoView>
	
	
	// ATTRIBUTES	------
	
	static let KEY_PROJECT = "project"
	static let KEY_ACCOUNT = "account"
	static let KEY_NAME = "name"
	
	static let instance = AvatarInfoView()
	static let keyNames = [KEY_PROJECT, KEY_ACCOUNT, KEY_NAME]
	
	let view = DATABASE.viewNamed("avatar_info")
	
	
	// INIT	--------------
	
	init()
	{
		view.setMapBlock(createMapBlock
		{
			info, emit in
			
			// Key = project id + account id + name key
			let key: [Any] = [info.projectId, info.accountId, info.nameKey]
			
			emit(key, nil)
		},
		version: "1")
	}
	
	
	// OTHER METHODS	---
	
	// A query for retrieving avatar data for a certain project
	func avatarQuery(projectId: String, accountId: String? = nil) -> MyQuery
	{
		let keys = [
			AvatarInfoView.KEY_PROJECT: Key(projectId),
			AvatarInfoView.KEY_ACCOUNT: Key(accountId),
			AvatarInfoView.KEY_NAME: Key.undefined
		]
		
		return createQuery(withKeys: keys)
	}
}
