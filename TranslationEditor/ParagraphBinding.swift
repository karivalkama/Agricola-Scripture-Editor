//
//  ParagraphBinding.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 11.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Paragraph bindings are used for matching different paragraph set orderings with each other
final class ParagraphBinding: Storable
{
	// ATTRIBUTES	----------
	
	static let type = "binding"
	static let idIndexMap = ["binding_uid" : IdIndex(0)]
	
	let uid: String
	
	let sourceBookId: String
	let targetBookId: String
	
	let created: TimeInterval
	let creatorId: String
	
	var isDeprecated: Bool
	// Source paragraph id <-> Target paragraph id. Ordered by source
	private var _bindings: [(String, String)]
	var bindings: [(String, String)]
	{
		get { return _bindings }
		set
		{
			_bindings = newValue
			updateIdMaps()
		}
	}
	
	// path id <-> path id
	private var sourceToTarget: [String : [String]]!
	private var targetToSource: [String : [String]]!
	
	
	// COMPUTED PROPERTIES	--
	
	var idProperties: [Any] { return [uid] }
	var properties: [String : PropertyValue] { return ["source_book": PropertyValue(sourceBookId), "target_book": PropertyValue(targetBookId), "created": PropertyValue(created), "creator": PropertyValue(creatorId), "deprecated": PropertyValue(isDeprecated), "bindings": PropertyValue(bindingDicts.map { PropertySet($0) })] }
	
	private var bindingDicts: [[String : String]]
	{
		var dicts = [[String : String]]()
		for (sourceId, targetId) in bindings
		{
			dicts.append(["source" : sourceId, "target" : targetId])
		}

		return dicts
	}
	
	
	// INIT	------------------
	
	// The bindings are as follows: (source parameter id, target parameter id)
	init(sourceBookId: String, targetBookId: String, bindings: [(String, String)], creatorId: String, created: TimeInterval = Date().timeIntervalSince1970, uid: String = UUID().uuidString.lowercased(), deprecated: Bool = false)
	{
		self.uid = uid
		self.sourceBookId = sourceBookId
		self.targetBookId = targetBookId
		self.created = created
		self.creatorId = creatorId
		self.isDeprecated = deprecated
		self._bindings = bindings
		
		updateIdMaps()
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> ParagraphBinding
	{
		// Parses the bindings separately
		return ParagraphBinding(sourceBookId: properties["source_book"].string(), targetBookId: properties["target_book"].string(), bindings: ParagraphBinding.parseBindings(from: properties["bindings"].array()), creatorId: properties["creator"].string(), created: properties["created"].time(), uid: id["binding_uid"].string(), deprecated: properties["deprecated"].bool())
	}
	
	
	// IMPLEMENTED METHODS	--
	
	func update(with properties: PropertySet) throws
	{
		if let deprecated = properties["deprecated"].bool
		{
			self.isDeprecated = deprecated
		}
		if let bindings = properties["bindings"].array
		{
			self.bindings = ParagraphBinding.parseBindings(from: bindings)
		}
	}
	
	
	// OTHER METHODS	-----
	
	func targetsForSource(_ sourcePath: String) -> [String]
	{
		return sourceToTarget[sourcePath].or([])
	}
	
	func sourcesForTarget(_ targetPath: String) -> [String]
	{
		return targetToSource[targetPath].or([])
	}
	
	private func updateIdMaps()
	{
		sourceToTarget = [:]
		targetToSource = [:]
		
		for (sourceId, targetId) in bindings
		{
			let sourcePathId = Paragraph.pathId(fromId: sourceId)
			let targetPathId = Paragraph.pathId(fromId: targetId)
			
			sourceToTarget.append(key: sourcePathId, value: targetPathId, empty: [])
			targetToSource.append(key: targetPathId, value: sourcePathId, empty: [])
		}
	}
	
	private static func parseBindings(from bindingValues: [PropertyValue]) -> [(String, String)]
	{
		var bindings = [(String, String)]()
		
		for bindingValue in bindingValues
		{
			let binding = bindingValue.object()
			
			if let sourceId = binding["source"].string, let targetId = binding["target"].string
			{
				bindings.append((sourceId, targetId))
			}
		}
		
		return bindings
	}
}
