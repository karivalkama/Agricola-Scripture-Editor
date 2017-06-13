//
//  Session.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 1.3.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Session keeps track of user choices within and between sessions
class Session
{
	// ATTRIBUTES	---------------
	
	static let instance = Session()
	
	private static let KEY_ACCOUNT = "agricola_account"
	private static let KEY_USERNAME = "agricola_username"
	private static let KEY_PASSWORD = "agricola_password"
	private static let KEY_PROJECT = "agricola_project"
	private static let KEY_AVATAR = "agricola_avatar"
	private static let KEY_BOOK = "agricola_book"
	
	private var keyChain = KeychainSwift()
	
	
	// COMPUTED PROPERTIES	-------
	
	var projectId: String?
	{
		get { return self[Session.KEY_PROJECT] }
		set { self[Session.KEY_PROJECT] = newValue }
	}
	
	var avatarId: String?
	{
		get { return self[Session.KEY_AVATAR] }
		set { self[Session.KEY_AVATAR] = newValue }
	}
	
	var bookId: String?
	{
		get { return self[Session.KEY_BOOK] }
		set { self[Session.KEY_BOOK] = newValue }
	}
	
	var accountId: String?
	{
		get { return self[Session.KEY_ACCOUNT] }
		set { self[Session.KEY_ACCOUNT] = newValue }
	}
	
	private(set) var userName: String?
	{
		get { return self[Session.KEY_USERNAME] }
		set { self[Session.KEY_USERNAME] = newValue }
	}
	
	private(set) var password: String?
	{
		get { return self[Session.KEY_PASSWORD] }
		set { self[Session.KEY_PASSWORD] = newValue }
	}
	
	// Whether the current session is authorized (logged in)
	var isAuthorized: Bool { return userName != nil && password != nil && accountId != nil}
	
	
	// INIT	-----------------------
	
	private init()
	{
		// Instance accessed statically
	}
	
	
	// SUBSCRIPT	---------------
	
	private subscript(key: String) -> String?
	{
		get { return keyChain.get(key) }
		set
		{
			print("STATUS: Session changed: \(key) = \(newValue.or("empty"))")
			if let newValue = newValue
			{
				keyChain.set(newValue, forKey: key)
			}
			else
			{
				keyChain.delete(key)
			}
		}
	}
	
	
	// OTHER METHODS	-----------
	
	// Notice that this is the couchbase username, not the one typed by the user
	func logIn(accountId: String, userName: String, password: String)
	{
		self.accountId = accountId
		self.userName = userName
		self.password = password
	}
	
	func logout()
	{
		self.password = nil
		self.userName = nil
		self.accountId = nil
	}
}
