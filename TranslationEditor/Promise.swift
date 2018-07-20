//
//  Promise.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.7.2018.
//  Copyright © 2018 Mikko Hilpinen. All rights reserved.
//

import Foundation

class Promise<T>: Future<Try<T>>
{
	// COMPUTED	---------------
	
	var success: Future<T?> { return map { $0.success } }
	
	var failure: Future<Error?> { return map { $0.failure } }
	
	var currentSuccess: T? { return currentItem?.success }
	
	var currentFailure: Error? { return currentItem?.failure }
	
	var isSuccess: Bool { return currentItem.exists{ $0.isSuccess } }
	
	var isFailure: Bool { return currentItem.exists { $0.isFailure } }
	
	
	// INIT	-------------------
	
	// NB: Must be fulfilled separately
	override init()
	{
		super.init()
	}
	
	static func fulfilled<T>(with result: Try<T>) -> Promise<T>
	{
		let p = Promise<T>()
		p.fulfill(with: result)
		return p
	}
	
	static func success<T>(_ item: T) -> Promise<T>
	{
		return fulfilled(with: Try<T>.success(item))
	}
	
	static func failed<T>(_ error: Error) -> Promise<T>
	{
		return fulfilled(with: Try<T>.failure(error))
	}
	
	// Completes an operation asynchronously
	static func async<T>(_ operation: @escaping () -> Try<T>) -> Promise<T>
	{
		let p = Promise<T>()
		DispatchQueue.global().async
		{
			p.fulfill(with: operation())
		}
		return p
	}
	
	// Completes an operation asynchronously, catches errors
	static func tryAsync<T>(_ operation: @escaping () throws -> T) -> Promise<T>
	{
		let p = Promise<T>()
		DispatchQueue.global().async
		{
			p.fulfill(with: Try(operation))
		}
		return p
	}
	
	
	// OTHER	---------------
	
	// Fulfills this promise with a success value
	func succeed(with item: T)
	{
		fulfill(with: Try<T>.success(item))
	}
	
	// Fulfils this promise with a failure value
	func fail(with error: Error)
	{
		fulfill(with: Try<T>.failure(error))
	}
	
	// Maps the success value of this promise, if there is one. Asynchronous mapping is avoided, if possible.
	func map<B>(_ f: @escaping (T) -> B) -> Promise<B>
	{
		if (isFulfilled)
		{
			return Promise.fulfilled(with: currentItem!.map(f))
		}
		else
		{
			return Promise.async { self.waitFor().map(f) }
		}
	}
	
	// Maps the success value of this promise if there is one, may fail. Asynchronous mapping is avoided, if possible.
	func flatMap<B>(_ f: @escaping (T) -> Try<B>) -> Promise<B>
	{
		if (isFulfilled)
		{
			return Promise.fulfilled(with: currentItem!.flatMap(f))
		}
		else
		{
			return Promise.async { self.waitFor().flatMap(f) }
		}
	}
	
	// Asynchronously maps the success value of this promise into another promise.
	// The mapping function will be run asynchronously only if necessary
	func flatMap<B>(_ f: @escaping (T) -> Promise<B>) -> Promise<B>
	{
		if (isFulfilled)
		{
			if (isSuccess)
			{
				return f(currentSuccess!)
			}
			else
			{
				return Promise.failed(currentFailure!)
			}
		}
		else
		{
			return Promise.async
			{
				let myResult = self.waitFor()
				if (myResult.isSuccess)
				{
					return f(myResult.success!).waitFor()
				}
				else
				{
					return Try<B>.failure(myResult.failure!)
				}
			}
		}
	}
	
	// Attempts to map the success value of this promise. Works like flat map and catches errors
	func tryMap<B>(_ f: @escaping (T) throws -> B) -> Promise<B>
	{
		return flatMap { value in Try { try f(value) } }
	}
	
	// Handles the results of this promise, calling one of the two functions. Handling is always done asynchronously.
	func handleAsync(onSuccess successHandler: @escaping (T) -> (), onFailure errorHandler: @escaping (Error) -> ())
	{
		doAsync { $0.handle(onSuccess: successHandler, onFailure: errorHandler) }
	}
	
	// Handles the results of this promise, calling one of the two functions. Handling is done synchronously if possible.
	func handle(onSuccess successHandler: @escaping (T) -> (), onFailure errorHandler: @escaping (Error) -> ())
	{
		if (isFulfilled)
		{
			currentItem!.handle(onSuccess: successHandler, onFailure: errorHandler)
		}
		else
		{
			handleAsync(onSuccess: successHandler, onFailure: errorHandler)
		}
	}
	
	// Handles the success value of this promise when / if it becomes available. May call the function synchronously.
	func handleSuccess(_ successHandler: @escaping (T) -> ())
	{
		if (isFulfilled)
		{
			currentSuccess.forEach(successHandler)
		}
		else
		{
			doOnceFulfilled { $0.success.forEach(successHandler) }
		}
	}
	
	// Handles the failure value of this promise when / if it becomes available. May call the function synchronously.
	func handleFailure(_ errorHandler: @escaping (Error) -> ())
	{
		if (isFulfilled)
		{
			currentFailure.forEach(errorHandler)
		}
		else
		{
			doOnceFulfilled { $0.failure.forEach(errorHandler) }
		}
	}
}
