TWEAK_NAME = cpengine
cpengine_OBJCC_FILES = cpengine.mm RingerStyle.mm timeitem.mm

cpengine_FRAMEWORKS = CFNetwork
cpengine_PRIVATE_FRAMEWORKS = 
cpengine_LDFLAGS = -lsqlite3 -llockdown

ADDITIONAL_OBJCCFLAGS = -fvisibility=hidden

GO_EASY_ON_ME =1
SDKVERSION = 4.0

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk

