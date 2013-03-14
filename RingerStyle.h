

bool ruleMatchesStuff(NSDictionary* rule, NSString* summary, NSString* location, NSString* description, int calendar_id, int availability);
uint32_t styleForEventId(int eventId);
uint32_t priorityForStyle(int styleID);
uint32_t styleForPriority(int priority);
uint32_t ruleStyleForPriority(int priority);



@interface RingerStyle : NSObject
{
}

+(RingerStyle *) sharedDatabase;
-(RingerStyle *) initWithFile: (const char *)fname;


-(void) refreshCache;
-(void) releaseCached;

-(NSDictionary*) mainDict;
-(NSDictionary*) altDict;

- (uint32_t) currentModeFromCache;
- (void) getCurrentStyles;


@end
