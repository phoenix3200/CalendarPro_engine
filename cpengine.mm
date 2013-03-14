//
//  CalendarPro.mm
//  CalendarPro
//
//  Created by Public Nuisance on 7/19/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//
//  MobileSubstrate, libsubstrate.dylib, and substrate.h are
//  created and copyrighted by Jay Freeman a.k.a saurik and 
//  are protected by various means of open source licensing.
//
//  Additional defines courtesy Lance Fetters a.k.a ashikase
//


// #define TESTING

#import "common.h"
#import "defines.h"

#import "cpengine.h"
#import "RingerStyle.h"


using namespace std;

extern bool isSpringBoard;

#ifdef FILE_LOG
#ifndef NSLog(...)
#define NSF
#else
#define NSFO
#endif
#define NSLog(args...) FLog(args)
#endif


int (*gRingerActiveCached);
int (*gCMSM);
uint8_t (*gCMSM1);
uint8_t (*gCMSM2);

bool (*cmsmGetRingerSwitchState)(bool reload);
bool (*__cmsmGetRingerSwitchState)(bool reload);



bool _cmsmGetRingerSwitchState(bool reload)
{
	SelLog();
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSLog(@"bool is %d, setting to 0", reload);
	
	NSLog(@"__cmsmGetRingerSwitchState = %x %x", cmsmGetRingerSwitchState, __cmsmGetRingerSwitchState);
	
	bool ret = __cmsmGetRingerSwitchState(0);//reload);
	
	NSLog(@"Completed original, original return %d", ret);
	
	
	NSDictionary *dict = nil;
	
	if(RingerStyle *sharedDB = [RingerStyle sharedDatabase])
	{
		if(ret)
		{
			NSLog(@"retrieving main dict");
			dict = [sharedDB mainDict];
		}
		else
		{
			NSLog(@"retrieving alt dict");
			dict = [sharedDB altDict];
		}
	}
	
	int mode = dict ? [[dict objectForKey: @"sys"] intValue] : 0;
	
	NSLog(@"current mode is %d", mode);
	
	if(!dict || mode==4)
	{
		NSLog(@"using defaults");
		NSDictionary *sbdict = [[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.springboard"];
		
		if(gCMSM1)
		{
			NSNumber* rv = [sbdict objectForKey: @"ring-vibrate"];
			*gCMSM1 = rv ? [rv boolValue] : 1; //catch-all if it isn't set
			NSNumber* sv = [sbdict objectForKey: @"silent-vibrate"];
			*gCMSM2 = sv ? [sv boolValue] : 1; //[[sbdict objectForKey: @"silent-vibrate"] boolValue];
			
		//	((uint8_t *)gCMSM)[0x24] = [[sbdict objectForKey: @"ring-vibrate"] boolValue];
		//	((uint8_t *)gCMSM)[0x25] = [[sbdict objectForKey: @"silent-vibrate"] boolValue];
		//	((uint8_t *)gCMSM)[0x2C] = [[sbdict objectForKey: @"ring-vibrate"] boolValue];
		//	((uint8_t *)gCMSM)[0x2E] = [[sbdict objectForKey: @"silent-vibrate"] boolValue];
		}
		NSLog(@"setting %d %d, returning %d", *gCMSM1, *gCMSM2, ret);
		return ret;
	}
	
	if(mode & 2)
	{
		ret = YES;
	}
	else
	{
		ret = NO;
	}
	if(mode & 1)
	{
		NSLog(@"setting to vibrate");
		if(gCMSM1)
		{
			*gCMSM1 = YES;
			*gCMSM2 = YES;
		//	((uint8_t *)gCMSM)[0x2C] = YES;
		//	((uint8_t *)gCMSM)[0x2E] = YES;
		}
	}
	else
	{
		NSLog(@"setting to not vibrate");
		if(gCMSM1)
		{
			*gCMSM1 = NO;
			*gCMSM2 = NO;
			//((uint8_t *)gCMSM)[0x2C] = NO;
			//((uint8_t *)gCMSM)[0x2E] = NO;
		}
	}
	
	[pool release];
	NSLog(@"setting %d %d, returning %d", *gCMSM1, *gCMSM2, ret);
//	NSLog(@"Returning ringer switch state = %d", ret);
//	NSLog(@"RingerSwitchState %x %x %x %x", *gRingerActiveCached, ret, (uint32_t) ((uint8_t *)gCMSM)[0x24],  (uint32_t) ((uint8_t *)gCMSM)[0x25]);
	return ret;
}

/*
NSDictionary* (*CelestialCFCreatePropertyList)(NSString *plist);

NSDictionary* (*__CelestialCFCreatePropertyList)(NSString *plist);

NSDictionary* _CelestialCFCreatePropertyList(NSString *plist)
{
	SelLog();
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSLog(@"plist is %@", plist);
	id ret = __CelestialCFCreatePropertyList(plist);
	
	if([plist isEqualToString: @"CategoriesThatShareVolumes.plist"])
	{
		NSMutableDictionary *dict2 = [[NSMutableDictionary alloc] initWithDictionary: ret];
		[dict2 setObject: @"Ringtone" forKey: @"Meh"];
		[ret release];
		
		[pool release];
		return dict2;
	}
	[pool release];
	return ret;//dict2;
}
*/

unsigned long (*cmsmSystemSoundShouldPlayGutsGuts)(const NSString *category, unsigned char argR1, unsigned char argR2, float *argR3, float *sp0, const NSString **sp4);

unsigned long (*__cmsmSystemSoundShouldPlayGutsGuts)(const NSString *category, unsigned char argR1, unsigned char argR2, float *argR3, float *sp0, const NSString **sp4);

unsigned long (*cmsmSystemSoundShouldPlayGutsGuts2)(unsigned char argR0, const NSString* category, unsigned char argR2, unsigned char argR3, unsigned char sp0, float* sp1, float* sp2, const NSString** sp3);

unsigned long (*__cmsmSystemSoundShouldPlayGutsGuts2)(unsigned char argR0, const NSString* category, unsigned char argR2, unsigned char argR3, unsigned char sp0, float* sp1, float* sp2, const NSString** sp3);

int CustomBehaviorForCategory(const NSString *category)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	bool rs = __cmsmGetRingerSwitchState(YES);
	
	NSLog(@"category = %@", category);
	
	NSDictionary *dict = nil;
	if(RingerStyle *sharedDB = [RingerStyle sharedDatabase])
	{
		if(rs)
		{
			dict = [sharedDB mainDict];
		}
		else
		{
			dict = [sharedDB altDict];
		}
	}
	
	int ret = -1;
	if(dict)
	{
		if(NSNumber *val = [dict objectForKey: category])
		{
			switch([val intValue])
			{
				case 0:
					NSLog(@"setting to silent");
					ret = 0;
					break;
				case 1:
					NSLog(@"setting to vib");
					ret = 2;
					break;
				case 2:
					NSLog(@"setting to ring");
					ret = 1;
					break;
				case 3:
					NSLog(@"setting to full");
					ret = 3;
					break;
					
			}
		}
	}
	[pool release];
	NSLog(@"returning tuned value of %d", ret);

	/*
	 NSLog(@"category is %@", category);
	 if([category isEqualToString: @"RingerSwitchIndication"])
	 return 2;
	 if([category isEqualToString: @"ConnectedToPower"])
	 return 1;
	 */
	// 0 = nada
	// 1 = ring
	// 2 = vibr
	// 3 = both
	return ret;
}

unsigned long _cmsmSystemSoundShouldPlayGutsGuts2(unsigned char argR0, const NSString* category, unsigned char argR2, unsigned char argR3, unsigned char sp0, float* sp1, float* sp2, const NSString** sp3)
{
	SelLog();
	_cmsmGetRingerSwitchState(NO); // why do we need to update BEFORE?
	unsigned long ret = __cmsmSystemSoundShouldPlayGutsGuts2(argR0, category, argR2, argR3, sp0, sp1, sp2, sp3);
	NSLog(@"Standard returned %x for category %@", ret, category);
	
//	return 0;
	
	int behavior;
	if((behavior = CustomBehaviorForCategory(category))>=0)
		return behavior;
	return ret;
}

unsigned long _cmsmSystemSoundShouldPlayGutsGuts(const NSString *category, unsigned char argR1, unsigned char argR2, float *argR3, float *sp0, const NSString **sp4)
{
	SelLog();
	_cmsmGetRingerSwitchState(NO); // why do we need to update BEFORE?
	unsigned long ret = __cmsmSystemSoundShouldPlayGutsGuts(category, argR1, argR2, argR3, sp0, sp4);
	NSLog(@"Standard returned %x for category %@", ret, category);
	int behavior;
	if((behavior = CustomBehaviorForCategory(category))>=0)
		return behavior;
	return ret;
}


@class SBCallAlertDisplay;
@class AVController;

NSString *AVController_AudioCategoryAttribute = @"AVController_AudioCategoryAttribute";


HOOKDEF(NSObject*, AVController, attributeForKey$, NSObject* key);

HOOK(NSObject*, AVController, attributeForKey$, NSObject* key)
{
	NSObject* attribute = CALL_ORIG(AVController, attributeForKey$, key);
	if([(NSString*)key isEqualToString: AVController_AudioCategoryAttribute] && [(NSString*)attribute isEqualToString: @"RingtonePreview"])
	{
		return @"Ringtone";
	}
	return attribute;
}

HOOKDEF(void, AVController, setAttribute$forKey$error$, NSObject* attribute, NSObject* key, void *err);

HOOK(void, AVController, setAttribute$forKey$error$, NSObject* attribute, NSObject* key, void *err)
{
	HookLog();
	
	if([(NSString*)key isEqualToString: AVController_AudioCategoryAttribute] && [(NSString*)attribute isEqualToString: @"Ringtone"])
	{
		NSLog(@"modifying category to meh");
		CALL_ORIG(AVController, setAttribute$forKey$error$, @"RingtonePreview", key, err);
	}
	else
	{
		CALL_ORIG(AVController, setAttribute$forKey$error$, attribute, key, err);
	}
}

bool (*RingerState)();
bool (*__RingerState)();

bool RingerStateCheck(int ret)
{
	NSDictionary *dict = nil;
	if(RingerStyle *sharedDB = [RingerStyle sharedDatabase])
	{
		if(ret)
		{
			dict = [sharedDB mainDict];
		}
		else
		{
			dict = [sharedDB altDict];
		}
	}
	
	int mode = 4;
	
	if(dict)
	{
		id sys = [dict objectForKey: @"sys"];
		if(sys)
		{
			mode = [sys intValue];
		}
	}
	//dict ? [[dict objectForKey: @"sys"] intValue] : 4;
	NSDesc(dict);
	
	if(!dict || mode==4)
	{
		NSLog(@"current mode is missing, returning %d", ret);
		return ret;
	}
	NSLog(@"current mode is %d", mode);
	
	return (mode & 2) ? 1 : 0;
}

bool __TrueRingerState()
{
	int token = 0;
	uint64_t value;
	
	notify_register_check("com.apple.springboard.ringerstate", &token);
	notify_get_state(token, &value);
	return (uint32_t) value;
}


bool _RingerState()
{
	SelLog();
	int ret = __TrueRingerState();
	NSLog(@"original state=%d", ret);
	ret = RingerStateCheck(ret);
	NSLog(@"returning state=%d", ret);
	return ret;
	/*
	NSDictionary *dict = nil;
	if(RingerStyle *sharedDB = [RingerStyle sharedDatabase])
	{
		if(ret)
		{
			dict = [sharedDB mainDict];
		}
		else
		{
			dict = [sharedDB altDict];
		}
	}
	
	int mode = dict ? [[dict objectForKey: @"sys"] intValue] : 0;
	
	NSDesc(dict);
	
	
	if(!dict || mode==4)
	{
		NSLog(@"current mode is missing, returning %d", ret);
		return ret;
	}
	NSLog(@"current mode is %d", mode);
	
	return (mode & 2);
	*/
}

@class SpringBoard;

HOOKDEF(void, SpringBoard, ringerChanged$, int ringerSetting);

HOOK(void, SpringBoard, ringerChanged$, int ringerSetting)
{
//	[self fail];
	SelLog();
	
	CALL_ORIG(SpringBoard, ringerChanged$, RingerStateCheck(ringerSetting));
	return;
	
	/*
	if(void* dl = dlopen(CoreMedia, RTLD_NOW))
	{
		if(dlsym(dl, "kCMSession_RouteDescriptionKey_PortPassword"))
		{
		}
	}
	
	CALL_ORIG(SpringBoard, ringerChanged$, RingerState());
	/ *
	HookLog();
	NSLog(@"ringerSetting = %d, changing to %d", ringerSetting, RingerStateCheck(ringerSetting));//RingerState());
	*/
	
}

@class AVQueue, SBSoundPreferences;

HOOKDEF(void, AVController, play$, id dc);

HOOK(void, AVController, play$, id dc)
{
	HookLog();
	
	int ret = __TrueRingerState();
	
	NSDictionary *dict = nil;
	if(RingerStyle *sharedDB = [RingerStyle sharedDatabase])
	{
		if(ret)
		{
			NSLog(@"grabbing normal dict");
			dict = [sharedDB mainDict];
		}
		else
		{
			NSLog(@"grabbing alt dict");
			dict = [sharedDB altDict];
		}
	}
	
	NSDesc(dict);
	
	int sys = dict ? [[dict objectForKey: @"sys"] intValue] : 4;
	int ring = dict ? [[dict objectForKey: @"ring"] intValue] : 4;
	
	if(sys==4)
	{
	}
	else if(sys & 2)
	{
		ret = YES;
	}
	else
	{
		ret = NO;
	}
	
	if(ring==4)
	{
	}
	else if(ring & 2)
	{
		ret = YES;
	}
	else
	{
		ret = NO;
	}
	
	
	AVQueue *oldQueue = nil;
	NSLog(@"attribute is %@", [self attributeForKey: AVController_AudioCategoryAttribute]);
	if(!ret && [[self attributeForKey: AVController_AudioCategoryAttribute] isEqualToString: @"Ringtone"])
		oldQueue = [[self queue] retain];
	if(oldQueue)
	{
		NSLog(@"silencing the ringtone");
		[self setQueue: nil];
	}
	CALL_ORIG(AVController, play$, dc);
	if(oldQueue)
	{
		[self setQueue: oldQueue];
		[oldQueue release];
	}
}


@class SBSoundPreferences;

HOOKDEF(bool, SBSoundPreferences, shouldVibrateForCurrentRingerState);
HOOKDEF(bool, SBSoundPreferences, vibrateWhenSilent);
HOOKDEF(bool, SBSoundPreferences, vibrateWhenRinging);

HOOK(bool, SBSoundPreferences, shouldVibrateForCurrentRingerState)
{
	HookLog();
	return CALL_ORIG(SBSoundPreferences, shouldVibrateForCurrentRingerState);
}

HOOK(bool, SBSoundPreferences, vibrateWhenSilent)
{
	HookLog();
	
	bool ret = CALL_ORIG(SBSoundPreferences, vibrateWhenSilent);
	
	int rs = __TrueRingerState();
	
	NSDictionary *dict = nil;
	if(RingerStyle *sharedDB = [RingerStyle sharedDatabase])
	{
		if(rs)
		{
			dict = [sharedDB mainDict];
		}
		else
		{
			dict = [sharedDB altDict];
		}
	}
	
	int sys = dict ? [[dict objectForKey: @"sys"] intValue] : 4;
	int ring = dict ? [[dict objectForKey: @"ring"] intValue] : 4;
	
	if(sys==4)
	{
	}
	else if(sys & 1)
	{
		ret = YES;
	}
	else
	{
		ret = NO;
	}
	
	if(ring==4)
	{
	}
	else if(ring & 1)
	{
		ret = YES;
	}
	else
	{
		ret = NO;
	}
	
	/*
	NSDictionary *dict = nil;
//	dict = currDict();

	if(RingerStyle *sharedDB = [RingerStyle sharedDatabase])
	{
		dict = [sharedDB altDict];
	}
	
	int sys = dict ? [[dict objectForKey: @"sys"] intValue] : 4;
	int ring = dict ? [[dict objectForKey: @"ring"] intValue] : 4;
	
	
	if(sys==4)
	{
	}
	else if(sys & 1)
	{
		ret = YES;
	}
	else
	{
		ret = NO;
	}
	
	if(ring==4)
	{
	}
	else if(ring & 1)
	{
		ret = YES;
	}
	else
	{
		ret = NO;
	}
	*/
	
	return ret;
//	return CALL_ORIG(SBSoundPreferences, vibrateWhenSilent);
}

HOOK(bool, SBSoundPreferences, vibrateWhenRinging)
{
	HookLog();
	bool ret = CALL_ORIG(SBSoundPreferences, vibrateWhenRinging);
	
	NSDictionary *dict = nil;
//	dict = currDict();
	
	int rs = __TrueRingerState();
	
//	NSDictionary *dict = nil;
	if(RingerStyle *sharedDB = [RingerStyle sharedDatabase])
	{
		if(rs)
		{
			dict = [sharedDB mainDict];
		}
		else
		{
			dict = [sharedDB altDict];
		}
	}
	
	int sys = dict ? [[dict objectForKey: @"sys"] intValue] : 4;
	int ring = dict ? [[dict objectForKey: @"ring"] intValue] : 4;
	
	if(sys==4)
	{
	}
	else if(sys & 1)
	{
		ret = YES;
	}
	else
	{
		ret = NO;
	}
	
	if(ring==4)
	{
	}
	else if(ring & 1)
	{
		ret = YES;
	}
	else
	{
		ret = NO;
	}
	/*
	
	if(RingerStyle *sharedDB = [RingerStyle sharedDatabase])
	{
		dict = [sharedDB mainDict];
	}

	int sys = dict ? [[dict objectForKey: @"sys"] intValue] : 4;
	int ring = dict ? [[dict objectForKey: @"ring"] intValue] : 4;
	
	if(sys==4)
	{
	}
	else if(sys & 1)
	{
		ret = YES;
	}
	else
	{
		ret = NO;
	}
	
	if(ring==4)
	{
	}
	else if(ring & 1)
	{
		ret = YES;
	}
	else
	{
		ret = NO;
	}
	*/
	return ret;
}

extern "C" bool MSDebug;



@class SBCalendarController, SoundController, VoicemailNavigationController;

//extern "C" void AudioServicesPlaySystemSound(int soundIdx);
/*
HOOKDEF(void, SBCalendarController, playAlertSound);

HOOK(void, SBCalendarController, playAlertSound)
{
	GETCLASS(SBSoundPreferences);
	if([[$SBSoundPreferences calendarAlarmPath] length])
	{
		AudioServicesPlaySystemSound(0x3ed);
	}
	else
	{
		NSDictionary *dict = nil;
		
		dict = currDict();

		if(dict && [[dict objectForKey: @"CalendarAlert"] intValue] !=4)
		{
			AudioServicesPlaySystemSound(0x3ed);
		}
	}
}


HOOKDEF(void, SoundController, playNewMailSound);
HOOKDEF(void, SoundController, playSentMailSound);

HOOK(void, SoundController, playNewMailSound)
{
	if([self _shouldPlaySound: @"PlayNewMailSound"])
	{
		AudioServicesPlaySystemSound(0x3e8);
	}
	else
	{
		NSDictionary *dict = nil;
		dict = currDict();
		
		
		if(dict && [[dict objectForKey: @"MailReceived"] intValue] !=4)
		{
			AudioServicesPlaySystemSound(0x3e8);
		}
	}
}

HOOK(void, SoundController, playSentMailSound)
{
	if([self _shouldPlaySound: @"PlaySentMailSound"])
	{
		AudioServicesPlaySystemSound(0x3e9);
	}
	else
	{
		NSDictionary *dict = nil;
		dict = currDict();

		if(dict && [[dict objectForKey: @"MailSent"] intValue] !=4)
		{
			AudioServicesPlaySystemSound(0x3e9);
		}
	}
}

HOOKDEF(void, VoicemailNavigationController, playVoicemailSound);

HOOK(void, VoicemailNavigationController, playVoicemailSound)
{
	NSDictionary *sbdict = [[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.springboard"];
	if([[sbdict objectForKey: @"VoicemailToneEnabled"] boolValue])
	{
		AudioServicesPlaySystemSound(0x3ea);
	}
	else
	{
		NSDictionary *dict = nil;
		dict = currDict();

		if(dict && [[dict objectForKey: @"VoicemailReceived"] intValue] !=4)
		{
			AudioServicesPlaySystemSound(0x3e9);
		}
	}
}
*/
#pragma mark dylib initialization and initial hooks
#pragma mark 

bool isSpringBoard;

void DatabaseChanged()
{
	NSLog(@"callback called!1111 %x", pthread_self());
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	RingerStyle *shared = [RingerStyle sharedDatabase];
	[NSObject cancelPreviousPerformRequestsWithTarget: shared];
	[[RingerStyle sharedDatabase] performSelector: @selector(refreshCache) withObject: nil afterDelay: 5.0f];
	[pool release];

//	
	/*
	 NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	if(NSDictionary *staticDict = [standardUserDefaults volatileDomainForName: @"com.phoenix.cpengine.volatile"])
	{
		NSLog(@"volatile!1111 %d", [[staticDict objectForKey: @"date"] intValue]);
	}
	for(NSString *names in [standardUserDefaults volatileDomainNames])
	{
		NSLog(@"volatileDomain 1111 %@", names);
	}	
	*/
}



@class SBMediaController;

HOOKDEF(BOOL, SBMediaController, isRingerMuted)
{
	bool muted = CALL_ORIG(SBMediaController, isRingerMuted);
	
	return !RingerStateCheck(!muted);
}



HOOKDEF(void, SpringBoard, _updateRingerStateWithVisuals$, bool visuals)
{
	/*
	{
		Dl_info info;
		void* addr = __builtin_return_address(0);
		dladdr(addr, &info);
		NSLog(@"%08x = %08x + %08x + %08x %s\t%s",
			(uint32_t) addr,
			info.dli_fbase,
			(uint32_t) info.dli_saddr,
			(uint32_t) addr - (uint32_t) info.dli_saddr - (uint32_t) info.dli_fbase,
			info.dli_sname, info.dli_fname);
	}
	*/
	
	
	//if(state != [si isRingerMuted])
	if(CFPreferencesGetAppBooleanValue((CFStringRef) @"SBUseHardwareSwitchAsOrientationLock", kCFPreferencesCurrentApplication, NULL))
	{
		CALL_ORIG(SpringBoard, _updateRingerStateWithVisuals$, visuals);
	}
	else
	{
		bool state = __RingerState();
		GETCLASS(SBMediaController);
		id si = [$SBMediaController sharedInstance];
		NSLog(@"setting state = %d", state);
		
		//bool diff = (state == (bool) [si isRingerMuted]);
		[si setRingerMuted: !state];
			
		//if(diff)
		{	
			GETCLASS(SBRingerHUDController);
			[$SBRingerHUDController activate: RingerStateCheck(state)];
		}
		
		
		
	}
	
	//CALL_ORIG(SpringBoard, _updateRingerStateWithVisuals$, visuals);
	/*
//	
	{
		if([[$SBMediaController sharedInstance] isRingerMuted]
		RingerState();
	}
	*/
}

void* NextFunctionCall(void* offset)
{
	void *vibCheck = offset;
	if(vibCheck)
	{
		if((uint32_t)vibCheck & 0x1)
		{

			(uint32_t)vibCheck &= ~0x1;
			int i;
			uint16_t pt1, pt2;
			pt2 = *((uint16_t *) vibCheck);
			for(i=0; i<0x10; i++)
			{
				pt1 = pt2;
				((uint32_t)vibCheck)+=2;
				pt2 = *((uint16_t *) vibCheck);
				if((pt1 & 0xF800) == 0xF000 && (pt2 & 0xF800) == 0xE800)
					break;
			}
			if(i!=0x10)
			{
				int offs = (pt1 & 0x400) ? 0xFFC00000 : 0x00000000;
				offs |= (pt1 & 0x3FF) << (4*3);
				offs |= (pt2 & 0x7FF) << 1;

				return (void *)(uint32_t)(offs + (uint32_t)vibCheck);
			}
		}
	}
	return 0;
}


void SpringBoardInitialize()
{
	GETCLASS(AVController);
	HOOKMESSAGE(AVController, setAttribute:forKey:error:, setAttribute$forKey$error$);
	HOOKMESSAGE(AVController, attributeForKey:, attributeForKey$);
	
	HOOKMESSAGE(AVController, play:, play$);
	
	GETCLASS(SBSoundPreferences);
	HOOKCLASSMESSAGE(SBSoundPreferences, shouldVibrateForCurrentRingerState, shouldVibrateForCurrentRingerState);
	HOOKCLASSMESSAGE(SBSoundPreferences, vibrateWhenSilent, vibrateWhenSilent);
	HOOKCLASSMESSAGE(SBSoundPreferences, vibrateWhenRinging, vibrateWhenRinging);
	
	//Method method =class_getInstanceMethod($SBSoundPreferences, @selector(shouldVibrateForCurrentRingerState));
	
	//GETCLASS(SpringBoard);
	
	
	
	GETCLASS(SBMediaController);
	HOOKMESSAGE(SBMediaController, isRingerMuted, isRingerMuted);
	//__RingerState = (MSHookMessage($SBMediaController, @selector(isRingerMuted), _RingerState);
	
	
	GETCLASS(SpringBoard);
	HOOKMESSAGE(SpringBoard, ringerChanged:, ringerChanged$);
	HOOKMESSAGE(SpringBoard, _updateRingerStateWithVisuals:, _updateRingerStateWithVisuals$);
	
	if(_SpringBoard$_updateRingerStateWithVisuals$)
	{
		__RingerState = (bool(*)()) NextFunctionCall((void *)_SpringBoard$_updateRingerStateWithVisuals$);
		
		if(__RingerState)
		{
			__RingerState = (bool(*)()) (uint32_t) (((uint32_t) __RingerState + 3) & ~0x3);
		}
		/*
		//NSLog(@"hooking at %x", __RingerState);
		{
			Dl_info info;
			//for(int i=0; i<4; i++)
			{
				void* addr = (void*) __RingerState;
				dladdr(addr, &info);
				NSLog(@"%d: %08x = %08x + %08x + %08x %s\t%s",
					0,
					(uint32_t) addr,
					info.dli_fbase,
					(uint32_t) info.dli_saddr,
					(uint32_t) addr - (uint32_t) info.dli_saddr - (uint32_t) info.dli_fbase,
					info.dli_sname, info.dli_fname);
			}
		}
		*/
		//RS2 = (bool(*)()) 
		
		//NSLog(@"hooking at %x", RS2);
		//5b046 - 0x7000
		//MSHookFunction((void *)RS2, (void *)&_RS2, (void **)&__RS2);
	}
	else
	{
	
	//HOOKMESSAGE(SBMediaController, isRingerMuted, isRingerMuted);
		void *vibCheck = (void *)_SBSoundPreferences$shouldVibrateForCurrentRingerState;
		RingerState = (bool(*)()) NextFunctionCall((void *)_SBSoundPreferences$shouldVibrateForCurrentRingerState);
		MSHookFunction((void *)RingerState, (void *)&_RingerState, (void **)&__RingerState);
		
		/*
		if(vibCheck)
		{
			if((uint32_t)vibCheck & 0x1)
			{

				(uint32_t)vibCheck &= ~0x1;
				int i;
				uint16_t pt1, pt2;
				pt2 = *((uint16_t *) vibCheck);
				for(i=0; i<0x10; i++)
				{
					pt1 = pt2;
					((uint32_t)vibCheck)+=2;
					pt2 = *((uint16_t *) vibCheck);
					if((pt1 & 0xF800) == 0xF000 && (pt2 & 0xF800) == 0xE800)
						break;
				}
				if(i!=0x10)
				{
					int offs = (pt1 & 0x400) ? 0xFFC00000 : 0x00000000;
					offs |= (pt1 & 0x3FF) << (4*3);
					offs |= (pt2 & 0x7FF) << 1;

					void *addr = (void *)(uint32_t)(offs + (uint32_t)vibCheck);
					RingerState = ((bool(*)())addr);
					NSLog(@"hooking ringerState: %p", addr);
					MSHookFunction((void *)RingerState, (void *)&_RingerState, (void **)&__RingerState);
				}
			}
		}*/
	}
	
}

void MediaserverdIntialize()
{
	struct nlist nl[9];
	memset(nl, 0, sizeof(nl));
	
	NSLine();
	/*
	nl[0].n_un.n_name = (char *) "__ZL19gRingerActiveCached";
	nl[1].n_un.n_name = (char *) "__ZL24cmsmGetRingerSwitchStateh";
	nl[2].n_un.n_name = (char *) "__ZL5gCMSM";
	nl[3].n_un.n_name = (char *) "__ZL33cmsmSystemSoundShouldPlayGutsGutsPK10__CFStringhhPfS2_PS1_";
	nl[4].n_un.n_name = (char *) "__ZL33cmsmSystemSoundShouldPlayGutsGutshPK10__CFStringhhhPfS2_PS1_";
	*/
	nl[0].n_un.n_name = (char *) "_gRingerActiveCached";
	nl[1].n_un.n_name = (char *) "_cmsmGetRingerSwitchState";
	nl[2].n_un.n_name = (char *) "_gCMSM";
	nl[3].n_un.n_name = (char *) "_cmsmSystemSoundShouldPlayGutsGuts";
//	nl[4].n_un.n_name = (char *) "__ZL33cmsmSystemSoundShouldPlayGutsGutshPK10__CFStringhhhPfS2_PS1_";
	NSLine();
	
//	nl[4].n_un.n_name = (char *) "_gRingerActiveCached";
//	nl[5].n_un.n_name = (char *) "_cmsmGetRingerSwitchState";
//	nl[6].n_un.n_name = (char *) "_gCMSM";
//	nl[7].n_un.n_name = (char *) "_cmsmSystemSoundShouldPlayGutsGuts";
	
	//		nl[4].n_un.n_name = (char *) "_CelestialCFCreatePropertyList";
	
	
	nlist(CoreMedia, nl);
	
	nlset(gRingerActiveCached, nl, 0);
	NSLog(@"gRingerActiveCached = %x", gRingerActiveCached);
	NSLine();
	nlset(cmsmGetRingerSwitchState, nl, 1);
	NSLog(@"cmsmGetRingerSwitchState = %x", cmsmGetRingerSwitchState);
	NSLine();
	nlset(gCMSM, nl, 2);
	NSLog(@"gCMSM0 = %x", gCMSM);
	//NSLine();
	cmsmSystemSoundShouldPlayGutsGuts = NULL;
	nlset(cmsmSystemSoundShouldPlayGutsGuts2, nl, 3);
	NSLog(@"cmsmSystemSoundShouldPlayGutsGuts = %x", cmsmSystemSoundShouldPlayGutsGuts);
	
//	nlset(cmsmSystemSoundShouldPlayGutsGuts2, nl, 4);
	
	/*
	NSLine();
	if(!gRingerActiveCached)
	{
		NSLine();
		nlset(gRingerActiveCached, nl, 4);
	}
	NSLine();
	if(!cmsmGetRingerSwitchState)
	{
		NSLine();
		nlset(cmsmGetRingerSwitchState, nl, 5);
	}
	NSLine();
	if(!gCMSM);
	{
		NSLine();
		nlset(gCMSM, nl, 6);
		NSLog(@"gCMSM = %x", gCMSM);
	}
	NSLog(@"gCMSM2 = %x", gCMSM);
	NSLine();
	if(!cmsmSystemSoundShouldPlayGutsGuts)
	{
		NSLine();
		nlset(cmsmSystemSoundShouldPlayGutsGuts, nl, 7);
	}
	NSLine();
	*/
	
	//		nlset(CelestialCFCreatePropertyList, nl, 4);
	
	if(gRingerActiveCached)
	{
		NSLog(@"gRingerActiveCached %x %x", gRingerActiveCached, *gRingerActiveCached);
	}
	if(gCMSM)
	{
		//NSLog(@"gCMSM %x %x %x", gCMSM, (uint32_t) ((uint8_t *)gCMSM)[0x2C],  (uint32_t) ((uint8_t *)gCMSM)[0x2E]);
		
		gCMSM1 = &((uint8_t *)gCMSM)[0x24];
		gCMSM2 = &((uint8_t *)gCMSM)[0x25];
		
		if(void* dl = dlopen(CoreMedia, RTLD_NOW))
		{
			if(dlsym(dl, "kCMSessionGlobalNotification_ActiveAudioRouteWillChange"))
			{
				gCMSM1 = &((uint8_t *)gCMSM)[0x30];
				gCMSM2 = &((uint8_t *)gCMSM)[0x32];
			}
			else if(dlsym(dl, "kCMSession_RouteDescriptionKey_PortPassword"))
			{
				// 4.2.+
				NSLog(@"running on 4.2+");
				gCMSM1 = &((uint8_t *)gCMSM)[0x2C];
				gCMSM2 = &((uint8_t *)gCMSM)[0x2E];
			}
			
		}
	}
	else
	{
		gCMSM1 = 0;
		gCMSM2 = 0;
	}
	if(cmsmGetRingerSwitchState)
	{
		NSLog(@"cmsmGetRingerSwitchState %x", cmsmGetRingerSwitchState);
		
		//MSDebug = 1;
		MSHookFunction((void *)cmsmGetRingerSwitchState, (void *)&_cmsmGetRingerSwitchState, (void **)&__cmsmGetRingerSwitchState);
		//MSDebug = 0;
	}
	
	/*
	 if(CelestialCFCreatePropertyList)
	 {
	 NSLine();
	 MSHookFunction((void *)CelestialCFCreatePropertyList, (void *)&_CelestialCFCreatePropertyList, (void **)&__CelestialCFCreatePropertyList);
	 }
	 */
	
	if(cmsmSystemSoundShouldPlayGutsGuts)
	{
		NSLog(@"cmsmSystemSoundShouldPlayGutsGuts %x", cmsmSystemSoundShouldPlayGutsGuts);
		NSLine();
		MSHookFunction((void *)cmsmSystemSoundShouldPlayGutsGuts, (void *)&_cmsmSystemSoundShouldPlayGutsGuts, (void **)&__cmsmSystemSoundShouldPlayGutsGuts);
	}
	if(cmsmSystemSoundShouldPlayGutsGuts2)
	{
		NSLog(@"cmsmSystemSoundShouldPlayGutsGuts2 %x", cmsmSystemSoundShouldPlayGutsGuts2);
		NSLine();
		MSHookFunction((void *)cmsmSystemSoundShouldPlayGutsGuts2, (void *)&_cmsmSystemSoundShouldPlayGutsGuts2, (void **)&__cmsmSystemSoundShouldPlayGutsGuts2);
	}
}


__attribute__((constructor)) void load()
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	
	NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    NSLine();
	
		
	if ([identifier isEqualToString:@"com.apple.springboard"])
	{
		NSLine();
		isSpringBoard = TRUE;
		SpringBoardInitialize();
	}
	else if(dlopen(CoreMedia, RTLD_LAZY | RTLD_NOLOAD) != NULL)
	{
		NSLine();
		isSpringBoard = FALSE;
		
		MediaserverdIntialize();
	}
	else
	{
		NSLine();
	}
//	[[RingerStyle sharedDatabase] performSelectorInBackground: @selector(refreshCache) withObject: nil];
	[[RingerStyle sharedDatabase] performSelector: @selector(refreshCache) withObject: nil afterDelay: 0.0f];
	
	{
		CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
		CFNotificationCenterAddObserver(darwin, NULL, (CFNotificationCallback) DatabaseChanged, (CFStringRef) @"_CPSettingsChanged", NULL, NULL);
		CFNotificationCenterAddObserver(darwin, NULL, (CFNotificationCallback) DatabaseChanged, (CFStringRef) @"_CalDatabaseChangedNotification", NULL, NULL);
		
	//	CFNotificationCenterAddObserver(darwin, NULL, (CFNotificationCallback) LicenseChanged, (CFStringRef) @"_CPLicenseChanged", NULL, NULL);
	}
	
    [pool release];
	
}

#ifdef NSF
#undef NSLog(...)
#undef NSF
#endif
#ifdef NSFO
#define NSLog(...)
#endif

