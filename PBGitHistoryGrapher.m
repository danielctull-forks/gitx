//
//  PBGitHistoryGrapher.m
//  GitX
//
//  Created by Nathan Kinsinger on 2/20/10.
//  Copyright 2010 Nathan Kinsinger. All rights reserved.
//

#import "PBGitCommit.h"
#import "PBGitGrapher.h"
#import "PBGitHistoryGrapher.h"
#import "PBGitSHA.h"


@implementation PBGitHistoryGrapher


- (id) initWithBaseCommits:(NSSet *)commits viewAllBranches:(BOOL)viewAll queue:(NSOperationQueue *)queue delegate:(id)theDelegate
{
	delegate = theDelegate;
	currentQueue = queue;
	searchSHAs = [NSMutableSet setWithSet:commits];
	grapher = [[PBGitGrapher alloc] initWithRepository:nil];
	viewAllBranches = viewAll;

	return self;
}


- (void)sendCommits:(NSArray *)commits
{
	NSDictionary *commitData = [NSDictionary dictionaryWithObjectsAndKeys:currentQueue, kCurrentQueueKey, commits, kNewCommitsKey, nil];
	[delegate performSelectorOnMainThread:@selector(updateCommitsFromGrapher:) withObject:commitData waitUntilDone:NO];
}


- (void) graphCommits:(NSArray *)revList
{
	if (!revList || [revList count] == 0)
		return;

	//NSDate *start = [NSDate date];
	NSThread *currentThread = [NSThread currentThread];
	NSDate *lastUpdate = [NSDate date];
	NSMutableArray *commits = [NSMutableArray array];
	NSInteger counter = 0;

	for (PBGitCommit *commit in revList) {
		if ([currentThread isCancelled])
			return;
		PBGitSHA *commitSHA = [commit sha];
		if (viewAllBranches || [searchSHAs containsObject:commitSHA]) {
			[grapher decorateCommit:commit];
			[commits addObject:commit];
			if (!viewAllBranches) {
				[searchSHAs removeObject:commitSHA];
				[searchSHAs addObjectsFromArray:[commit parents]];
			}
		}
		if (++counter % 100 == 0) {
			if ([[NSDate date] timeIntervalSinceDate:lastUpdate] > 0.1) {
				[self sendCommits:commits];
				commits = [NSMutableArray array];
				lastUpdate = [NSDate date];
			}
		}
	}
	//NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
	//NSLog(@"Graphed %i commits in %f seconds (%f/sec)", counter, duration, counter/duration);

	[self sendCommits:commits];
	[delegate performSelectorOnMainThread:@selector(finishedGraphing) withObject:nil waitUntilDone:NO];
}


@end
