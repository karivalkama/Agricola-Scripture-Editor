//
//  CBDocumentDict.swift
//  TranslationEditor
//
//  Created by A&A Consulting on 15/12/2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

class CBDocumentDict: ReadableDict
{
    typealias Key = String
    typealias Value = PropertyValue
    
    // ATTRIBUTES   ---------------
    
    private let document: [String: Any]
    private var cachedValues: [String: PropertyValue] = [:]
    
    
    // INIT -----------------------
    
    init(doc: [String: Any])
    {
        self.document = doc
    }
    
    func get(_ key: String) -> PropertyValue?
    {
        // Checks first if there's a cached value
        if let cached = cachedValues[key]
        {
            return cached
        }
        else
        {
            if let value = PropertyValue.of(document[key])
            {
                cachedValues[key] = value
                return value
            }
            else
            {
                return PropertyValue.empty
            }
        }
    }
}
