//
//  Carousel.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

final class Carousel: Storable
{
	// ATTRIBUTES	--------------
	
	static let PROPERTY_PROJECT = "project"
	
	static let type = "carousel"
	//static let idIndexMap = ["carousel_uid": IdIndex(0)]
	
	let uid: String
	let projectId: String
	let isTemplate: Bool
	let ownerId: String
	
	var sourceBookIds: [String]
	var resourceIds: [String]
	
	
	// COMPUTED PROPERTIES	-----
	
	static var idIndexMap: IdIndexMap
	{
		return Project.idIndexMap.makeChildPath(parentPathName: PROPERTY_PROJECT, childPath: ["carousel_separator", "carousel_uid"])
	}
	
	var idProperties: [Any] { return [projectId, "carousel", uid] }
	var properties: [String : PropertyValue]
	{
		return ["template": isTemplate.value, "owner": ownerId.value, "source_books": sourceBookIds.value, "resources": resourceIds.value]
	}
	
	
	// INIT	---------------------
	
	init(projectId: String, sourceBookIds: [String], resourceIds: [String], ownerId: String, isTemplate: Bool, uid: String = UUID().uuidString.lowercased())
	{
		self.projectId = projectId
		self.sourceBookIds = sourceBookIds
		self.resourceIds = resourceIds
		self.ownerId = ownerId
		self.isTemplate = isTemplate
		self.uid = uid
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> Carousel
	{
		return Carousel(projectId: id[PROPERTY_PROJECT].string(), sourceBookIds: properties["source_books"].array { $0.string }, resourceIds: properties["resources"].array { $0.string }, ownerId: properties["owner"].string(), isTemplate: properties["template"].bool(), uid: id["carousel_uid"].string())
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func update(with properties: PropertySet)
	{
		if let sourceBookData = properties["source_books"].array
		{
			self.sourceBookIds = sourceBookData.flatMap { $0.string }
		}
		if let resourceData = properties["resources"].array
		{
			self.resourceIds = resourceData.flatMap { $0.string }
		}
	}
}
