
//#define TESTING		// debug messages

#define DATABASE "/var/mobile/Library/Calendar/Calendar.sqlitedb"

#define CP_VERSION @"1.0"

#define SRPINIT();	NSBundle* mainBundle = [NSBundle mainBundle];

#define SRPLOC(val) [mainBundle localizedStringForKey: val value: nil table: @"RingProfiles"]

#define RPLOC(val) [[NSBundle mainBundle] localizedStringForKey: val value: nil table: @"RingProfiles"]



//void * __builtin_return_address (unsigned int level);
/*
#define TESTLOG(); \
	{ \
		Dl_info info; \
		for(int i=0; i<4; i++) \
		{ \
			void* addr = __builtin_return_address(0); \
			dladdr(, &info); \
			NSLog(@"%d: %08x=%08x+%08x+%08x %s (%s)", \
				i, \
				(uint32_t) addr - (uint32_t) info.dli_fbase, \
				info.dli_fbase, \
				(uint32_t) info.dli_saddr - (uint32_t) info.dli_fbase, \
				(uint32_t) addr - (uint32_t) info.dli_saddr, \
				info.dli_fname, info.dli_sname); \
		} \
	} \
	*/

#ifdef TESTING
	#define NSLine() NSLog(@"%s %s %d", __FILE__, __FUNCTION__, __LINE__)
	#define HookLog(); \
		{ \
		uint32_t bt=0; \
		__asm__("mov %0, lr": "=r"(bt)); \
		NSLog(@"[%@ %s] bt=%x", [[self class] description], sel_getName(sel), bt); \
		}
	#define SelLog(); \
		{ \
		uint32_t bt=0; \
		__asm__("mov %0, lr": "=r"(bt)); \
		NSLog(@"%s bt=%x", __FUNCTION__, bt); \
		}
	#define NSType(obj) \
		NSLog(@"%@* " #obj  ";", [[obj class] description])
	#define NSDesc(obj) \
		NSLog(@"" #obj  "%@", [obj description])
	#define NSPoint(obj) \
		NSLog(@ #obj " = {{%f %f}{%f %f}}", obj.origin.x, obj.origin.y, obj.size.width, obj.size.height)
#else
	#define NSLine()
	#define NSLog(...)
	#define HookLog();
	#define SelLog();
	#define NSType(...)
	#define NSDesc(...)
	#define NSPoint(...)
#endif

#define HOOKDEF(type, class, name, args...) \
static type (*_ ## class ## $ ## name)(class *self, SEL sel, ## args); \
static type $ ## class ## $ ## name(class *self, SEL sel, ## args)

#define HOOK(type, class, name, args...) \
static type $ ## class ## $ ## name(class *self, SEL sel, ## args)

#define CALL_ORIG(class, name, args...) \
_ ## class ## $ ## name(self, sel, ## args)

#define GETCLASS(class) \
Class $ ## class  = objc_getClass(#class)

#define HOOKMESSAGE(class, sel, selnew) \
MSHookMessageEx( $ ## class, @selector(sel), (IMP)$ ## class ## $ ## selnew, (IMP*)&_ ## class ## $ ## selnew);

#define HOOKCLASSMESSAGE(class, sel, selnew) \
MSHookMessageEx( object_getClass($ ## class), @selector(sel), (IMP)$ ## class ## $ ## selnew, (IMP*)&_ ## class ## $ ## selnew);

#define IVGETVAR(type, name); \
static type name; \
Ivar IV$ ## name = object_getInstanceVariable(self, #name, reinterpret_cast<void **> (& name));

#define GETVAR(type, name); \
static type name; \
object_getInstanceVariable(self, #name, reinterpret_cast<void **> (& name));

#define GETIVAR(type, name) \
name = (type) object_getIvar(self, IV$ ## name)

#define SETIVAR(name) \
object_setIvar(self, IV$ ## name, (id) name)

#define SETVAL(name, value); \
name = value; \
object_setIvar(self, IV$ ## name, (id) name);

#define CLASSALLOC(class) \
[objc_getClass(#class) alloc]

