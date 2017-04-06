//
//  Avatar.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation
import SCrypto

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
	
	static var idIndexMap: IdIndexMap
	{
		return Project.idIndexMap.makeChildPath(parentPathName: PROPERTY_PROJECT, childPath: ["avatar_separator", "avatar_name_key"])
	}
	
	var idProperties: [Any] { return [projectId, "avatar", name.toKey] }
	var properties: [String : PropertyValue]
	{
		return ["name": name.value, "created": created.value]
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
	
	
	// OTHER METHODS	---------
	
	// The private infor for this avatar instance
	func privateInfo() throws -> AvatarInfo?
	{
		return try AvatarInfo.get(avatarId: idString)
	}
	
	static func project(fromId avatarId: String) -> String
	{
		return property(withName: PROPERTY_PROJECT, fromId: avatarId).string()
	}
	
	// Creates a new avatar id based on the provided properties
	static func createId(projectId: String, avatarName: String) -> String
	{
		return parseId(from: [projectId, "avatar", avatarName.toKey])
	}
	
	// Retrieves avatar data from the database
	static func get(projectId: String, avatarName: String) throws -> Avatar?
	{
		return try get(createId(projectId: projectId, avatarName: avatarName))
	}
	
	fileprivate static func nameKey(ofId avatarId: String) -> String
	{
		return property(withName: "avatar_name_key", fromId: avatarId).string()
	}
}

// This class contains avatar info that is only visible in the project scope
final class AvatarInfo: Storable
{
	// ATTRIBUTES	-------------
	
	static let PROPERTY_AVATAR = "avatar"
	
	static let type = "avatar_info"
	
	let avatarId: String
	
	var accountId: String
	var openName: String?
	var isShared: Bool
	
	// Phase id -> Carousel id
	var carouselIds: [String : String]
	
	private var passwordHash: String?
	
	private var _image: UIImage?
	var image: UIImage?
	{
		// Reads the image from CB if necessary
		if let image = _image
		{
			return image
		}
		else
		{
			if let image = attachment(named: "image")?.toImage
			{
				_image = image
				return image
			}
			else
			{
				return nil
			}
		}
	}
	
	
	// COMPUTED PROPERTIES	----
	
	static var idIndexMap: IdIndexMap
	{
		return Avatar.idIndexMap.makeChildPath(parentPathName: PROPERTY_AVATAR, childPath: ["private_separator"])
	}
	
	var idProperties: [Any] { return [avatarId, "private"] }
	var properties: [String : PropertyValue]
	{
		return ["open_name": openName.value, "account": accountId.value, "offline_password": passwordHash.value, "shared": isShared.value, "carousels": PropertySet(carouselIds).value]
	}
	
	var projectId: String { return Avatar.project(fromId: avatarId) }
	
	// The key version of the avatar's name
	var nameKey: String { return Avatar.nameKey(ofId: avatarId) }
	
	// Whether the info requires a password for authentication
	var requiresPassword: Bool { return passwordHash != nil }
	
	
	// INIT	--------------------
	
	init(avatarId: String, accountId: String, openName: String? = nil, password: String? = nil, isShared: Bool = false, carousels: [String : String] = [:])
	{
		self.avatarId = avatarId
		self.accountId = accountId
		self.openName = openName
		self.carouselIds = carousels
		self.isShared = isShared
		
		if let password = password
		{
			// Uses the avatar id as salt
			self.passwordHash = createPasswordHash(password: password)
		}
	}
	
	private init(avatarId: String, accountId: String, openName: String?, passwordHash: String?, isShared: Bool, carousels: [String : String])
	{
		self.avatarId = avatarId
		self.accountId = accountId
		self.openName = openName
		self.passwordHash = passwordHash
		self.isShared = isShared
		self.carouselIds = carousels
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> AvatarInfo
	{
		return AvatarInfo(avatarId: id[PROPERTY_AVATAR].string(), accountId: properties["account"].string(), openName: properties["open_name"].string, passwordHash: properties["offline_password"].string, isShared: properties["shared"].bool(), carousels: properties["carousels"].object { $0.string })
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func update(with properties: PropertySet)
	{
		if let accountId = properties["account"].string
		{
			self.accountId = accountId
		}
		if let openName = properties["open_name"].string
		{
			self.openName = openName
		}
		if let isShared = properties["shared"].bool
		{
			self.isShared = isShared
		}
		if let carouselData = properties["carousels"].object
		{
			self.carouselIds = carouselData.properties.flatMapValues { $0.string }
		}
		if let passwordHash = properties["offline_password"].string
		{
			self.passwordHash = passwordHash
		}
	}
	
	
	// OTHER METHODS	-------
	
	// Changes the image associated with this avatar
	func setImage(_ image: UIImage) throws
	{
		if (_image != image)
		{
			_image = image
			if let attachment = Attachment.parse(fromImage: image)
			{
				try saveAttachment(attachment, withName: "image")
			}
		}
	}
	
	// Updates the avatar's password
	func setPassword(_ password: String)
	{
		passwordHash = createPasswordHash(password: password)
	}
	
	func authenticate(loggedAccountId: String?, password: String) -> Bool
	{
		// If the avatar doesn't have a specified password, correct account login is enough
		if passwordHash == nil
		{
			return self.accountId == loggedAccountId
		}
		else
		{
			return createPasswordHash(password: password) == passwordHash
		}
	}
	
	// The name that should be displayed for this avatar in-project
	func displayName() throws -> String
	{
		if let openName = openName
		{
			return openName
		}
		else if let avatar = try Avatar.get(avatarId)
		{
			return avatar.name
		}
		else
		{
			return nameKey
		}
	}
	
	private func createPasswordHash(password: String) -> String
	{
		return (avatarId + password).SHA256()
	}
	
	static func get(avatarId: String) throws -> AvatarInfo?
	{
		return try get(parseId(from: [avatarId, "private"]))
	}
	
	// The avatar id portion of the avatar info id string
	static func avatarId(fromAvatarInfoId infoId: String) -> String
	{
		return property(withName: PROPERTY_AVATAR, fromId: infoId).string()
	}
}
