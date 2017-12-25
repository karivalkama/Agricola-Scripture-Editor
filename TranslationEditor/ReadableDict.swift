//
//  LazyDict.swift
//  TranslationEditor
//
//  Created by A&A Consulting on 15/12/2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This is just a common protocol for dictionaries and dictionary-like tools (read only)
protocol PropertyDict
{
    // Retrieves a value from this dictionary
    func get(_ key: String) -> PropertyValue?
}

extension Dictionary: PropertyDict where Key == String, Value == PropertyValue
{
    func get(_ key: String) -> PropertyValue?
    {
        return self[key]
    }
}
