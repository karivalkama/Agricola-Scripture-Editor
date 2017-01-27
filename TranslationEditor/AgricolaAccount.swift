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
	static let idIndexMap = [PROPERTY_CB_USERNAME: IdIndex(1)]
	private static let userRegex = try! NSRegularExpression(pattern: "[a-z0-9_@]", options: [.caseInsensitive])
	
	let cbUserName: String
	let isShared: Bool
	let projectId: String? // The tied project id. Only for shared project accounts
	
	var displayName: String
	
	
	// COMPUTED PROPERTIES	---
	
	var idProperties: [Any] { return ["user", cbUserName] }
	var properties: [String : PropertyValue]
	{
		return ["displayname": PropertyValue(displayName), "shared": PropertyValue(isShared), "project": PropertyValue(projectId)]
	}
	
	
	// INIT	-------------------
	
	init(name: String, projectId: String? = nil)
	{
		self.displayName = name
		self.cbUserName = name.limited(toExpression: AgricolaAccount.userRegex).lowercased()
		self.isShared = projectId != nil
		self.projectId = projectId
	}
	
	private init(cbUserName: String, displayName: String, isShared: Bool, projectId: String?)
	{
		self.displayName = displayName
		self.cbUserName = cbUserName
		self.isShared = isShared
		self.projectId = projectId
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> AgricolaAccount
	{
		return AgricolaAccount(cbUserName: id[PROPERTY_CB_USERNAME].string(), displayName: properties["displayname"].string(), isShared: properties["shared"].bool(), projectId: properties["project"].string)
	}
	
	
	// IMPLEMENTED METHODS	-----
	
	func update(with properties: PropertySet)
	{
		if let displayName = properties["displayname"].string
		{
			self.displayName = displayName
		}
	}
}
