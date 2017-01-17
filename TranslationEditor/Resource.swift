//
//  Resource.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 9.1.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This protocol is implemented by all the resource models
@available(*, deprecated)
protocol Resource: Storable
{
	var collectionId: String { get }
	var chapterIndex: Int { get }
	
	var pathId: String { get set }
}
