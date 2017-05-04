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
	
	static let type = "user"
	static let idIndexMap: IdIndexMap = ["user_uid"]
	
	let uid: String
	let isShared: Bool
	
	var username: String
	// var languageIds: [String]
	
	private var passwordHash: String
	
	
	// COMPUTED PROPERTIES	---
	
	var idProperties: [Any] { return [uid] }
	var properties: [String : PropertyValue]
	{
		return ["username": username.value, "shared": isShared.value, "password": passwordHash.value]
	}
	
	
	// INIT	-------------------
	
	convenience init(name: String, isShared: Bool, password: String)
	{
		self.init(username: name, isShared: isShared, passwordHash: AgricolaAccount.createPasswordHash(name: name.toKey, password: password))
	}
	
	private init(username: String, isShared: Bool, passwordHash: String, uid: String = UUID().uuidString.lowercased())
	{
		self.username = username
		self.isShared = isShared
		self.passwordHash = passwordHash
		self.uid = uid
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> AgricolaAccount
	{
		return AgricolaAccount(username: properties["username"].string(), isShared: properties["shared"].bool(), passwordHash: properties["password"].string(), uid: id["user_uid"].string())
	}
	
	
	// IMPLEMENTED METHODS	-----
	
	func update(with properties: PropertySet)
	{
		if let username = properties["username"].string
		{
			self.username = username
		}
		if let passwordHash = properties["password"].string
		{
			self.passwordHash = passwordHash
		}
	}
	
	
	// OTHER METHODS	--------
	
	// Tries to authorize the user using a specific password
	func authorize(password: String) -> Bool
	{
		return AgricolaAccount.createPasswordHash(name: username, password: password) == passwordHash
	}
	
	// Changes the password of the account
	func setPassword(password: String)
	{
		passwordHash = AgricolaAccount.createPasswordHash(name: username, password: password)
	}
	
	private static func createPasswordHash(name: String, password: String) -> String
	{
		return (name + password).SHA256()
	}
}
