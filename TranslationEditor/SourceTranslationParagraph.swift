//
//  SourceTranslationParagraph.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Source translation paragraph is a non-editable paragraph that is used as a resource, tied to a certain target translation paragraph
final class SourceTranslationParagraph: Resource
{
	// ATTRIBUTES	-----------
	
	static let type = "source_translation_resource"
	
	let uid: String
	let collectionId: String
	let chapterIndex: Int
	let sectionIndex: Int
	let index: Int
	
	let content: [Para]
	
	var pathId: String
	
	
	// COMPUTED PROPERTIES	---
	
	static var idIndexMap: [String : IdIndex] { return [ "source_uid" : IdIndex(0) ] }
	
	var idProperties: [Any] { return [uid] }
	
	var properties: [String : PropertyValue] { return ["resource" : PropertyValue(collectionId), "chapter_index" : PropertyValue(chapterIndex), "section_index" : PropertyValue(sectionIndex), "index" : PropertyValue(index), "pathId" : PropertyValue(pathId), "paras" : PropertyValue(content)] }
	
	
	// INIT	------------------
	
	init(collectionId: String, chapterIndex: Int, sectionIndex: Int, paragraphIndex: Int, pathId: String, content: [Para], uid: String = UUID().uuidString.lowercased())
	{
		self.uid = uid
		self.collectionId = collectionId
		self.chapterIndex = chapterIndex
		self.sectionIndex = sectionIndex
		self.index = paragraphIndex
		self.content = content
		self.pathId = pathId
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> SourceTranslationParagraph
	{
		return SourceTranslationParagraph(collectionId: properties["resource"].string(), chapterIndex: properties["chapter_index"].int(), sectionIndex: properties["section_index"].int(), paragraphIndex: properties["index"].int(), pathId: properties["pathId"].string(), content: try Para.parseArray(from: properties["paras"].array(), using: Para.parse), uid: id["source_id"].string())
	}
	
	
	// IMPLEMENTED METHODS	-
	
	func update(with properties: PropertySet) throws
	{
		if let pathId = properties["pathId"].string
		{
			self.pathId = pathId
		}
	}
}
