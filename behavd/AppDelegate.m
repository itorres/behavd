//
//  AppDelegate.m
//  behavd
//
//  This software is licensed under the Apache 2 license, quoted below.
//
//  Copyright 2014 Ignacio Torres Masdeu <ignacio@torresmasdeu.name>
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License. You may obtain a copy of
//  the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "AppDelegate.h"
#import <AppKit/AppKit.h>

#include <stdio.h>
#include <stdlib.h>
#include <libproc.h>
#include <sys/proc_info.h>
#include <signal.h>

@implementation AppDelegate

// http://developer.android.com/tools/help/emulator.html

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                   selector:@selector(appDidActivate:)
                   name:NSWorkspaceDidActivateApplicationNotification
                   object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                   selector:@selector(appDidDeActivate:)
                   name:NSWorkspaceDidDeactivateApplicationNotification
                   object:nil];
    
    
}
// ripped from https://github.com/palominolabs/get_process_handles/blob/master/main.c
int lsfd(pid_t pid) {
    
    // Figure out the size of the buffer needed to hold the list of open FDs
	int bufferSize = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, 0, 0);
	if (bufferSize == -1) {
        NSLog(@"UNABLE_TO_GET_PROC_FDS! %d", pid);
		return -1;
	}
    
	// Get the list of open FDs
	struct proc_fdinfo *procFDInfo = (struct proc_fdinfo *)malloc(bufferSize);
	if (!procFDInfo) {
		NSLog(@"OOM! %d", bufferSize);
		return -1;
	}
	proc_pidinfo(pid, PROC_PIDLISTFDS, 0, procFDInfo, bufferSize);
	int numberOfProcFDs = bufferSize / PROC_PIDLISTFD_SIZE;
    int port; port=0;
	int i;
	for(i = 0; i < numberOfProcFDs; i++) {
		if(procFDInfo[i].proc_fdtype == PROX_FDTYPE_SOCKET) {
			// A socket is open
			struct socket_fdinfo socketInfo;
			int bytesUsed = proc_pidfdinfo(pid, procFDInfo[i].proc_fd, PROC_PIDFDSOCKETINFO, &socketInfo, PROC_PIDFDSOCKETINFO_SIZE);
			if (bytesUsed == PROC_PIDFDSOCKETINFO_SIZE
                && socketInfo.psi.soi_family == AF_INET
                && socketInfo.psi.soi_kind == SOCKINFO_TCP) {
                int localPort = (int)ntohs(socketInfo.psi.soi_proto.pri_tcp.tcpsi_ini.insi_lport);
                int remotePort = (int)ntohs(socketInfo.psi.soi_proto.pri_tcp.tcpsi_ini.insi_fport);
                if (remotePort == 0) {
                    // Remote port will be 0 when the FD represents a listening socket
                    if (port == 0 || localPort < port)
                        port = localPort;
                }
                
			}
		}
	}
    return port;
}
- (pid_t)isEmulator:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    if ([userInfo objectForKey:@"NSWorkspaceApplicationKey"] ==  nil)
        return 0;
    if ([[userInfo objectForKey:@"NSWorkspaceApplicationKey"] class] != [NSRunningApplication class])
        return 0;
    
    NSRunningApplication *app = [userInfo objectForKey:@"NSWorkspaceApplicationKey"];
    NSString *appPath = [[app executableURL] absoluteString];
    
    if ([appPath rangeOfString:@"android-sdk"].location != NSNotFound &&
        ( [appPath rangeOfString:@"tools/emulator64-"].location != NSNotFound
         ||[appPath rangeOfString:@"tools/emulator-"].location != NSNotFound ) ) {
            
            return [app processIdentifier];
        }
    return 0;
}

- (void)appDidDeActivate:(NSNotification *)notification {
    pid_t ret = [self isEmulator:notification];
    if (ret>0 && self.activated) {
        NSLog(@"Desactivando Emulator");
        kill(ret, SIGSTOP);
    }
}

- (void)appDidActivate:(NSNotification *)notification {
    pid_t ret = [self isEmulator:notification];
    if (ret>0) {
        NSLog(@"Activando Emulator");
        kill(ret, SIGCONT);
    }
}

// NSStatusBar behaviour from http://cocoatutorial.grapewave.com/tag/menulet/
// Adapted for ARC
- (void)changeMenu:(NSString *)emoji {
    [self.statusItem setTitle:emoji];
}

-(void)awakeFromNib {
    self.activated = true;
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.statusMenu];
    NSLog(@"Monitoring: %d", self.activated);
    [self.statusItem setTitle: self.activated? @"🌝":@"🌚"];
    [self.statusItem setHighlightMode:YES];
    NSApplication *app = [NSApplication sharedApplication];
    [app activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:nil];
}

-(IBAction)optionAbout:(id)sender {
    NSApplication *app = [NSApplication sharedApplication];
    [app activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
    NSLog(@"Monitoring: %d", self.activated);
    
}

-(IBAction)toggleMonitor:(id)sender {
    self.activated = !self.activated;
    NSLog(@"Monitor: %@", self.activated?@"activated":@"deactivated");
    [self.statusItem setTitle: self.activated? @"🌝":@"🌚"];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = menuItem.action;
    if (action == @selector(toggleMonitor:)) {
        [menuItem setTitle:(self.activated ? @"Deactivate" :@"Activate")];
    }
    return YES;
}

@end