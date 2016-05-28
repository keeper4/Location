//
//  ACCoreTelephony.m
//  Location
//
//  Created by Oleksandr Chyzh on 27/5/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACCoreTelephony.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

extern CFStringRef const kCTCellMonitorCellType;
extern CFStringRef const kCTCellMonitorCellTypeServing;
extern CFStringRef const kCTCellMonitorCellTypeNeighbor;
extern CFStringRef const kCTCellMonitorCellId;
extern CFStringRef const kCTCellMonitorLAC;
extern CFStringRef const kCTCellMonitorMCC;
extern CFStringRef const kCTCellMonitorMNC;
extern CFStringRef const kCTCellMonitorUpdateNotification;

struct CTResult {
    int flag;
    int a;
};

id _CTServerConnectionCreate(CFAllocatorRef, void*, int*);
void _CTServerConnectionAddToRunLoop(id, CFRunLoopRef, CFStringRef);
mach_port_t _CTServerConnectionGetPort(id);

#ifdef __LP64__
void _CTServerConnectionRegisterCallService(id);
void _CTServerConnectionUnregisterCallService(id,int*);
void _CTServerConnectionRegisterForNotification(id, CFStringRef);
void _CTServerConnectionCellMonitorStart(id);
void _CTServerConnectionCellMonitorStop(id);
void _CTServerConnectionCellMonitorCopyCellInfo(id, void*, CFArrayRef*);
void _CTServerConnectionIsInHomeCountry(id, void*, int*);
void _CTServerConnectionCopyCountryCode(id, void*, CFStringRef);

#else

void _CTServerConnectionRegisterCallService(struct CTResult*, id);
#define _CTServerConnectionRegisterCallService(connection) { struct CTResult res; _CTServerConnectionRegisterCallService(&res, connection); }

void _CTServerConnectionRegisterForNotification(struct CTResult*, id, CFStringRef);
#define _CTServerConnectionRegisterForNotification(connection, notification) { struct CTResult res; _CTServerConnectionRegisterForNotification(&res, connection, notification); }

void _CTServerConnectionCellMonitorStart(struct CTResult*, id);
#define _CTServerConnectionCellMonitorStart(connection) { struct CTResult res; _CTServerConnectionCellMonitorStart(&res, connection); }

void _CTServerConnectionCellMonitorStop(struct CTResult*, id);
#define _CTServerConnectionCellMonitorStop(connection) { struct CTResult res; _CTServerConnectionCellMonitorStop(&res, connection); }

void _CTServerConnectionCellMonitorCopyCellInfo(struct CTResult*, id, void*, CFArrayRef*);
#define _CTServerConnectionCellMonitorCopyCellInfo(connection, tmp, cells) { struct CTResult res; _CTServerConnectionCellMonitorCopyCellInfo(&res, connection, tmp, cells); }

void _CTServerConnectionIsInHomeCountry(struct CTResult*, id, int*);
#define CTServerConnectionIsInHomeCountry(connection, isHomeCountry) { struct CTResult res; _CTServerConnectionIsInHomeCountry(&res, connection, &isHomeCountry); }

#endif


@implementation ACCoreTelephony {
    CTCarrier *_carrier;
    id CTConnection;
    mach_port_t  port;
}

+ (instancetype) sharedInstance {
    static ACCoreTelephony *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ACCoreTelephony alloc] init_true];
    });
    return instance;
}

- (instancetype) init_true {
    if (self = [super init]) {
        _carrier = [[CTTelephonyNetworkInfo new] subscriberCellularProvider];
    }
    return self;
}


- (void) startMonitoring {
#if TARGET_IPHONE_SIMULATOR
    return;
#else
    CTConnection = _CTServerConnectionCreate(kCFAllocatorDefault, CellMonitorCallback, NULL);
    _CTServerConnectionRegisterForNotification(CTConnection, kCTCellMonitorUpdateNotification);
    
    port  = _CTServerConnectionGetPort(CTConnection);
    CFMachPortRef ref = CFMachPortCreateWithPort(kCFAllocatorDefault,port,NULL,NULL, NULL);
    CFRunLoopSourceRef rlref = CFMachPortCreateRunLoopSource ( kCFAllocatorDefault, ref, 0);
    CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(currentRunLoop, rlref, kCFRunLoopCommonModes);
    
    _CTServerConnectionCellMonitorStart(CTConnection);
    
#endif
    
}

- (void) stopMonitoring {
    _CTServerConnectionCellMonitorStop(CTConnection);
}


int CellMonitorCallback(id connection, CFStringRef string, CFDictionaryRef dictionary, void *data) {
    int tmp = 0;
    CFArrayRef cells = NULL;
    _CTServerConnectionCellMonitorCopyCellInfo(connection, (void*)&tmp, &cells);
    if (cells == NULL)
    {
        return 0;
    }
    
    for (NSDictionary* cell in (__bridge NSArray*)cells)
    {
        int LAC, CID, MCC, MNC;
        
        if ([cell[(__bridge NSString*)kCTCellMonitorCellType] isEqualToString:(__bridge NSString*)kCTCellMonitorCellTypeServing])
        {
            LAC = [cell[(__bridge NSString*)kCTCellMonitorLAC] intValue];
            CID = [cell[(__bridge NSString*)kCTCellMonitorCellId] intValue];
            MCC = [cell[(__bridge NSString*)kCTCellMonitorMCC] intValue];
            MNC = [cell[(__bridge NSString*)kCTCellMonitorMNC] intValue];
        }
        else if ([cell[(__bridge NSString*)kCTCellMonitorCellType] isEqualToString:(__bridge NSString*)kCTCellMonitorCellTypeNeighbor])
        {
        }
    }
    
    CFRelease(cells);
    
    return 0;
}

@end
