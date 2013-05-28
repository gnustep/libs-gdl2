/** -*-ObjC-*-
   SQLite3LoginPanel.m

   Copyright (C) 2006 Free Software Foundation, Inc.

   Author: Matt Rice  <ratmice@gmail.com>
   Date: January 2006

   This file is part of the GNUstep Database Library

   The GNUstep Database Library is free software; you can redistribute it 
   and/or modify it under the terms of the GNU Lesser General Public License 
   as published by the Free Software Foundation; either version 3, 
   or (at your option) any later version.

   The GNUstep Database Library is distributed in the hope that it will be 
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of 
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License 
   along with the GNUstep Database Library; see the file COPYING. If not, 
   write to the Free Software Foundation, Inc., 
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. 
*/

#include "SQLite3LoginPanel.h"

#import <AppKit/AppKit.h>

#ifndef GNUSTEP
#include <GNUstepBase/Additions.h>
#endif

static BOOL insideModalLoop = YES;

@interface SQLite3LoginPanel(Private)
- (NSDictionary *)_runPanelForAdaptor:(EOAdaptor *)adaptor
                             validate:(BOOL)flag
                       allowsCreation:(BOOL)allowsCreation
               requiresAdministration:(BOOL)adminFlag;
-(void)_assertConnectionDictionaryIsValidForAdaptor:(EOAdaptor *)adaptor
       requiresAdministration:(BOOL)adminFlag;
@end


@implementation SQLite3LoginPanel

- (id) init
{
  if ((self = [super init]))
    {
      NSRect fr1, fr2;
      float w;
      NSImage *imageLogo;
      NSImageView *logo;
      /* TODO make the interface pretty */
      _win = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 256, 148)
      		styleMask: NSTitledWindowMask
		backing:NSBackingStoreBuffered
		defer:YES];
      [_win center];

      imageLogo = [[NSImage alloc] initWithContentsOfFile:
				[[NSBundle bundleForClass: [self class]]
				  pathForImageResource:@"sqlitelogo"]];
      logo = [[NSImageView alloc] initWithFrame:NSMakeRect(5, 48, 214, 96)];
      [logo setImage: imageLogo];
      [logo setEditable:NO];
      [[_win contentView] addSubview: logo];
      [imageLogo release];
      [logo release];

      _ok = [[NSButton alloc] init];
      _cancel = [[NSButton alloc] init];
      [_ok setTitle:@"Ok"];
      [_cancel setTitle:@"Cancel"];
      
      [_ok sizeToFit];
      [_cancel sizeToFit];
      
      fr1 = [_ok frame];
      fr2 = [_cancel frame];
      [_ok setFrame:NSMakeRect(252 - fr2.size.width, 4, fr2.size.width, fr2.size.height)];
      
      fr1 = [_ok frame];
      [_cancel setFrameOrigin:NSMakePoint(fr1.origin.x - fr2.size.width - 4, 4)];
      _browse = [[NSButton alloc] initWithFrame:NSMakeRect(NSMaxX(fr2) + 4, NSMaxY(fr1) + 4, 0, 0)];
      [_browse setTitle:@"Browse"];
      [_browse sizeToFit];
      fr2 = [_browse frame];
      [_browse setFrame:NSMakeRect(256 - fr2.size.width - 4, NSMaxY(fr1) + 4, fr2.size.width, fr2.size.height)];
      fr2 = [_browse frame];

      w = 256 - fr2.size.width - 12;
      _path = [[NSTextField alloc] initWithFrame: NSMakeRect(NSMinX(fr2) - w - 4, NSMaxY(fr1) + 4, w, fr2.size.height)];

      [_ok setTarget:self];
      [_cancel setTarget:self];
      [_browse setTarget:self];
      
      [_ok setAction:@selector(ok:)];
      [_cancel setAction:@selector(cancel:)];
      [_browse setAction:@selector(browse:)];

      [[_win contentView] addSubview:_ok];
      [_ok release];
      [[_win contentView] addSubview:_cancel];
      [_cancel release];
      [[_win contentView] addSubview:_browse];
      [_browse release];
      [[_win contentView] addSubview:_path];
      [_path release];
    }
  
  return self;
}

- (NSDictionary *) _runPanelForAdaptor:(EOAdaptor *)adaptor
		validate:(BOOL)flag
		allowsCreation:(BOOL) allowsCreation
		requiresAdministration:(BOOL)adminFlag
{
  int modalCode;
  volatile BOOL keepLooping = YES;
  NSDictionary *connDict;
  
  while (keepLooping)
    {
      if (!flag) keepLooping = NO;

      insideModalLoop = YES;

      modalCode = [NSApp runModalForWindow:_win];

      if (modalCode == NSRunStoppedResponse)
        {
	  insideModalLoop = NO;
	  connDict = RETAIN([NSDictionary  
		  	dictionaryWithObject:[_path stringValue]
			forKey:@"databasePath"]);
	  [adaptor setConnectionDictionary:connDict];

	  if (flag)
	    {
	      NSString *reason; 
	      NS_DURING
		[self _assertConnectionDictionaryIsValidForAdaptor:adaptor
				requiresAdministration:adminFlag];
	      NS_HANDLER
	      	reason = [localException reason];
		NSRunAlertPanel(@"Invalid SQLite3 connection dictionary",
				reason, nil, nil, nil);
	      NS_ENDHANDLER
	        
	    }
        }
      if (modalCode == NSRunAbortedResponse)
        {
	  insideModalLoop = NO;
	  connDict = nil;
	  keepLooping = NO;
        }
    }
  [_win orderOut:self];
  return AUTORELEASE(connDict);
}

- (NSDictionary *)administrativeConnectionDictionaryForAdaptor:(EOAdaptor *)adaptor;
{
  return [self _runPanelForAdaptor:adaptor
  			validate:YES
			allowsCreation:NO
			requiresAdministration:YES];
}

- (NSDictionary *)runPanelForAdaptor:(EOAdaptor *)adaptor
			validate:(BOOL)flag
			allowsCreation:(BOOL)allowsCreation
{
  return [self _runPanelForAdaptor:adaptor
  			validate:flag
			allowsCreation:allowsCreation
			requiresAdministration:NO];
}



- (void) _assertConnectionDictionaryIsValidForAdaptor:(EOAdaptor *)adaptor
		requiresAdministration:(BOOL)adminFlag
{
  volatile NSException *exception = nil;
  EOAdaptorContext *adaptorContext;
  EOAdaptorChannel *adaptorChannel;

  if (![adaptor hasOpenChannels])
    {
      adaptorContext = [adaptor createAdaptorContext];
      adaptorChannel = [adaptorContext createAdaptorChannel];

      NS_DURING
      	[adaptorChannel openChannel];
      NS_HANDLER
        exception = localException;
      NS_ENDHANDLER

      if ([adaptorChannel isOpen])
        {
	  if (adminFlag)
	    {
	      NSString *path = [[adaptor connectionDictionary] 
	      				objectForKey:@"databasePath"];
	      NSFileManager *fm = [NSFileManager defaultManager];
	      BOOL isDir;
	      BOOL exists;
	      BOOL isW;
	      
	      exists = [fm fileExistsAtPath:path isDirectory:&isDir];
	      
	      if ([path length] && !isDir)
	        {
	          isW = [fm isWritableFileAtPath:path];
		  if (exists && !isW)
		    {
		      exception =
		      	[NSException
			      exceptionWithName:@"Invalid ConnectionDictionary"
		      			 reason:@"Database path is not writable"
				       userInfo:[adaptor connectionDictionary]];
		    }
		  else
		    {
		      path = [path lastPathComponent];
	      	      exists = [fm fileExistsAtPath:path isDirectory:&isDir];
	              isW = [fm isWritableFileAtPath:path];
		      if (!exists || !isW)
		        {
		          exception =
		      	   [NSException
			      exceptionWithName:@"Invalid ConnectionDictionary"
		      			 reason:@"Database path is not writable"
				       userInfo:[adaptor connectionDictionary]];
		        }
		    }
		}
	      else
	        {
		  exception =
		      	[NSException
			      exceptionWithName:@"Invalid ConnectionDictionary"
		      			 reason:@"Database path is invalid."
				       userInfo:[adaptor connectionDictionary]];
		}
	    }
	}

	if (exception)
	  [exception raise];
    }
}

- (void)ok:(id)sender
{
  if (insideModalLoop)
    {
      [NSApp stopModalWithCode:NSRunStoppedResponse];
    }
}

- (void) cancel:(id)sender
{
  if (insideModalLoop)
    {
      [NSApp stopModalWithCode:NSRunAbortedResponse];
    }
}

- (void)browse:(id)sender
{
  NSInteger code;
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *lastPath;
  NSString *file;
 
  lastPath = [defaults stringForKey: @"SQLiteLoginPanelOpenDirectory"];
  if (lastPath == nil)
    lastPath = NSHomeDirectory();
  [panel setAllowedFileTypes:nil];
  code = [panel runModalForDirectory:lastPath file:nil];
  file = [panel filename];

  
  [defaults setObject:[file stringByDeletingLastPathComponent] 
	       forKey:@"SQLiteLoginPanelOpenDirectory"];
  [defaults synchronize];

  if (code == NSOKButton && file)
    {
      [_path setStringValue:file];
    }
}
@end

