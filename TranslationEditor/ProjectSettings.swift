//
//  ProjectSettings.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
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
		return ["project_path": PropertyValue(projectPath.map { PropertyValue($0) }), "avatars": PropertyValue(avatarIds.map { PropertyValue($0) }), "rigths": PropertyValue(PropertySet(rights.mapDict { key, value in return (key.rawValue, PropertyValue(value.map { PropertyValue($0) })) }))] // TODO: Create a slightly more simple way to do this
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
		return ProjectSettings(projectId: id[PROPERTY_PROJECT].string(), projectPath: properties["project_path"].array().flatMap { $0.string }, avatarIds: properties["avatars"].array().flatMap { $0.string }, rights: properties["rights"].object().properties.flatMapDict { key, value in return (UserRight(rawValue: key), value.array().flatMap { $0.string }) })
	}
	
	
	// OTHER METHODS	-----------------
	
	func update(with properties: PropertySet)
	{
		
	}
}
