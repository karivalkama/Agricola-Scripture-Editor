//
//  DatabaseExtension.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.12.2016.
//  Copyright © 2016 Mikko Hilpinen. All rights reserved.
//

import Foundation

extension CBLDatabase
{
	// Performs a database transaction that can fail (throw), in which case the transaction is cancelled and an error is thrown
	// When you block cannot throw, it is better to use inTransaction(...), this function is desidned for error prone situations (which database interactions generally are)
	func tryTransaction(_ block: @escaping () throws -> ()) throws
	{
		var raisedError: Error?
		
		inTransaction
		{
			do
			{
				try block()
			}
			catch
			{
				raisedError = error
			}
			
			return raisedError == nil
		}
		
		if let raisedError = raisedError
		{
			throw raisedError
		}
	}
}
