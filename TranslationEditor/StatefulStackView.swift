//
//  StatefulStackView.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 16.6.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import UIKit

enum DataState
{
	// Data is not yet available, but is being retrieved
	case loading
	// No data was found
	case empty
	// An error occurred while retrieving data
	case error
	// Data was found and loaded successfully
	case data
}

// This stack view is designed to change visible content based on program status
class StatefulStackView: UIStackView
{
	// ATTRIBUTES	-----------------
	
	private var views = [DataState: Weak<UIView>]()
	private var lastState: DataState?
	
	
	// OTHER METHODS	-------------
	
	func dataLoaded(isEmpty: Bool = false)
	{
		setState(isEmpty ? .empty : .data)
	}
	
	func errorOccurred(title: String? = nil, description: String? = nil, canContinueWithData: Bool = true)
	{
		if !canContinueWithData || lastState != .data
		{
			if title != nil || description != nil
			{
				registerDefaultErrorView(heading: title, description: description)
			}
			
			setState(.error)
		}
	}
	
	func setState(_ state: DataState)
	{
		if lastState == state
		{
			return
		}
		else
		{
			lastState = state
		}
		
		// Makes sure there exists a suitable view in the stack
		if !views[state].exists({ $0.isDefined })
		{
			var defaultView: UIView?
			switch state
			{
			case .loading: defaultView = DefaultLoadingView()
			case .empty: defaultView = DefaultNoDataView()
			case .error: defaultView = DefaultErrorView()
			default: defaultView = nil
			}
			
			if let defaultView = defaultView
			{
				register(defaultView, for: state)
			}
			else
			{
				return
			}
		}
		
		// Sets the view for the state visible and other views invisible
		views.values.forEach { $0.value?.isHidden = true }
		views[state]?.value?.isHidden = false
	}
	
	func register(_ view: UIView, for state: DataState)
	{
		// Removes any previous view for that state
		if let previousView = views[state]?.value
		{
			removeArrangedSubview(previousView)
		}
		
		views[state] = Weak(view)
		
		// Adds the view to this stack view if not already
		if !view.isDescendant(of: self)
		{
			view.isHidden = true
			addArrangedSubview(view)
		}
	}
	
	func registerDefaultLoadingView(title: String? = nil)
	{
		let view = DefaultLoadingView()
		
		if let title = title
		{
			view.title = title
		}
		
		register(view, for: .loading)
	}
	
	func registerDefaultErrorView(heading: String? = nil, description: String? = nil)
	{
		let view = DefaultErrorView()
		
		if let heading = heading
		{
			view.title = heading
		}
		if let description = description
		{
			view.errorDescription = description
		}
		
		register(view, for: .error)
	}
	
	func registerDefaultNoDataView(heading: String? = nil, description: String? = nil)
	{
		let view = DefaultNoDataView()
		
		if let heading = heading
		{
			view.title = heading
		}
		if let description = description
		{
			view.extraDescription = description
		}
		
		register(view, for: .empty)
	}
}
