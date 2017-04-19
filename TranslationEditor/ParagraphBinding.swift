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
	static let idIndexMap: IdIndexMap = ["binding_uid"]
	
	let uid: String
	
	let sourceBookId: String
	let targetBookId: String
	
	var created: TimeInterval
	var creatorId: String
	
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
	var properties: [String : PropertyValue] { return ["source_book": sourceBookId.value, "target_book": targetBookId.value, "created": created.value, "creator": creatorId.value, "bindings": bindingDicts.map { PropertySet($0) }.value] }
	
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
	init(sourceBookId: String, targetBookId: String, bindings: [(String, String)], creatorId: String, created: TimeInterval = Date().timeIntervalSince1970, uid: String = UUID().uuidString.lowercased())
	{
		self.uid = uid
		self.sourceBookId = sourceBookId
		self.targetBookId = targetBookId
		self.created = created
		self.creatorId = creatorId
		self._bindings = bindings
		
		updateIdMaps()
	}
	
	static func create(from properties: PropertySet, withId id: Id) throws -> ParagraphBinding
	{
		// Parses the bindings separately
		return ParagraphBinding(sourceBookId: properties["source_book"].string(), targetBookId: properties["target_book"].string(), bindings: ParagraphBinding.parseBindings(from: properties["bindings"].array()), creatorId: properties["creator"].string(), created: properties["created"].time(), uid: id["binding_uid"].string())
	}
	
	
	// IMPLEMENTED METHODS	--
	
	func update(with properties: PropertySet) throws
	{
		if let creatorId = properties["creator"].string
		{
			self.creatorId = creatorId
		}
		if let created = properties["created"].double
		{
			self.created = created
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
			if let binding = bindingValue.object, let sourceId = binding["source"].string, let targetId = binding["target"].string
			{
				bindings.append((sourceId, targetId))
			}
		}
		
		return bindings
	}
}
