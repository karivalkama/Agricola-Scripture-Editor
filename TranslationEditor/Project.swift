//
//  Project.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 27.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// A project combines multiple associated resources together
// Some resources under a project will require specific project level authorization
final class Project: Storable
{
	// ATTRIBUTES	----------------
	
	static let type = "project"
	static let idIndexMap: IdIndexMap = ["project_uid": 0]
	
	let uid: String
	let created: TimeInterval
	let languageId: String
	
	var name: String
	var ownerId: String // Id of the owner CB user
	var contributorIds: [String] // Ids of the contributing CB users
	
	
	// COMPUTED PROPERTIES	--------
	
	var idProperties: [Any] { return [uid] }
	var properties: [String : PropertyValue]
	{
		return ["owner": ownerId.value, "contributors": contributorIds.value, "name": name.value, "language": languageId.value, "created": created.value]
	}
	
	
	// INIT	------------------------
	
	init(name: String, languageId: String, ownerId: String, contributorIds: [String], uid: String = UUID().uuidString.lowercased(), created: TimeInterval = Date().timeIntervalSince1970)
	{
		self.uid = uid
		self.created = created
		self.languageId = languageId
		self.name = name
		self.ownerId = ownerId
		
		if contributorIds.contains(ownerId)
		{
			self.contributorIds = contributorIds
		}
		else
		{
			self.contributorIds = contributorIds + ownerId
		}
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> Project
	{
		return Project(name: properties["name"].string(), languageId: properties["language"].string(), ownerId: properties["owner"].string(), contributorIds: properties["contributors"].array({ $0.string }), uid: id["project_uid"].string(), created: properties["created"].time())
	}
	
	
	// IMPLEMENTED METHODS	-------
	
	func update(with properties: PropertySet)
	{
		if let name = properties["name"].string
		{
			self.name = name
		}
		if let ownerId = properties["owner"].string
		{
			self.ownerId = ownerId
		}
		if let contributorData = properties["contributors"].array
		{
			self.contributorIds = contributorData.flatMap { $0.string }
		}
	}
}
