//
//  Completion.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 20.7.2018.
//  Copyright © 2018 Mikko Hilpinen. All rights reserved.
//

import Foundation

// Completions are used for marking when an asynchronous operation finishes
class Completion
{
	// ATTRIBUTES	-----------------
	
	private let group = DispatchGroup()
	
	// Whether the operation has finished already
	private(set) var isCompleted = false
	
	
	// INIT	-------------------------
	
	// NB: Must be fulfilled separately
	init()
	{
		group.enter()
	}
	
	static func fulfilled() -> Completion
	{
		let c = Completion()
		c.fulfill()
		return c
	}
	
	// Completes when operation completes. Run asynchronously
	static func ofAsync(_ operation: @escaping () -> ()) -> Completion
	{
		let c = Completion()
		DispatchQueue.global().async
		{
			operation()
			c.fulfill()
		}
		return c
	}
	
	
	// OTHER	---------------------
	
	// Marks as completed
	func fulfill()
	{
		isCompleted = true
		group.leave()
	}
	
	// Waits until marked as completed
	func waitFor()
	{
		group.wait()
	}
	
	// Completes another operation after this one. Always run asynchronously
	func continuedAsync(with operation: @escaping () -> ()) -> Completion
	{
		return Completion.ofAsync
		{
			self.waitFor()
			operation()
		}
	}
	
	// Completes another operation after this one. Runs asynchronously only if has to
	func continued(with operation: @escaping () -> ()) -> Completion
	{
		if (isCompleted)
		{
			operation()
			return Completion.fulfilled()
		}
		else
		{
			return Completion.ofAsync
			{
				self.waitFor()
				operation()
			}
		}
	}
	
	// Maps this completion into a future
	func toFuture<T>(_ makeValue: @escaping () -> T) -> Future<T>
	{
		if (isCompleted)
		{
			return Future<T>.fulfilled(with: makeValue())
		}
		else
		{
			return Future<T>.async
			{
				self.waitFor()
				return makeValue()
			}
		}
	}
}
