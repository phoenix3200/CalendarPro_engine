//
//  RingerStyle.mm
//  cpengine
//
//  Created by Public Nuisance on 10/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

//#define TESTING

#import "common.h"
#import "defines.h"

#import "RingerStyle.h"
#import "cpengine.h"
#import "timeitem.h"

RingerStyle *RingerStyle$shared;

pthread_mutex_t mutex;

sqlite3 *db;
NSMutableDictionary *_mainDict = 0;
NSMutableDictionary *_altDict = 0;
NSAutoreleasePool *_pool = 0;

NSTimer *timer = 0;

timeblk *schedEvent = 0;
timeblk **schedRules = 0;


//timeitem *schedule = 0;

#define c_sqlite3_prepare_v2	0
#define c_sqlite3_bind_int		1
#define c_styleForEventId		2
#define c_priorityForStyle		3
#define c_styleForPriority		4
#define c_ruleStyleForPriority	5
#define c_ruleMatchesStuff		6

#define G_RAND1 0x39d8d6c4
#define G_RAND2 0x29bad223
#define G_RAND3 0x53b6fa35




#define NSLog(...)


uint32_t styleForEventId(int eventId)
{
	SelLog();
	
	if(eventId<=0)
	{
		return 0;
	}
	
	if(!db)
		return nil;
	
	uint32_t ret = 0;

	{
		char *find = "select style from CPEvents where event = ?";
		sqlite3_stmt *find_stmt;
		if(sqlite3_prepare_v2(db, find, -1, &find_stmt, NULL)==SQLITE_OK)
		{
			sqlite3_bind_int(find_stmt, 1, eventId);
			if(sqlite3_step(find_stmt)==SQLITE_ROW)
			{
				ret = sqlite3_column_int(find_stmt, 0);
		//		NSLog(@"returning %d for %d", ret, eventId);
			}
			sqlite3_finalize(find_stmt);
		}
	}
	if(!ret)
	{
		char *parent = "select orig_event_id from Event where rowid = ?";
		sqlite3_stmt *parent_stmt;
		if(sqlite3_prepare_v2(db, parent, -1, &parent_stmt, NULL)==SQLITE_OK)
		{
			sqlite3_bind_int(parent_stmt, 1, eventId);
			uint32_t res = sqlite3_step(parent_stmt);
			if(res==SQLITE_ROW)
			{
				int parentId = sqlite3_column_int(parent_stmt, 0);
				sqlite3_finalize(parent_stmt);
		//		NSLog(@"returning parent for %d", eventId);
				ret = styleForEventId(parentId);
			}
			sqlite3_finalize(parent_stmt);
		}
	}
	return ret;
}


using namespace std;

extern bool isSpringBoard;

/*
#ifdef FILE_LOG
	#ifndef NSLog(...)
		#define NSF
	#else
		#define NSFO
	#endif
	#define NSLog(args...) FLog(args)
#endif
*/

bool ruleMatchesStuff(NSDictionary* rule, NSString* summary, NSString* location, NSString* description, int calendar_id, int availability)
//- (bool) rule: (NSDictionary*) rule matchesEventSummary: (NSString*) summary location: (NSString*) location description: (NSString*) description
{
	NSArray *filters = [rule objectForKey: @"filters"];
	for(NSDictionary *filter in filters)
	{
		bool ruleMustApply = ([[filter objectForKey: @"filter"] boolValue]) ? NO : YES;
		
		NSString *category = nil;
		switch([[filter objectForKey: @"category"] intValue])
		{
			case 0:
				category = summary;
				break;
			case 1:
				category = location;
				break;
			case 2:
				category = description;
				break;
			case 3:
				NSLog(@"calendar_id %d %d", [[filter objectForKey: @"match"] intValue], calendar_id);
				if( ruleMustApply ^ ([[filter objectForKey: @"match"] intValue] == calendar_id) )
					return NO;
				continue;
			case 4:
				NSLog(@"availability %d %d", [[filter objectForKey: @"match"] intValue] , availability);
				if(ruleMustApply ^ ([[filter objectForKey: @"match"] intValue] == availability) )
					return NO;
				continue;
		}
		
		
		
		NSString *match = [filter objectForKey: @"string"];
		
		NSLog(@"searching for %@ in %@", match, category);
		NSRange matchRange = [category rangeOfString: match options: NSCaseInsensitiveSearch];
		
		
		NSLog(@"Found at %d,+%d", matchRange.location, matchRange.length);
		uint32_t cat_length = [category length];
		
		if(matchRange.length)
		{
			switch([[filter objectForKey: @"match"] intValue])
			{
				case 0: //contains
					ruleMustApply ^= YES;
					break;
				case 1: //is
					if(match.length == cat_length)
						ruleMustApply ^= YES;
						break;
				case 2: //begins with
					if(matchRange.location == 0)
						ruleMustApply ^= YES;
						break;
				case 3: //ends with
					if(matchRange.location + matchRange.length == cat_length)
						ruleMustApply ^= YES;
						break;
			}
		}
		if(ruleMustApply)
			return NO;
	}
	return YES;
}

uint32_t priorityForStyle(int styleID)
{
	if(styleID<=0)
		return 0;
	
	if(!db)
		return nil;
	
	char *find = "select priority from CPStyles where rowid = ?";
	sqlite3_stmt *find_stmt;
	
	uint32_t ret = -1;
	if(sqlite3_prepare_v2(db, find, -1, &find_stmt, NULL)==SQLITE_OK)
	{
		sqlite3_bind_int(find_stmt, 1, styleID);
		if(sqlite3_step(find_stmt)==SQLITE_ROW)
		{
			ret = sqlite3_column_int(find_stmt, 0);
		}
		sqlite3_finalize(find_stmt);
	}
	return ret;
}

uint32_t styleForPriority(int priority)
{
	if(priority<0)
		return 0;
	
	if(!db)
		return nil;
	
	char *find = "select rowid from CPStyles where priority = ?";
	sqlite3_stmt *find_stmt;
	
	uint32_t ret = -1;
	if(sqlite3_prepare_v2(db, find, -1, &find_stmt, NULL)==SQLITE_OK)
	{
		sqlite3_bind_int(find_stmt, 1, priority);
		if(sqlite3_step(find_stmt)==SQLITE_ROW)
		{
			ret = sqlite3_column_int(find_stmt, 0);
		}
		sqlite3_finalize(find_stmt);
	}
	return ret;
}


uint32_t ruleStyleForPriority(int priority)
{
	if(priority<0)
		return 0;
	
	if(!db)
		return nil;
	
	char *find = "select style from CPRules where priority = ?";
	sqlite3_stmt *find_stmt;
	
	uint32_t ret = -1;
	if(sqlite3_prepare_v2(db, find, -1, &find_stmt, NULL)==SQLITE_OK)
	{
		sqlite3_bind_int(find_stmt, 1, priority);
		if(sqlite3_step(find_stmt)==SQLITE_ROW)
		{
			ret = sqlite3_column_int(find_stmt, 0);
		}
		sqlite3_finalize(find_stmt);
	}
	return ret;
}

extern bool isSpringBoard;

void TBPrint(timeblk *blk)
{
	timeblkval *data = blk->data;
	uint32_t idx=0;
	NSLog(@"Starting at %d", data[idx].endT);
	while(idx=data[idx].next)
	{
		NSLog(@"Priority %08x until %d", data[idx].priority, data[idx].endT);
	}
}

void refreshCache()
{
	NSLine();
	
	
	NSTimeZone *ocTZ = nil, *sysTZ, *evTZ;
	{
		{
			char *ocTZ_cmd = "select value from _SQLiteDatabaseProperties where key = \"OccurrenceCacheTimeZone\"";
			sqlite3_stmt *ocTZ_stmt;
			
			if(sqlite3_prepare_v2(db, ocTZ_cmd, -1, &ocTZ_stmt, NULL)==SQLITE_OK)
			{				
				if(sqlite3_step(ocTZ_stmt) == SQLITE_ROW)
				{
					ocTZ = [NSTimeZone timeZoneWithName: [NSString stringWithUTF8String: (const char *) sqlite3_column_text(ocTZ_stmt, 0)]];
				}
				sqlite3_finalize(ocTZ_stmt);
			}
		}
		sysTZ = [NSTimeZone localTimeZone];
		evTZ = sysTZ;
		{
			NSDictionary *calendarPrefs = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/Preferences/com.apple.mobilecal.plist"];
			if([[calendarPrefs objectForKey: @"ViewedTimeZoneAutomatic"] boolValue]==NO)
			{
				evTZ = [NSTimeZone timeZoneWithName: [calendarPrefs objectForKey: @"ViewedTimeZone"]];
			}
		}
	}
	
	NSLine();
	
	uint32_t refTime = [NSDate timeIntervalSinceReferenceDate];
	
	NSLine();
	uint32_t sysOffs = [sysTZ secondsFromGMT];
	uint32_t locTime = refTime + sysOffs;
	
	NSLine();
	uint32_t ocOffs = [ocTZ secondsFromGMT];
	uint32_t locDay = (locTime / 86400);
	uint32_t locWkDay = locDay % 7;
	
	NSLine();
	uint32_t sysDayStart = locDay * 86400 - [sysTZ secondsFromGMT];
	uint32_t ocDayStart = locDay * 86400 - ocOffs;
	{
		if(!schedEvent)
			schedEvent = TBnew();
		TBset(schedEvent, refTime-3600,	sysDayStart + 86400*2, (uint32_t) (1<<31)-1);

		if(!schedRules)
		{
			schedRules = (timeblk **)malloc(sizeof(timeblk*)*3);
			for(int i=0; i<3; i++)
			{
				NSLine();
				schedRules[i] = TBnew();
			}
		}

		for(int i=0; i<3; i++)
		{
			TBset(schedRules[i], refTime-3600,	sysDayStart + 86400*2, (uint32_t) (1<<31)-1);
		}
		
		//return;
		
		/*
		timeitem *start = new timeitem;
		timeitem *end = new timeitem;
		start->prior = (uint32_t) 0;
		start->endT = refTime-3600;
		start->next = end;
		
		end->prior = (uint32_t) (1<<31)-1;
		end->endT = sysDayStart + 86400*2; //events until tomorrow midnight (occurrenceCache)
		end->next = 0;
		
		schedule=  start;
		*/
	}
	
	NSMutableArray *rules;
	//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	{
		rules = [[NSMutableArray alloc] init];
		
		char *req = "select rowid, priority, all_day, start_time, end_time, weekdays, match, override from CPRules order by priority";
		
		sqlite3_stmt *req_stmt;
		if(sqlite3_prepare_v2(db, req, -1, &req_stmt, NULL)==SQLITE_OK)
		{
			while(sqlite3_step(req_stmt)==SQLITE_ROW)
			{
				int prior = sqlite3_column_int(req_stmt, 1);
				int allDay = sqlite3_column_int(req_stmt, 2);	// local time
				int startT, endT;
				if(allDay)
				{
					startT = 0;
					endT = 86400;
				}
				else
				{
					startT = sqlite3_column_int(req_stmt, 3);
					endT = sqlite3_column_int(req_stmt, 4);
				}
				
				uint32_t wkdays = sqlite3_column_int(req_stmt, 5);
				int match = sqlite3_column_int(req_stmt, 6);
				int override = sqlite3_column_int(req_stmt, 7);
				
				if(endT < startT)
				{
					endT += 86400;
				}
				if(match==4) //nonconditional matches
				{
					// construct days
					uint32_t offs = sysDayStart - 86400;
					uint32_t lStartT = startT + offs;
					uint32_t lEndT = endT + offs;
					for(int i=-1; i<2; i++)
					{
						if( wkdays & (1<<((7+locWkDay+i)%7)) )
						{
							// default, any, none
							
							NSLog(@"inserting always match rule %d %d %x", lStartT, lEndT, (override!=2 ? 1<<24 : 2<<24) | prior);
							
							TBinsert(schedRules[override], lStartT, lEndT, prior);
							//TBinsert(sched, lStartT, lEndT, (override!=2 ? 1<<24 : 2<<24) | prior);
							//insertTimeitem(schedule, lStartT, lEndT, (override!=2 ? 1<<24 : 2<<24) | prior);
						}
						lStartT += 86400;
						lEndT += 86400;
					}
					// no need to continue here
//					if(override==2)
					continue;
				}
				NSMutableDictionary *rule_dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
												  [NSNumber numberWithInt: prior] , @"priority",
												  [NSNumber numberWithInt: match], @"match",
												  [NSNumber numberWithBool: override], @"override",
												  [NSNumber numberWithInt: wkdays], @"weekdays",
												  [NSNumber numberWithBool: allDay], @"all_day",
												  [NSNumber numberWithInt: startT], @"start_time",
												  [NSNumber numberWithInt: endT], @"end_time",
												  nil];
				if(match!=4)
				{
					int rule_id = sqlite3_column_int(req_stmt, 0);
					char *filter = "select filter, category, match, string from CPRuleFilters where ruleid = ?";
					sqlite3_stmt *filter_stmt;
					
					NSMutableArray *filters = [[NSMutableArray alloc] init]; 
					if(sqlite3_prepare_v2(db, filter, -1, &filter_stmt, NULL)==SQLITE_OK)
					{
						if(sqlite3_bind_int(filter_stmt, 1, rule_id)==SQLITE_OK)
						{
							while(sqlite3_step(filter_stmt)==SQLITE_ROW)
							{
								NSMutableDictionary *subdict = [[NSMutableDictionary alloc] initWithCapacity: 4];
								
								[subdict setObject: [NSNumber numberWithInt: sqlite3_column_int(filter_stmt, 0)] forKey: @"filter"];
								[subdict setObject: [NSNumber numberWithInt: sqlite3_column_int(filter_stmt, 1)] forKey: @"category"];
								[subdict setObject: [NSNumber numberWithInt: sqlite3_column_int(filter_stmt, 2)] forKey: @"match"];
								[subdict setObject: [NSString stringWithUTF8String: (const char *) sqlite3_column_text(filter_stmt, 3)] forKey: @"string"];
								[filters addObject: subdict];
								[subdict release];
							}
							
						}
						sqlite3_finalize(filter_stmt);
					}
					if([filters count])
						[rule_dict setObject: filters forKey: @"filters"];
					[filters release];
				}
				[rules addObject: rule_dict];
				[rule_dict release];
			}
			sqlite3_finalize(req_stmt);
		}
	}
	
	{
		
		//char *ocSearch_cmd = "select event_id, OccurrenceCache.occurrence_date, (Event.end_date-Event.start_date), event.summary, event.location, event.description from OccurrenceCache inner join event on OccurrenceCache.event_id = event.rowid where OccurrenceCache.day in (?,?)";
		
		// SERIOUSLY?  MEM LEAK!!!
		//timeblk *evtBlk = TBnew();
		
		char *ocSearch_cmd = "select event_id, occurrence_date, end_date - start_date, summary, location, description, OccurrenceCache.calendar_id, availability from OccurrenceCache inner join Event on event_id = Event.rowid where occurrence_start_date is null and (day in (?, ?, ?) or (end_date - start_date) > ?)";
		
		sqlite3_stmt *ocSearch_stmt;
		if(sqlite3_prepare_v2(db, ocSearch_cmd, -1, &ocSearch_stmt, NULL)==SQLITE_OK)
		{
		//	NSLog(@"binding days %d %d %d", ocDayStart-86400, ocDayStart, ocDayStart+86400);
			sqlite3_bind_int(ocSearch_stmt, 1, ocDayStart-86400);
			sqlite3_bind_int(ocSearch_stmt, 2, ocDayStart);
			sqlite3_bind_int(ocSearch_stmt, 3, ocDayStart+86400);
			sqlite3_bind_int(ocSearch_stmt, 4, (locTime % 86400) + 86400);
			while(sqlite3_step(ocSearch_stmt)==SQLITE_ROW)
			{
				uint32_t rowid = sqlite3_column_int(ocSearch_stmt, 0);
				uint32_t startT = sqlite3_column_int(ocSearch_stmt, 1) + ocOffs - sysOffs; //make system
				uint32_t length = sqlite3_column_int(ocSearch_stmt, 2);// ? 86400 : sqlite3_column_int(ocSearch_stmt, 3);
				
//				NSLog(@"EVENT1: %d", rowid);
				
				if(!length)
					continue;
				
				uint32_t endT = startT + length;
				
//				NSLog(@"EVENT2: %d", rowid);
				
				
				if(startT>sysDayStart+86400*2 || endT<sysDayStart)
					continue;
				
				NSLog(@"EVENT: %d", rowid);
				NSLog(@"start=%d end=%d ref=%d", startT, endT, refTime);
				
				NSString *summary, *location, *description;
				{
					{
						const char *str_tmp = (const char*) sqlite3_column_text(ocSearch_stmt, 3);
						summary = str_tmp ? [NSString stringWithUTF8String: str_tmp] : @"";
					}
					{
						const char *str_tmp = (const char*) sqlite3_column_text(ocSearch_stmt, 4);
						location = str_tmp ? [NSString stringWithUTF8String: str_tmp] : @"";
					}
					{
						const char *str_tmp = (const char*) sqlite3_column_text(ocSearch_stmt, 5);
						description = str_tmp ? [NSString stringWithUTF8String: str_tmp] : @"";
					}
				}
				int calendar_id = sqlite3_column_int(ocSearch_stmt, 6);
				int availability = sqlite3_column_int(ocSearch_stmt, 7);
				
				{
					uint32_t evtStyle = styleForEventId(rowid);
					// set to default
					if(!evtStyle)
					{
						evtStyle = 1;
					}
				
					uint32_t evtPriority = priorityForStyle(evtStyle);
					TBinsert(schedEvent, startT, endT, evtPriority);
				}
				
//				NSLog(@"TTIMEITEM: PRE %d", rowid);
//				TBPrint(evtBlk);
				
				for(NSDictionary *row in rules)
				{
					if(ruleMatchesStuff(row, summary, location, description, calendar_id, availability))
					{
						int rOverride = [[row objectForKey: @"override"] intValue];
						int rPrior = [[row objectForKey: @"priority"] intValue];
						NSLog(@"filters on rule with priority %d apply to %d", rPrior, rowid);
						
						int wkdays = [[row objectForKey: @"weekdays"] intValue];
						if([[row objectForKey: @"all_day"] boolValue])
						{
							if(wkdays == 127)
							{
								// matches entire time period, apply to entire event
								//NSLog(@"-1: %d %d %d", 0, (1<<31)-1, 1<<24 | rPrior);
								TBinsert(schedRules[rOverride], startT, endT, rPrior);
								//TBinsert(evtBlk, 0, (uint32_t) (1<<31)-1, 1<<24 | rPrior);
//								insertTimeitem(evtTime, 0, (1<<31)-1, 1<<24 | rPrior);
							}
							else
							{
								int rWkStartT = sysDayStart - (locWkDay+7)*86400;
								
								for(uint32_t i=locWkDay+1; i<locWkDay+14; i++)
								{
									if(wkdays & (1<<(i%7)))
									{
										int rStartT = rWkStartT + 86400*i;
										i++;
										for(; (wkdays & (1<<(i%7))) && i<locWkDay+14; i++)
										{}
										int rEndT = rWkStartT + 86400*i;
										i--;
										
										int stMat = (rStartT > startT ? rStartT : startT);
										int enMat = (rEndT < endT ? rEndT : endT);
										if(stMat < enMat)
										{
//											NSLog(@"matching rule2 %d", [[row objectForKey: @"match"] intValue]);
											switch([[row objectForKey: @"match"] intValue])
											{
												case 0:
													// during
//													NSLog(@"0: %d %d %d", stMat, enMat, 1<<24 | rPrior);
													TBinsert(schedRules[rOverride], stMat, enMat, rPrior);
//													TBinsert(evtBlk, stMat, enMat, 1<<24 | rPrior);
													break;
												case 1:
													// overlapping
//													NSLog(@"1: %d %d %d", 0, (1<<31)-1, 1<<24 | rPrior);
													TBinsert(schedRules[rOverride], startT, endT, rPrior);
//													TBinsert(evtBlk, 0, (uint32_t) (1<<31)-1, 1<<24 | rPrior);
													break;
												case 2:
													// contained
													if(stMat = startT && enMat==endT)
													{
//														NSLog(@"2: %d %d %d", 0, (1<<31)-1, 1<<24 | rPrior);
														TBinsert(schedRules[rOverride], startT, endT, rPrior);
//														TBinsert(evtBlk, 0, (uint32_t) (1<<31)-1, 1<<24 | rPrior);
													}
													break;
//												case 4:
//													NSLog(@"4: %d %d %d", stMat, enMat, 1<<24 | rPrior);
//													TBinsert(evtBlk, stMat, enMat, 1<<24 | rPrior);
//													break;
											}
										}
									}
									
								}
								
							}
						}
						else
						{
							int rWkStartT = sysDayStart - (locWkDay+7)*86400;
							
						//	NSLine();
							for(uint32_t i=locWkDay+1; i<locWkDay+14; i++)
							{
						//		NSLine();
								if(wkdays & (1<<(i%7)))
								{
						//			NSLine();
									NSLog(@"rStartT = %d %d %d", rWkStartT + 86400*i, [[row objectForKey: @"start_time"] intValue], [[row objectForKey: @"end_time"] intValue]);
									int rStartT = rWkStartT + 86400*i;
									int rEndT = rStartT + [[row objectForKey: @"end_time"] intValue];
									rStartT += [[row objectForKey: @"start_time"] intValue];
									
									int stMat = (rStartT > startT ? rStartT : startT);
									int enMat = (rEndT < endT ? rEndT : endT);
							//		NSLine();
							//		NSLog(@"stMat = %d, enMat = %d", stMat, enMat);
									if(stMat < enMat)
									{
							//			NSLine();
							//			NSLog(@"matching rule3 %d", [[row objectForKey: @"match"] intValue]);
										switch([[row objectForKey: @"match"] intValue])
										{
											case 0:
												TBinsert(schedRules[rOverride], stMat, enMat, rPrior);
//												TBinsert(evtBlk, stMat, enMat, 1<<24 | rPrior);
												break;
											case 1:
												TBinsert(schedRules[rOverride], startT, endT, rPrior);
//												TBinsert(evtBlk, 0, (uint32_t) (1<<31)-1, 1<<24 | rPrior);
												break;
											case 2:
												if(stMat = startT && enMat==endT)
												{
													TBinsert(schedRules[rOverride], startT, endT, rPrior);
//													TBinsert(evtBlk, 0, (uint32_t) (1<<31)-1, 1<<24 | rPrior);
												}
												break;
//											case 4:
							//					NSLog(@"4: %d %d %d", stMat, enMat, 1<<24 | rPrior);
//												TBinsert(evtBlk, stMat, enMat, 1<<24 | rPrior);
//												break;
//											default:
							//					NSLog(@"unknown switch");
//												break;
										}
									}
								}
								
							}
						}
					}
				}
				
//				NSLog(@"SCHEDULE: POST %d", rowid);
//				TBPrint(sched);				
				
				//MergeTimeitem_continuous(schedule, evtTime);
				
			}
		}
		else
		{
			NSLine();
			NSLog(@"malformed command");
		}
//		TBdel(evtBlk);
//		evtBlk = 0;
	}
}


void getStylesForStyleID(int _style)
{
	
	int mainSty = -1;
	
	int altSty = -1;
	if(_style > 0)
	{
		char *req = "select main, alt from CPStyles where rowid = ?";
		sqlite3_stmt *req_stmt;
		if(sqlite3_prepare_v2(db, req, -1, &req_stmt, NULL)==SQLITE_OK)
		{
			if(sqlite3_bind_int(req_stmt, 1, _style)==SQLITE_OK)
			{
				int err;
				if((err=sqlite3_step(req_stmt))==SQLITE_ROW)
				{
					//					NSLog(@"Active style is %s", (const char *) sqlite3_column_text(req_stmt, 0));
					mainSty = sqlite3_column_int(req_stmt, 0);
					altSty = sqlite3_column_int(req_stmt, 1);
				}
			}
			sqlite3_finalize(req_stmt);
		}
	}
	
	[_mainDict release];
	[_altDict release];
	_mainDict = nil;
	_altDict = nil;
	
	if(mainSty>0)
	{
		
		char *req = "select sys, ring, text, vm, imail, omail, cal, push from CPStyleRules where rowid = ?";
		
		//char *req = "select * from CPStyleRules where rowid = ?";
		
		sqlite3_stmt *req_stmt;
		if(sqlite3_prepare_v2(db, req, -1, &req_stmt, NULL)==SQLITE_OK)
		{
			if(sqlite3_bind_int(req_stmt, 1, mainSty)==SQLITE_OK)
			{
				int err;
				if((err=sqlite3_step(req_stmt))==SQLITE_ROW)
				{
					//	NSLine();
					_mainDict = [[NSMutableDictionary alloc] initWithCapacity: 9];
					[_mainDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 0)] forKey: @"sys"];
					[_mainDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 1)] forKey: @"ring"];
					[_mainDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 2)] forKey: @"SMSReceived_Alert"];
					[_mainDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 3)] forKey: @"VoicemailReceived"];
					[_mainDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 4)] forKey: @"MailReceived"];
					[_mainDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 5)] forKey: @"MailSent"];
					[_mainDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 6)] forKey: @"CalendarAlert"];
					[_mainDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 7)] forKey: @"UserAlert"];
					
				}
			}
			sqlite3_finalize(req_stmt);
		}
		if(altSty>0 && altSty != mainSty)
		{
			if(sqlite3_prepare_v2(db, req, -1, &req_stmt, NULL)==SQLITE_OK)
			{
				if(sqlite3_bind_int(req_stmt, 1, altSty)==SQLITE_OK)
				{
					int err;
					if((err=sqlite3_step(req_stmt))==SQLITE_ROW)
					{
						_altDict = [[NSMutableDictionary alloc] initWithCapacity: 9];
						[_altDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 0)] forKey: @"sys"];
						[_altDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 1)] forKey: @"ring"];
						[_altDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 2)] forKey: @"SMSReceived_Alert"];
						[_altDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 3)] forKey: @"VoicemailReceived"];
						[_altDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 4)] forKey: @"MailReceived"];
						[_altDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 5)] forKey: @"MailSent"];
						[_altDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 6)] forKey: @"CalendarAlert"];
						[_altDict setObject: [NSNumber numberWithInt: sqlite3_column_int(req_stmt, 7)] forKey: @"UserAlert"];
					}
				}
			}
			sqlite3_finalize(req_stmt);
		}
		else
		{
			_altDict = [_mainDict retain];
		}
	}	
	
}

int PriorityFromSchedule(timeblk *sched, int refTime)
{
	SelLog();
	
	timeblkval *data = sched->data;
	uint32_t idx=data[0].next;
	for(;idx && refTime >= data[idx].endT; idx=data[idx].next)
	{}
	if(idx)
		return data[idx].priority;
	return (1<<31)-1;
}

@implementation RingerStyle

//@synthesize db;

+(RingerStyle *) sharedDatabase
{
	if(!RingerStyle$shared)
	{
		RingerStyle$shared = [[RingerStyle alloc] initWithFile: "/var/mobile/Library/Calendar/Calendar.sqlitedb"];
	}
	return RingerStyle$shared;
}

-(RingerStyle *) initWithFile: (const char *)fname
{
	self = [super init];
	if(sqlite3_open(fname, &db) == SQLITE_OK)
	{
		schedEvent = 0;//ule = 0;
		schedRules = 0;
		NSLog(@"MUTEX is %d", pthread_mutex_init(&mutex, 0));
		pthread_mutex_unlock(&mutex);
		
		char *check_init = "select * from CPStyles";
		sqlite3_stmt *check_stmt;
		if(sqlite3_prepare_v2(db, check_init, -1, &check_stmt, NULL)!=SQLITE_OK)
		{
			return nil;
		}
		
		sqlite3_finalize(check_stmt);
		return self;
	}
	return nil;
}

-(void) refreshCache
{
	NSLog(@"MUTEX0: prelock!");
	pthread_mutex_lock(&mutex);
	NSLog(@"MUTEX0: lock!");
	
	/*
	if(schedule)
	{
		killTimeitem(schedule);
	}
	*/
	if(timer)
	{
		[timer invalidate];
		[timer release];
	}
	[self releaseCached];
	
	[NSObject cancelPreviousPerformRequestsWithTarget: self];
	
	refreshCache();
	
	//
	{
		if(timer)
		{
			[timer release];
			timer = nil;
		}
		GETCLASS(PCPersistentTimer);
		timer = [[$PCPersistentTimer alloc] initWithFireDate: [NSDate dateWithTimeIntervalSinceNow: 86400.0f] serviceIdentifier: @"cpengine.fire" target: self selector: @selector(refreshCache) userInfo: nil];
		
		if(timer)
		{
			[timer scheduleInRunLoop: [NSRunLoop currentRunLoop]];
		}
		if(!timer)
		{
			[self performSelector: @selector(refreshCache) withObject: nil afterDelay: 86400.0f];
			
		//	[timer release];
		}
		
		
	}
	
	[self performSelector: @selector(refreshCache) withObject: nil afterDelay: 86400.0f];
//	timer = [[NSTimer alloc] initWithFireDate: [NSDate dateWithTimeIntervalSinceNow: 86400.0f] interval: 0.0f target: self selector: @selector(refreshCache) userInfo: nil repeats: NO];
	
	NSLog(@"MUTEX0: unlock!");
	pthread_mutex_unlock(&mutex);

}

- (uint32_t) currentModeFromCache
{
	SelLog();
	
	uint32_t refTime = [NSDate timeIntervalSinceReferenceDate];
	NSLog(@"now is %d", refTime);
	NSLine();
//	printTimeitem(schedule);
	if(schedEvent && schedRules)
	{
		uint32_t defaultPrior = priorityForStyle(1);
		
		int priorEvt = PriorityFromSchedule(schedEvent, refTime);
		
		int priorDef = PriorityFromSchedule(schedRules[0], refTime);
		int priorAlw = PriorityFromSchedule(schedRules[1], refTime);
		int priorNev = PriorityFromSchedule(schedRules[2], refTime);
		
		NSLog(@"priorities: %d %d %d %d", priorEvt, priorAlw, priorDef, priorNev);
		
		if(priorEvt==(1<<31)-1)
		{
			int prior = priorAlw;
			if(prior>priorDef)
				prior = priorDef;
			if(prior>priorNev)
				prior = priorNev;
			if(prior==(1<<31)-1)
			{
				NSLog(@"no event or styles currently.");
				return 0;
			}
			else
			{
				uint32_t style = ruleStyleForPriority(prior);
				NSLog(@"current rule style is %d", style);
				return style;	
			}
		}
		else if(priorEvt==defaultPrior)
		{
			int prior = priorAlw;
			if(prior>priorDef)
				prior = priorDef;
			if(prior==(1<<31)-1)
			{
				uint32_t style = styleForPriority(priorEvt);
				NSLog(@"current style is %d", style);
				return style;
			}
			else
			{
				uint32_t style = ruleStyleForPriority(prior);
				NSLog(@"current rule style is %d", style);
				return style;	
			}
		}
		else
		{
			int prior = priorAlw;
			if(prior==(1<<31)-1)
			{
				uint32_t style = styleForPriority(priorEvt);
				NSLog(@"current style is %d", style);
				return style;
			}
			else
			{
				uint32_t style = ruleStyleForPriority(prior);
				NSLog(@"current rule style is %d", style);
				return style;	
			}
		}
		return 0;
	}
	return 0;
}


-(void) releaseCached
{
	[_mainDict release];
	_mainDict = nil;
	[_altDict release];
	_altDict = nil;
}

-(NSDictionary*) mainDict
{
	SelLog();
	if(_mainDict)
	{
		return _mainDict;
	}
	NSLog(@"MUTEX1: prelock!");
	pthread_mutex_lock(&mutex);
	NSLog(@"MUTEX1: lock!");
	
	if(!_mainDict)
	{
		[self getCurrentStyles];//return _mainDict;
	}
	NSLog(@"MUTEX1: unlock!");
	pthread_mutex_unlock(&mutex);
	
	NSLog(@"_mainDict = %x", _mainDict);
	return _mainDict;
}

-(NSDictionary*) altDict
{
	SelLog();
	if(_altDict)
	{
		return _altDict;
	}
	NSLog(@"MUTEX2: prelock!");
	pthread_mutex_lock(&mutex);
	NSLog(@"MUTEX2: lock!");
	if(!_altDict)
	{
		[self getCurrentStyles];
	}
	NSLog(@"MUTEX2: unlock!");
	pthread_mutex_unlock(&mutex);
	
	NSLog(@"_altDict = %x", _mainDict);
	return _altDict;
}


- (void) getCurrentStyles
{
	SelLog();
	
	//[self refreshCache];
	int _style = [self currentModeFromCache];
	
	getStylesForStyleID(_style);
	
	[self performSelector: @selector(releaseCached) withObject: nil afterDelay: 5.0f];
		
	return;
//	[pool release];
}

@end

#ifdef NSF
#undef NSLog(...)
#undef NSF
#endif
#ifdef NSFO
#define NSLog(...)
#endif
