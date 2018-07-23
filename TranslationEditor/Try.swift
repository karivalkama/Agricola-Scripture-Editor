//
//  Try.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.7.2018.
//  Copyright © 2018 Mikko Hilpinen. All rights reserved.
//

import Foundation

// This class is used for wrapping possibly failing operation results
class Try<T>
{
	// ATTRIBUTES	-----------------
	
	let success: T?
	let failure: Error?
	
	
	// COMPUTED	---------------------
	
	var isSuccess: Bool { return success != nil }
	
	var isFailure: Bool { return !isSuccess }
	
	var error: Error? { return failure }
	
	
	// CONSTRUCTOR	-----------------
	
	private init(success: T?, error: Error?)
	{
		self.success = success
		self.failure = error
	}
	
	// Runs operation, caches errors
	init(_ operation: () throws -> T)
	{
		do
		{
			success = try operation()
			failure = nil
		}
		catch
		{
			success = nil
			failure = error
		}
	}
	
	static func success<T>(_ value: T) -> Try<T>
	{
		return Try<T>(success: value, error: nil)
	}
	
	static func failure<T>(_ error: Error) -> Try<T>
	{
		return Try<T>(success: nil, error: error)
	}
	
	static func flatten<T>(_ value: Try<Try<T>>) -> Try<T>
	{
		if (value.isSuccess)
		{
			return value.success!
		}
		else
		{
			return Try.failure(value.failure!)
		}
	}
	
	
	// OTHER --------------------
	
	// Throws error on failure
	func unwrap() throws -> T
	{
		if (isSuccess)
		{
			return success!
		}
		else
		{
			throw failure!
		}
	}
	
	func orElse(_ backUp: Try<T>) -> Try<T>
	{
		if (isSuccess)
		{
			return self;
		}
		else
		{
			return backUp;
		}
	}
	
	func orElse(_ backUp: () throws -> T) -> Try<T>
	{
		if (isSuccess)
		{
			return self;
		}
		else
		{
			return Try<T>(backUp)
		}
	}
	
	func map<B>(_ f: (T) -> B) -> Try<B>
	{
		return Try<B>(success: success.map(f), error: error)
	}
	
	func flatMap<B>(_ f: (T) -> Try<B>) -> Try<B>
	{
		if (isSuccess)
		{
			return f(success!)
		}
		else
		{
			return Try.failure(error!)
		}
	}
	
	// Maps this try using one of two mapping functions
	func handleMap<B>(onSuccess successMap: (T) -> B, onFailure failureMap: (Error) -> B) -> B
	{
		if (isSuccess)
		{
			return successMap(success!)
		}
		else
		{
			return failureMap(failure!)
		}
	}
	
	// Handles this try if it is success or failure
	func handle(onSuccess successHandler: (T) -> (), onFailure errorHandler: (Error) -> ())
	{
		success.forEach(successHandler)
		error.forEach(errorHandler)
	}
}

// Tries can be converted to strings if the content can be converted
extension Try: CustomStringConvertible where T: CustomStringConvertible
{
	var description: String
	{
		if (isSuccess)
		{
			return "Success(" + success!.description + ")"
		}
		else
		{
			return "Failure(" + failure!.localizedDescription + ")"
		}
	}
}

/*
extension Try: CustomStringConvertible where T == String
{
	var description: String
	{
		if (isSuccess)
		{
			return "Success(" + success! + ")"
		}
		else
		{
			return "Failure(" + failure!.localizedDescription + ")"
		}
	}
}*/
