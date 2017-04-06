//
//  User.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 25.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation
import SCrypto

final class AgricolaAccount: Storable
{
	// ATTRIBUTES	-----------
	
	static let PROPERTY_CB_USERNAME = "cbusername"
	
	static let type = "user"
	static let idIndexMap: IdIndexMap = ["user_separator", PROPERTY_CB_USERNAME]
	
	let cbUserName: String
	let isShared: Bool
	
	var displayName: String
	var languageIds: [String]
	
	private var passwordHash: String
	
	
	// COMPUTED PROPERTIES	---
	
	var idProperties: [Any] { return ["user", cbUserName] }
	var properties: [String : PropertyValue]
	{
		return ["displayname": displayName.value, "shared": isShared.value, "languages": languageIds.value, "password": passwordHash.value]
	}
	
	
	// INIT	-------------------
	
	convenience init(name: String, languageIds: [String], isShared: Bool, password: String)
	{
		self.init(cbUserName: name.toKey, displayName: name, languageIds: languageIds, isShared: isShared, passwordHash: AgricolaAccount.createPasswordHash(name: name.toKey, password: password))
	}
	
	private init(cbUserName: String, displayName: String, languageIds: [String], isShared: Bool, passwordHash: String)
	{
		self.languageIds = languageIds
		self.displayName = displayName
		self.cbUserName = cbUserName
		self.isShared = isShared
		self.passwordHash = passwordHash
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> AgricolaAccount
	{
		return AgricolaAccount(cbUserName: id[PROPERTY_CB_USERNAME].string(), displayName: properties["displayname"].string(), languageIds: properties["languages"].array { $0.string }, isShared: properties["shared"].bool(), passwordHash: properties["password"].string())
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
	
	
	// OTHER METHODS	--------
	
	// Tries to authorize the user using a specific password
	func authorize(password: String) -> Bool
	{
		return AgricolaAccount.createPasswordHash(name: cbUserName, password: password) == passwordHash
	}
	
	private static func createPasswordHash(name: String, password: String) -> String
	{
		return (name + password).SHA256()
	}
}
