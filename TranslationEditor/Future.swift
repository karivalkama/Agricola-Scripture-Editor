//
//  Future.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.7.2018.
//  Copyright © 2018 Mikko Hilpinen. All rights reserved.
//

import Foundation

class Future<T>
{
	// ATTIRIBUTES	------------------
	
	private let group = DispatchGroup()
	
	// The currently held item of this future. Nil while future hasn't been fulfilled
	private(set) var currentItem: T?
	
	
	// COMPUTED	----------------------
	
	// Whether this future hasn't been fulfilled
	var isEmpty: Bool { return currentItem == nil }
	
	// Whether this future has already been fulfilled
	var isFulfilled: Bool { return !isEmpty }
	
	// A completion for this future
	var completion: Completion
	{
		if (isFulfilled)
		{
			return Completion.fulfilled()
		}
		else
		{
			return Completion.ofAsync { _ = self.waitFor() }
		}
	}
	
	
	// INIT	--------------------------
	
	// DB: Must be fultilled separately
	init()
	{
		group.enter()
	}
	
	// Already fulfilled future
	static func fulfilled<T>(with item: T) -> Future<T>
	{
		let f = Future<T>()
		f.fulfill(with: item)
		return f
	}
	
	// NB: Must be fulfilled separately
	static func sync<T>() -> Future<T> { return Future<T>() }
	
	// Fulfils this future asynchronously
	static func async<T>(_ operation: @escaping () -> T) -> Future<T>
	{
		let f = Future<T>()
		DispatchQueue.global().async
		{
			f.fulfill(with: operation())
		}
		return f
	}
	
	
	// OTHER	----------------------
	
	// Used for fulfilling this future synchronously
	func fulfill(with item: T)
	{
		currentItem = item
		group.leave()
	}
	
	// Returns the item in this future once it has been produced.
	// NB: Blocks the thread until this future has completed!
	func waitFor() -> T
	{
		if (isEmpty)
		{
			group.wait()
		}
		return currentItem!
	}
	
	// Similar to waitFor but the wait is limited
	// Returns nil if wait was interrupted
	func waitFor(timeout: DispatchTime) -> T?
	{
		if (isEmpty)
		{
			_ = group.wait(timeout: timeout)
		}
		return currentItem
	}
	
	// Performs an operation once this future completes. Always runs asynchronously
	func doAsync(_ operation: @escaping (T) -> ())
	{
		DispatchQueue.global().async
		{
			operation(self.waitFor())
		}
	}
	
	// Performs an operation once this future completes. Runs asynchronously only if has to
	func doOnceFulfilled(_ operation: @escaping (T) -> ())
	{
		if (isFulfilled)
		{
			operation(currentItem!)
		}
		else
		{
			doAsync(operation)
		}
	}
	
	// Maps the value of this future once it is available
	func map<B>(_ f: @escaping (T) -> B) -> Future<B>
	{
		if (isFulfilled)
		{
			return Future.fulfilled(with: f(currentItem!))
		}
		else
		{
			return Future.async { f(self.waitFor()) }
		}
	}
	
	// Maps the value of this future once it is available
	// The mapping is done asynchronously by returning another future
	func flatMap<B>(_ f: @escaping (T) -> Future<B>) -> Future<B>
	{
		if (isFulfilled)
		{
			return f(currentItem!)
		}
		else
		{
			return Future.async { f(self.waitFor()).waitFor() }
		}
	}
	
	// Makes a completion for this future, but only after an operation has been run. Always runs the operation asynchronously
	func completionAfterAsync(_ operation: @escaping (T) -> ()) -> Completion
	{
		return Completion.ofAsync { operation(self.waitFor()) }
	}
	
	// Makes a completion for this future, but only after an operation has been run. Runs asynchronously only if has to
	func completionAfter(_ operation: @escaping (T) -> ()) -> Completion
	{
		if (isFulfilled)
		{
			operation(currentItem!)
			return Completion.fulfilled()
		}
		else
		{
			return completionAfterAsync(operation)
		}
	}
	
	// Performs a piece of code once this future has completed. Only runs asynchronously if has to
	func onCompletion(_ operation: @escaping () -> ())
	{
		doOnceFulfilled { x in operation() }
	}
}
