//
//  Carousel.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 30.1.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

final class Carousel: Storable
{
	// ATTRIBUTES	--------------
	
	static let PROPERTY_AVATAR = "avatar"
	static let PROPERTY_BOOK_CODE = "book_code"
	
	static let type = "carousel"
	
	let avatarId: String
	let bookCode: BookCode
	
	private(set) var resourceIds: [String]
	private(set) var updated: TimeInterval
	
	
	// COMPUTED PROPERTIES	-----
	
	static var idIndexMap: IdIndexMap
	{
		return Avatar.idIndexMap.makeChildPath(parentPathName: PROPERTY_AVATAR, childPath: ["carousel_separator", PROPERTY_BOOK_CODE])
	}
	
	var idProperties: [Any] { return [avatarId, "carousel", bookCode.code.lowercased()] }
	var properties: [String : PropertyValue]
	{
		return ["resources": resourceIds.value, "updated": updated.value]
	}
	
	
	// INIT	---------------------
	
	init(avatarId: String, bookCode: BookCode, resourceIds: [String], updated: TimeInterval = Date().timeIntervalSince1970)
	{
		self.bookCode = bookCode
		self.resourceIds = resourceIds
		self.avatarId = avatarId
		self.updated = updated
	}
	
	static func create(from properties: PropertySet, withId id: Id) -> Carousel
	{
		return Carousel(avatarId: id[PROPERTY_AVATAR].string(), bookCode: BookCode.of(code: id[PROPERTY_BOOK_CODE].string()), resourceIds: properties["resources"].array { $0.string }, updated: properties["updated"].time())
	}
	
	
	// IMPLEMENTED METHODS	----
	
	func update(with properties: PropertySet)
	{
		if let resourceData = properties["resources"].array
		{
			self.resourceIds = resourceData.flatMap { $0.string }
		}
		if let updated = properties["updated"].double
		{
			self.updated = updated
		}
	}
	
	
	// OTHER METHODS	-------
	
	// Saves new resource state to the database
	func pushResources(_ resourceIds: [String]) throws
	{
		self.resourceIds = resourceIds
		self.updated = Date().timeIntervalSince1970
		
		try push()
	}
	
	static func push(avatarId: String, bookCode: BookCode, resourceIds: [String]) throws
	{
		try Carousel(avatarId: avatarId, bookCode: bookCode, resourceIds: resourceIds).push()
	}
	
	static func get(avatarId: String, bookCode: BookCode) throws -> Carousel?
	{
		return try get(parseId(from: [avatarId, "carousel", bookCode.code.lowercased()]))
	}
}
