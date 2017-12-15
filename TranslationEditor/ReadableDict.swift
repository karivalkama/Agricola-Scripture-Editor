//
//  LazyDict.swift
//  TranslationEditor
//
//  Created by A&A Consulting on 15/12/2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This is just a common protocol for dictionaries and dictionary-like tools (read only)
protocol ReadableDict
{
    // The type of the key in this dictionary
    associatedtype Key
    // The type of the value in this dictionary
    associatedtype Value
    
    // Retrieves a value from this dictionary
    func get(_ key: Key) -> Value?
}

extension Dictionary: ReadableDict
{
    func get(_ key: Key) -> Value?
    {
        return self[key]
    }
}
