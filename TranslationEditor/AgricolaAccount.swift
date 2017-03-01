//
//  User.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 25.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class AgricolaAccount: Storable
{
	// ATTRIBUTES	-----------
	
	static let PROPERTY_CB_USERNAME = "cbusername"
	
	static let type = "user"
	static let idIndexMap: IdIndexMap = ["user_separator", PROPERTY_CB_USERNAME]
	
	let cbUserName: String
	let isShared: Bool
	
	var projectId: String? // The tied project id. Only for shared project accounts
	var displayName: String
	var languageIds: [String]
	
	
	// COMPUTED PROPERTIES	---
	
	var idProperties: [Any] { return ["user", cbUserName] }
	var properties: [String : PropertyValue]
	{
		return ["displayname": displayName.value, "shared": isShared.value, "project": projectId.value, "languages": languageIds.value]
	}
	
	
	// INIT	-------------------
	
	convenience init(name: String, languageIds: [String], isShared: Bool)
	{
		self.init(cbUserName: name.toKey, displayName: name, languageIds: languageIds, isShared: isShared, projectId: nil)
	}
	
	private init(cbUserName: String, displayName: String, languageIds: [String], isShared: Bool, projectId: String?)
	{
		self.languageIds = languageIds
		self.displayName = displayName
		self.cbUserName = cbUserName
		self.isShared = isShared
		self.projectId = projectId
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> AgricolaAccount
	{
		return AgricolaAccount(cbUserName: id[PROPERTY_CB_USERNAME].string(), displayName: properties["displayname"].string(), languageIds: properties["languages"].array { $0.string }, isShared: properties["shared"].bool(), projectId: properties["project"].string)
	}
	
	
	// IMPLEMENTED METHODS	-----
	
	func update(with properties: PropertySet)
	{
		if let displayName = properties["displayname"].string
		{
			self.displayName = displayName
		}
		if let languageData = properties["language"].array
		{
			languageIds = languageData.flatMap { $0.string }
		}
	}
}
