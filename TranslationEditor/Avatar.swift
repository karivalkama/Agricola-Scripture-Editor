//
//  Avatar.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Avatars are project-specific user accounts
final class Avatar: Storable
{
	// ATTRIBUTES	-------------
	
	static let PROPERTY_PROJECT = "project"
	
	static let type = "avatar"
	
	let projectId: String
	let name: String
	let created: TimeInterval
	
	
	// COMPUTED PROPERTIES	-----
	
	static var idIndexMap: [String : IdIndex]
	{
		let projectMap = Project.idIndexMap
		let projectIndex = IdIndex.of(indexMap: projectMap)
		
		return projectMap + [PROPERTY_PROJECT: projectIndex, "avatar_name_key": projectIndex + 2]
	}
	
	var idProperties: [Any] { return [projectId, "avatar", name.toKey] }
	var properties: [String : PropertyValue]
	{
		return ["name": PropertyValue(name), "created": PropertyValue(created)]
	}
	
	
	// INIT	---------------------
	
	init(name: String, projectId: String, created: TimeInterval = Date().timeIntervalSince1970)
	{
		self.projectId = projectId
		self.name = name
		self.created = created
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> Avatar
	{
		return Avatar(name: properties["name"].string(), projectId: id[PROPERTY_PROJECT].string(), created: properties["created"].time())
	}
	
	
	// IMPLEMENTED METHODS	-----
	
	func update(with properties: PropertySet)
	{
		// No mutable fields
	}
}

// This class contains avatar info that is only visible in the project scope
final class AvatarInfo
{
	// ATTRIBUTES	-------------
	
	static let type = "avatar_info"
	
	let avatarId: String
	
	var accountId: String
	var openName: String?
	var password: String?
	
	// Phase id -> Carousel id
	var carousels: [String : String]
	
	
	// INIT	--------------------
	
	init(avatarId: String, accountId: String, openName: String? = nil, password: String? = nil, carousels: [String : String] = [:])
	{
		self.avatarId = avatarId
		self.accountId = accountId
		self.openName = openName
		self.password = password
		self.carousels = carousels
	}
}