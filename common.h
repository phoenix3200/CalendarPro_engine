// framework imports
#import <AudioToolbox/AudioServices.h>
#import <CFNetwork/CFNetwork.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

// hooking imports
#import <fstream>
#import <mach-o/dyld.h>
#import <mach-o/nlist.h>
#import <notify.h>
#import <objc/message.h>

#import <pthread.h>
#import <sqlite3.h>
#import <substrate.h>


extern "C" id lockdown_connect();
extern "C" void lockdown_disconnect(id port);
extern "C" NSString *lockdown_copy_value(id port, int idk, CFStringRef value);
extern "C" CFStringRef kLockdownUniqueDeviceIDKey;
extern "C" CFStringRef kLockdownProductVersionKey;		// systemVersion
extern "C" CFStringRef kLockdownProductTypeKey;			// model

#define CoreMedia "/System/Library/Frameworks/CoreMedia.framework/CoreMedia"
//#define CoreMedia "/System/Library/Frameworks/CoreMedia.framework/CoreMedia"
#define Celestial "/System/Library/PrivateFrameworks/Celestial.framework/Celestial"
