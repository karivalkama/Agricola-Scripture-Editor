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
	let created: TimeInterval
	let uid: String
	let accountId: String
	
	var name: String
	var isAdmin: Bool
	var isDisabled: Bool
	
	
	// COMPUTED PROPERTIES	-----
	
	static var idIndexMap: IdIndexMap
	{
		return Project.idIndexMap.makeChildPath(parentPathName: PROPERTY_PROJECT, childPath: ["avatar_separator", "avatar_uid"])
	}
	
	var idProperties: [Any] { return [projectId, "avatar", uid] }
	var properties: [String : PropertyValue]
	{
		return ["name": name.value, "account": accountId.value, "created": created.value, "admin": isAdmin.value, "disabled": isDisabled.value]
	}
	
	
	// INIT	---------------------
	
	init(name: String, projectId: String, accountId: String, isAdmin: Bool = false, isDisabled: Bool = false, uid: String = UUID().uuidString.lowercased(), created: TimeInterval = Date().timeIntervalSince1970)
	{
		self.isAdmin = isAdmin
		self.isDisabled = isDisabled
		self.projectId = projectId
		self.name = name
		self.created = created
		self.uid = uid
		self.accountId = accountId
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> Avatar
	{
		return Avatar(name: properties["name"].string(), projectId: id[PROPERTY_PROJECT].string(), accountId: properties["account"].string(), isAdmin: properties["admin"].bool(), isDisabled: properties["disabled"].bool(), uid: id["avatar_uid"].string(), created: properties["created"].time())
	}
	
	
	// IMPLEMENTED METHODS	-----
	
	func update(with properties: PropertySet)
	{
		if let name = properties["name"].string
		{
			self.name = name
		}
		if let isAdmin = properties["admin"].bool
		{
			self.isAdmin = isAdmin
		}
		if let isDisabled = properties["disabled"].bool
		{
			self.isDisabled = isDisabled
		}
	}
	
	
	// OTHER METHODS	---------
	
	// The private infor for this avatar instance
	func info() throws -> AvatarInfo?
	{
		return try AvatarInfo.get(avatarId: idString)
	}
	
	static func project(fromId avatarId: String) -> String
	{
		return property(withName: PROPERTY_PROJECT, fromId: avatarId).string()
	}
	
	// Creates a new avatar id based on the provided properties
	/*
	static func createId(projectId: String, avatarName: String) -> String
	{
		return parseId(from: [projectId, "avatar", avatarName.toKey])
	}*/
	
	// Retrieves avatar data from the database
	/*
	static func get(projectId: String, avatarName: String) throws -> Avatar?
	{
		return try get(createId(projectId: projectId, avatarName: avatarName))
	}*/
	/*
	fileprivate static func nameKey(ofId avatarId: String) -> String
	{
		return property(withName: "avatar_name_key", fromId: avatarId).string()
	}*/
}

// This class contains avatar info that is only visible in the project scope
final class AvatarInfo: Storable
{
	// ATTRIBUTES	-------------
	
	static let PROPERTY_AVATAR = "avatar"
	
	static let type = "avatar_info"
	
	let avatarId: String
	
	var isShared: Bool
	
	// Phase id -> Carousel id
	// var carouselIds: [String : String]
	
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
		return Avatar.idIndexMap.makeChildPath(parentPathName: PROPERTY_AVATAR, childPath: ["info_separator"])
	}
	
	var idProperties: [Any] { return [avatarId, "info"] }
	var properties: [String : PropertyValue]
	{
		return ["offline_password": passwordHash.value, "shared": isShared.value]
	}
	
	var projectId: String { return Avatar.project(fromId: avatarId) }
	
	// The key version of the avatar's name
	// var nameKey: String { return Avatar.nameKey(ofId: avatarId) }
	
	// Whether the info requires a password for authentication
	var requiresPassword: Bool { return passwordHash != nil }
	
	
	// INIT	--------------------
	
	init(avatarId: String, password: String? = nil, isShared: Bool = false)
	{
		self.avatarId = avatarId
		self.isShared = isShared
		
		if let password = password
		{
			// Uses the avatar id as salt
			self.passwordHash = createPasswordHash(password: password)
		}
	}
	
	private init(avatarId: String, passwordHash: String?, isShared: Bool)
	{
		self.avatarId = avatarId
		self.passwordHash = passwordHash
		self.isShared = isShared
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> AvatarInfo
	{
		return AvatarInfo(avatarId: id[PROPERTY_AVATAR].string(), passwordHash: properties["offline_password"].string, isShared: properties["shared"].bool())
	}
	
	
	// IMPLEMENTED METHODS	---
	
	func update(with properties: PropertySet)
	{
		if let isShared = properties["shared"].bool
		{
			self.isShared = isShared
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
	
	func resetPassword()
	{
		passwordHash = nil
	}
	
	func authenticate(loggedAccountId: String?, password: String) -> Bool
	{
		if passwordHash == nil
		{
			return true
		}
		else
		{
			return createPasswordHash(password: password) == passwordHash
		}
	}
	
	private func createPasswordHash(password: String) -> String
	{
		return (avatarId + password).SHA256()
	}
	
	static func get(avatarId: String) throws -> AvatarInfo?
	{
		return try get(parseId(from: [avatarId, "info"]))
	}
	
	// The avatar id portion of the avatar info id string
	static func avatarId(fromAvatarInfoId infoId: String) -> String
	{
		return property(withName: PROPERTY_AVATAR, fromId: infoId).string()
	}
}
