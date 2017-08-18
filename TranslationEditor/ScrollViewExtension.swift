//
//  ScrollViewExtension.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 10.2.2017.
//  Copyright © 2017 SIL. All rights reserved.
//

import Foundation

// Some code references Alexander Dvornikov's answer at
// http://stackoverflow.com/questions/7706152/iphone-knowing-if-a-uiscrollview-reached-the-top-or-bottom
extension UIScrollView
{
	// Checks whether the scroll view is at the top
	var isAtTop: Bool
	{
		return contentOffset.y <= verticalOffsetForTop
	}
	
	// Checks whether the scroll view is scrolled to the bottom
	var isAtBottom: Bool
	{
		return contentOffset.y >= verticalOffsetForBottom
	}
	
	// The maximum offset that is considered to be at the top of the scrollview
	var verticalOffsetForTop: CGFloat
	{
		let topInset = contentInset.top
		return -topInset
	}
	
	// The vertical offset that is considered to be at the bottom of the scroll view
	var verticalOffsetForBottom: CGFloat
	{
		let scrollViewHeight = bounds.height
		let scrollContentSizeHeight = contentSize.height
		let bottomInset = contentInset.bottom
		let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
		return scrollViewBottomOffset
	}
	
	// The height of the area in this table view that displays content
	// (Insets do not count to this height)
	var visibleContentHeight: CGFloat
	{
		return frame.height - contentInset.top - contentInset.bottom
	}
	
	// Scrolls the view to the top
	func scrollToTop(animated: Bool = true)
	{
		setContentOffset(CGPoint(x: contentOffset.x, y: verticalOffsetForTop), animated: animated)
	}
	
	// Scrolls the view to the bottom
	func scrollToBottom(animated: Bool = true)
	{
		setContentOffset(CGPoint(x: contentOffset.x, y: verticalOffsetForBottom), animated: animated)
	}
}
