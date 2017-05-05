//
//  ParagraphUtils.swift
//  TranslationEditor
//
//  Created by Mikko Hilpinen on 18.4.2017.
//  Copyright © 2017 Mikko Hilpinen. All rights reserved.
//

import Foundation

func match(_ sources: [Paragraph], and targets: [Paragraph]) -> [(source: Paragraph, target: Paragraph)]
{
	// TODO: You have to take chapter indices into account, else all is messed up!
	
	// Makes sure there actually are paragraphs to match
	guard !sources.isEmpty && !targets.isEmpty else
	{
		return []
	}
	
	// Groups the paragraphs by chapters, so that ranges can be used within that range
	let sourcesByChapter = sources.toArrayDictionary { return ($0.chapterIndex, $0) }
	let targetsByChapter = targets.toArrayDictionary { return ($0.chapterIndex, $0) }
	
	let maxChapter = max(sourcesByChapter.keys.max()!, targetsByChapter.keys.max()!)
	var matches = [(source: Paragraph, target: Paragraph)]()
	
	for chapterIndex in 1 ... maxChapter
	{
		if let chapterSources = sourcesByChapter[chapterIndex], let chapterTargets = targetsByChapter[chapterIndex]
		{
			matches.append(contentsOf: matchInsideChapter(chapterSources, and: chapterTargets))
		}
		else
		{
			print("ERROR: Either of the translations is missing chapter \(chapterIndex)")
		}
	}
	
	return matches
}

private func matchInsideChapter(_ sources: [Paragraph], and targets: [Paragraph]) -> [(source: Paragraph, target: Paragraph)]
{
	guard !sources.isEmpty && !targets.isEmpty else
	{
		return []
	}
	
	// Creates an index match set first (target index, source index)
	// This will be swapped to (source index, target index) later
	var targetToSourceIndexMatches = [(targetIndex: Int, sourceIndex: Int)]()
	
	// First makes all the possible matches based on paragraph ranges
	var lastMatchedSourceIndex: Int?
	for targetIndex in 0 ..< targets.count
	{
		guard let targetRange = targets[targetIndex].range else
		{
			continue
		}
		
		for sourceIndex in lastMatchedSourceIndex.or(0) ..< sources.count
		{
			guard let sourceRange = sources[sourceIndex].range else
			{
				continue
			}
			
			// If the source ranges start to be larger the matched target range, doesn't bother going forward
			if sourceRange.start >= targetRange.end
			{
				break
			}
			
			// Matches all overlapping ranges
			if sourceRange.overlaps(with: targetRange)
			{
				targetToSourceIndexMatches.add((targetIndex, sourceIndex))
				lastMatchedSourceIndex = sourceIndex
			}
		}
	}
	
	// Makes sure the very first and last indices are matched together
	if (targetToSourceIndexMatches.isEmpty)
	{
		targetToSourceIndexMatches.add((0, 0))
		if targets.count > 1 || sources.count > 1
		{
			targetToSourceIndexMatches.add((targets.count - 1, sources.count - 1))
		}
	}
	else
	{
		// Creates a new match in the beginning if either of the first elements haven't been matched
		if targetToSourceIndexMatches.first!.targetIndex > 0 || targetToSourceIndexMatches.first!.sourceIndex > 0
		{
			targetToSourceIndexMatches.insert((0, 0), at: 0)
		}
		// Likewise with the last indices
		if targetToSourceIndexMatches.last!.targetIndex < targets.count - 1 || targetToSourceIndexMatches.last!.sourceIndex < sources.count - 1
		{
			targetToSourceIndexMatches.add((targets.count - 1, sources.count - 1))
		}
	}
	
	// Fills any gaps on the left (target) side
	// Swaps sides and fills any remaining gaps on the left (source) side
	return fillGapsAtLeftSideMatches(fillGapsAtLeftSideMatches(targetToSourceIndexMatches).map { ($0.1, $0.0) }).map { (sources[$0.0], targets[$0.1]) }
}

private func fillGapsAtLeftSideMatches(_ originalMatches: [(Int, Int)]) -> [(Int, Int)]
{
	var newMatches = originalMatches
	
	var nextMatchIndex = 1
	while nextMatchIndex < newMatches.count
	{
		let (lastLeftSideIndex, lastRightSideIndex) = newMatches[nextMatchIndex - 1]
		let (leftSideIndex, matchingRightIndex) = newMatches[nextMatchIndex]
		
		if lastLeftSideIndex < leftSideIndex - 1
		{
			// If a gap was found on the left side, checks if there is one on the right side as well
			if lastRightSideIndex < matchingRightIndex - 1
			{
				// If so, connects the left side gap with the first right side gap
				newMatches.insert((lastLeftSideIndex + 1, lastRightSideIndex + 1), at: nextMatchIndex)
			}
			// If there was no gap at the right side, just matches the left side gap with the last right side match
			else
			{
				newMatches.insert((lastLeftSideIndex + 1, lastRightSideIndex), at: nextMatchIndex)
			}
		}
		
		// Either way, there's a match and we can move on
		nextMatchIndex += 1
	}
	
	return newMatches
}

/*
func match(_ sources: [Paragraph], and targets: [Paragraph]) -> [(Paragraph, Paragraph)]
{
	guard !sources.isEmpty && !targets.isEmpty else
	{
		print("ERROR: Nothing to match!")
		return []
	}
	
	// Source + Target
	var matches = [(Paragraph, Paragraph)]()
	var nextSourceIndex = 0
	var nextTargetIndex = 0
	
	// Matches paragraphs. A single paragraph may be matched with multiple consecutive paragraphs
	while nextSourceIndex < sources.count || nextTargetIndex < targets.count
	{
		// If either of the sides is at the last paragraph (or past it), matches the remaining paragraphs to the last paragraph on the opposite side
		if nextSourceIndex >= sources.count - 1
		{
			targets[nextTargetIndex ..< targets.count].forEach { matches.add((sources.last!, $0)) }
			break
		}
		else if nextTargetIndex >= targets.count - 1
		{
			sources[nextSourceIndex ..< sources.count].forEach { matches.add(($0, targets.last!)) }
			break
		}
		else
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
	}
	
	// And if there happen to be any unmatched elements at the end, connects them to the last available match
	/*
	for i in nextTargetIndex ..< targets.count
	{
		matches.append((sources.last!, targets[i]))
	}*/
	
	return matches
}*/
