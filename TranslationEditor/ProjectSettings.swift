//
//  ProjectSettings.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

enum UserRight: String
{
	case admin, task, resource, tag
	case projectPath = "project_path"
}

// Project settings are used for storing restricted project data
final class ProjectSettings: Storable
{
	// ATTRIBUTES	----------------------
	
	static let PROPERTY_PROJECT = "project"
	
	static let type = "project_settings"
	
	let projectId: String
	
	// Array of phase ids
	var projectPath: [String]
	var avatarIds: [String]
	// User right -> array of avatar ids
	var rights: [UserRight: [String]]
	
	
	// COMPUTED PROPERTIES	-------------
	
	static var idIndexMap: IdIndexMap
	{
		return Project.idIndexMap.makeChildPath(parentPathName: PROPERTY_PROJECT, childPath: ["settings_separator"])
	}
	
	var idProperties: [Any] { return [projectId, "settings"] }
	
	var properties: [String : PropertyValue]
	{
		return ["project_path": projectPath.value, "avatars": avatarIds.value, "rigths": PropertySet(rights.mapDict { ($0.rawValue, $1.value) }).value]
	}
	
	
	// INIT	------------------------------
	
	init(projectId: String, projectPath: [String], avatarIds: [String], rights: [UserRight: [String]])
	{
		self.projectId = projectId
		self.projectPath = projectPath
		self.avatarIds = avatarIds
		self.rights = rights
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> ProjectSettings
	{
		return ProjectSettings(projectId: id[PROPERTY_PROJECT].string(), projectPath: properties["project_path"].array { $0.string }, avatarIds: properties["avatars"].array { $0.string }, rights: properties["rights"].object().properties.flatMapDict { key, value in return (UserRight(rawValue: key), value.array() { $0.string }) })
	}
	
	
	// OTHER METHODS	-----------------
	
	func update(with properties: PropertySet)
	{
		if let projectPath = properties["project_path"].array
		{
			self.projectPath = projectPath.compactMap { $0.string }
		}
		if let avatarIds = properties["avatars"].array
		{
			self.avatarIds = avatarIds.compactMap { $0.string }
		}
		if let rights = properties["rights"].object
		{
			self.rights = rights.properties.flatMapDict { key, value in return (UserRight(rawValue: key), value.array { $0.string }) }
		}
	}
}
