//
//  ParagraphUtils.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

func match(_ sources: [Paragraph], and targets: [Paragraph]) -> [(Paragraph, Paragraph)]
{
	guard !sources.isEmpty && !targets.isEmpty else
	{
		print("ERROR: Nothing to match!")
		return []
	}
	
	var matches = [(Paragraph, Paragraph)]()
	var nextSourceIndex = 0
	var nextTargetIndex = 0
	
	// Matches paragraphs. A single paragraph may be matched with multiple consecutive paragraphs
	while nextSourceIndex < sources.count || nextTargetIndex < targets.count
	{
		// Finds out how many paragraphs without range there are on either side consecutively
		let noRangeSources = sources.take(from: nextSourceIndex, while: { $0.range == nil })
		let noRangeTargets = targets.take(from: nextTargetIndex, while: { $0.range == nil })
		
		// Matches them together, or if there are no matching paragraphs on either side, matches them to the latest paragraph instead
		if noRangeSources.isEmpty
		{
			// If both sides have ranges, matches the paragraphs based on range overlapping
			if noRangeTargets.isEmpty
			{
				// Goes through sources until one is found that doesn't have a range
				var lastConnectedTargetRange: VerseRange?
				var lastConnectedTargetIndex: Int?
				var targetWithoutRangeFound = false
				while nextSourceIndex < sources.count, let sourceRange = sources[nextSourceIndex].range
				{
					// The latest connected target may be connected to multiple sources
					if let lastConnectedTargetIndex = lastConnectedTargetIndex, let lastConnectedTargetRange = lastConnectedTargetRange, sourceRange.overlaps(with: lastConnectedTargetRange)
					{
						matches.append((sources[nextSourceIndex], targets[lastConnectedTargetIndex]))
					}
					else if targetWithoutRangeFound
					{
						break
					}
					
					// Goes through the targets (matching overlaps) until
					// a) No match can be made -> moves to next source
					// b) No target range available -> moves to next source but activates a different state too
					while nextTargetIndex < targets.count
					{
						if let targetRange = targets[nextTargetIndex].range
						{
							if sourceRange.overlaps(with: targetRange)
							{
								matches.append((sources[nextSourceIndex], targets[nextTargetIndex]))
								lastConnectedTargetIndex = nextTargetIndex
								lastConnectedTargetRange = targetRange
								nextTargetIndex += 1
							}
							else
							{
								break
							}
						}
						else
						{
							targetWithoutRangeFound = true
							break
						}
					}
					
					nextSourceIndex += 1
				}
			}
			else
			{
				let matchingSource = nextSourceIndex == 0 ? sources.first! : sources[nextSourceIndex - 1]
				noRangeTargets.forEach { matches.append((matchingSource, $0)) }
				nextTargetIndex += noRangeTargets.count
			}
		}
		else if noRangeTargets.isEmpty
		{
			let matchingTarget = nextTargetIndex == 0 ? targets.first! : targets[nextTargetIndex - 1]
			noRangeSources.forEach { matches.append(($0, matchingTarget)) }
			nextSourceIndex += noRangeSources.count
		}
		else
		{
			// TODO: Should probably let the user match paragraphs when the case is ambiguous (different number of non-verse paragraphs)
			// Now simply binds the last to many
			let commonIndices = min(noRangeSources.count, noRangeTargets.count)
			for i in 0 ..< commonIndices
			{
				matches.append((noRangeSources[i], noRangeTargets[i]))
			}
			for i in commonIndices ..< noRangeSources.count
			{
				matches.append((noRangeSources[i], noRangeTargets[commonIndices - 1]))
			}
			for i in commonIndices ..< noRangeTargets.count
			{
				matches.append((noRangeSources[commonIndices - 1], noRangeTargets[i]))
			}
			
			nextSourceIndex += noRangeSources.count
			nextTargetIndex += noRangeTargets.count
		}
	}
	
	// And if there happen to be any unmatched elements at the end, connects them to the last available match
	for i in nextTargetIndex ..< targets.count
	{
		matches.append((sources.last!, targets[i]))
	}
	
	return matches
}
