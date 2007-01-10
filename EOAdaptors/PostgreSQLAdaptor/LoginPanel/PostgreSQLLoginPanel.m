/** -*-ObjC-*-
   PostgreSQLLoginPanel.m

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: Matt Rice  <ratmice@gmail.com>
   Date: February 2004

   This file is part of the GNUstep Database Library

   The GNUstep Database Library is free software; you can redistribute it 
   and/or modify it under the terms of the GNU Lesser General Public License 
   as published by the Free Software Foundation; either version 2, 
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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <EOAccess/EOAccess.h>

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include "PostgreSQLLoginPanel.h"

static BOOL insideModalLoop;

static NSString *windowTitle = @"PostgreSQLql login";
static NSString *newDatabaseTitle = @"New";
static NSString *userNameTitle = @"Username: ";
static NSString *passwordTitle = @"Password: ";
static NSString *databaseNameTitle = @"Database: ";
static NSString *hostTitle = @"Host: ";
static NSString *portTitle = @"Port: ";
static NSString *okTitle = @"OK";
static NSString *cancelTitle = @"Cancel";



static float
vfmaxf (int n, float aFloat, ...)
{
  float champion=0.0; 
  va_list list;

  if (n == 0)
    {
      return 0;
    }

  va_start(list,aFloat);
  champion = aFloat;

  while (n > 1) 
    {
      float contender;

      contender = (float)va_arg(list,double);
      //printf("%f vs %f ",contender,champion); 
      // fmaxf is c99 or i'd use it.. 
      champion = (champion > contender ) ? champion : contender;
      //printf("champion: %f\n",champion); 
      n--; 
    }

  va_end(list);
  return champion;
}



@implementation PostgreSQLLoginPanel : EOLoginPanel

- (void) dealloc
{
  DESTROY(_databases);
  DESTROY(_win);
  [super dealloc];
}

- (NSString *) logoPath
{
  return [[NSBundle bundleForClass: [self class]]
	  	pathForImageResource:@"postgreslogo"];
}

- (id)init
{
  if ((self = [super init]))
    {
      NSRect rect1,rect2,rect3; 
      float maxLabelHeight;
      float maxButtonWidth;
      float maxButtonHeight;
      // this doesn't have a height because it'll be the same as the label
      float maxFieldWidth;

      float spacer = 3.0;
      float lalign;
      NSRect tempRect;
      NSSize screenSize = [[NSScreen mainScreen] frame].size;
      NSImage *logoImg = [[NSImage alloc] initWithContentsOfFile: [self logoPath]]; 
      
      NSSize tmpSize = [logoImg size];

      _databases = nil;
      logo = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, tmpSize.width, tmpSize.height)];
      [logo setImage: logoImg]; 
      [logo setEditable:NO];
      RELEASE(logoImg);
      


      
      userNameLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(0,0,0,0)];
      [userNameLabel setStringValue:userNameTitle]; 
      [userNameLabel setAlignment:NSRightTextAlignment];
      [userNameLabel setEditable:NO]; 
      [userNameLabel setSelectable:NO]; 
      [userNameLabel setDrawsBackground:NO]; 
      [userNameLabel setBordered:YES];
      [userNameLabel setBezeled:YES];
      [userNameLabel sizeToFit];
      [userNameLabel setBordered:NO];
      [userNameLabel setBezeled:NO];
      
      passwdLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,0,0)];
      [passwdLabel setStringValue:passwordTitle];
      [passwdLabel setAlignment:NSRightTextAlignment];
      [passwdLabel setEditable:NO];
      [passwdLabel setSelectable:NO];
      [passwdLabel setDrawsBackground:NO];
      [passwdLabel setBordered:YES];
      [passwdLabel setBezeled:YES];
      [passwdLabel sizeToFit];
      [passwdLabel setBordered:NO];
      [passwdLabel setBezeled:NO];
      
      databaseLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(0,0,0,0)];
      [databaseLabel setStringValue:databaseNameTitle];
      [databaseLabel setAlignment:NSRightTextAlignment];
      [databaseLabel setEditable:NO];
      [databaseLabel setSelectable:NO];
      [databaseLabel setDrawsBackground:NO];
      [databaseLabel setBordered:YES];
      [databaseLabel setBezeled:YES];
      [databaseLabel sizeToFit];
      [databaseLabel setBordered:NO];
      [databaseLabel setBezeled:NO];

      hostLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(0,0,0,0)];
      [hostLabel setStringValue:hostTitle];
      [hostLabel setAlignment:NSRightTextAlignment];
      [hostLabel setEditable:NO];
      [hostLabel setSelectable:NO];
      [hostLabel setDrawsBackground:NO];
      [hostLabel setBordered:YES];
      [hostLabel setBezeled:YES];
      [hostLabel sizeToFit];
      [hostLabel setBordered:NO];
      [hostLabel setBezeled:NO];
      
      portLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(0,0,0,0)];
      [portLabel setStringValue:portTitle];
      [portLabel setAlignment:NSRightTextAlignment];
      [portLabel setEditable:NO];
      [portLabel setSelectable:NO];
      [portLabel setDrawsBackground:NO];
      [portLabel setBordered:YES];
      [portLabel setBezeled:YES];
      [portLabel sizeToFit];
      [portLabel setBordered:NO];
      [portLabel setBezeled:NO];


      
      lalign = vfmaxf(3, [databaseLabel frame].size.width,
		      [passwdLabel frame].size.width,
		      [userNameLabel frame].size.width);
      maxLabelHeight = vfmaxf(3, [databaseLabel frame].size.height,
		      	      [passwdLabel frame].size.height,
			      [userNameLabel frame].size.height);
      
      [databaseLabel setFrame: NSMakeRect(spacer,
		      			  (maxLabelHeight + spacer * 2) * 2,
					  lalign,
					  maxLabelHeight)];
      [portLabel setFrame: NSMakeRect(spacer,
                                        (maxLabelHeight + spacer * 2) * 3,
                                        lalign,
                                          maxLabelHeight)];
      [hostLabel setFrame: NSMakeRect(spacer,
                                        (maxLabelHeight + spacer * 2) * 4,
                                        lalign,
                                          maxLabelHeight)];
      [passwdLabel setFrame: NSMakeRect(spacer,
		      			(maxLabelHeight + spacer * 2) * 5,
					lalign,
					  maxLabelHeight)];
      [userNameLabel setFrame: NSMakeRect(spacer,
			      	  	  (maxLabelHeight + spacer * 2) * 6,
				          lalign,
					  maxLabelHeight)];
     
      rect1 = [userNameLabel frame];
      rect2 = [logo frame];
      [logo setFrame:NSMakeRect(spacer * 2,
		      		rect1.origin.y + rect1.size.height + (spacer * 2),
				rect2.size.width, rect2.size.height)];

      okButton = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,0,0)];
      [okButton setTitle:okTitle];
      [okButton setTarget:self];
      [okButton setAction:@selector(ok:)];
      [okButton setImagePosition:NSImageRight];
      [okButton setImage:[NSImage imageNamed:@"common_ret"]];
      [okButton setAlternateImage:[NSImage imageNamed:@"common_retH"]];
      [okButton setKeyEquivalent:@"\r"];
      [okButton sizeToFit];

      cancelButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,0,0)];
      [cancelButton setTitle:cancelTitle];
      [cancelButton setTarget:self];
      [cancelButton setAction:@selector(cancel:)];
      [cancelButton sizeToFit];
      
      newDatabaseButton = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,0,0)];
      [newDatabaseButton setTarget:self];
      [newDatabaseButton setAction:@selector(newDatabase:)];
      [newDatabaseButton setTitle:newDatabaseTitle];
      [newDatabaseButton setEnabled:NO];
      [newDatabaseButton sizeToFit];

      rect1 = [cancelButton frame];
      rect2 = [okButton frame];
      rect3 = [newDatabaseButton frame];

      maxButtonWidth  = vfmaxf(3, rect1.size.width, rect2.size.width,
		      	       rect3.size.width);
      maxButtonHeight = vfmaxf(3, rect1.size.height, rect2.size.height,
		      	       rect3.size.width);

      tempRect = NSMakeRect(rect1.origin.x,
			    rect1.origin.y,
			    maxButtonWidth,
			    maxButtonHeight);
      
      [cancelButton setFrame:tempRect];
      tempRect = NSMakeRect(rect1.origin.x +
			    maxButtonWidth + spacer,
			    rect2.origin.y,
			    maxButtonWidth,
			    maxButtonHeight);
      [okButton setFrame:tempRect];

      tempRect = NSMakeRect([userNameLabel frame].origin.x +
			    [userNameLabel frame].size.width+spacer,
			    [userNameLabel frame].origin.y,
			    300,maxLabelHeight);
      userNameField = [[NSTextField alloc] initWithFrame: tempRect];
      [userNameField setStringValue:NSUserName()]; 
      [userNameField setTarget:self];
      [userNameField setAction:@selector(ok:)];
      
      tempRect = NSMakeRect([hostLabel frame].origin.x +
                            [hostLabel frame].size.width+spacer,
                            [hostLabel frame].origin.y,
                            300,maxLabelHeight);
      hostField = [[NSTextField alloc] initWithFrame: tempRect];
      [hostField setStringValue:@""];
      [hostField setTarget:self];
      [hostField setAction:@selector(ok:)];

      tempRect = NSMakeRect([portLabel frame].origin.x +
                            [portLabel frame].size.width+spacer,
                            [portLabel frame].origin.y,
                            50,maxLabelHeight);
      portField = [[NSTextField alloc] initWithFrame: tempRect];
      [portField setStringValue:@""];
      [portField setTarget:self];
      [portField setAction:@selector(ok:)];

      maxFieldWidth=[userNameField frame].size.width; 

      tempRect = NSMakeRect([passwdLabel frame].origin.x +
			    [passwdLabel frame].size.width + spacer,
			    [passwdLabel frame].origin.y,
			    300, maxLabelHeight);
      passwdField = [[NSSecureTextField alloc] initWithFrame: tempRect];
      [passwdField setStringValue:@""];
      [passwdField setTarget:self];
      [passwdField setAction:@selector(ok:)];

      tempRect = NSMakeRect([databaseLabel frame].origin.x +
			    [databaseLabel frame].size.width + spacer,
			    [databaseLabel frame].origin.y,
			    300 - maxButtonWidth - (spacer * 3),maxLabelHeight); 
      databasesCombo = [[NSComboBox alloc] initWithFrame:tempRect];
      [databasesCombo setStringValue:@""];
      [databasesCombo setUsesDataSource:YES];
      [databasesCombo setDataSource:self];
      [databasesCombo setDelegate:self];

      tempRect = [newDatabaseButton frame];
      tempRect.origin.x = [databasesCombo frame].origin.x + [databasesCombo frame].size.width + (spacer * 2);
      tempRect.origin.y = [databasesCombo frame].origin.y;
      tempRect.size.width = maxButtonWidth;
      [newDatabaseButton setFrame: tempRect]; 
      
      /* make a window that will fit all the controls, 
	 center it, add all subviews.. */
      tempRect.size.width = vfmaxf(3,
		      		   [logo frame].origin.x + [logo frame].size.width, 
		      		   [userNameField frame].origin.x + [userNameField frame].size.width,
				   [newDatabaseButton frame].origin.x + [newDatabaseButton frame].size.width) + spacer;
      tempRect.size.height = [logo frame].origin.y + [logo frame].size.height + (spacer * 2);
      
      tempRect.origin.x = (screenSize.width/2) - (tempRect.size.width/2);
      tempRect.origin.y = (screenSize.height/2) - (tempRect.size.height/2);
      
      _win = [[NSWindow alloc] initWithContentRect: tempRect 
			       styleMask: NSTitledWindowMask
			       backing: NSBackingStoreRetained
			       defer: YES];
      [_win setTitle: windowTitle];
      [_win setDelegate:self];
      rect1 = [NSWindow contentRectForFrameRect:[_win frame]
			styleMask:[_win styleMask]];  
      [_win setMinSize: rect1.size]; 
      
      [[_win contentView] addSubview: newDatabaseButton];
      RELEASE(newDatabaseButton);
      [[_win contentView] addSubview: userNameLabel];
      RELEASE(userNameLabel);
      [[_win contentView] addSubview: databaseLabel];
      RELEASE(databaseLabel);
      [[_win contentView] addSubview: passwdLabel];
      RELEASE(passwdLabel);
      [[_win contentView] addSubview: portLabel];
      RELEASE(portLabel);
      [[_win contentView] addSubview: hostLabel];
      RELEASE(hostLabel);
      [[_win contentView] addSubview: userNameField];
      RELEASE(userNameField);
      [[_win contentView] addSubview: passwdField];
      RELEASE(passwdField);
      [[_win contentView] addSubview: databasesCombo];
      RELEASE(databasesCombo);
      [[_win contentView] addSubview: hostField];
      RELEASE(hostField);

      [[_win contentView] addSubview: portField];
      RELEASE(portField);

      [[_win contentView] addSubview: logo];
      RELEASE(logo);
      
      [[_win contentView] addSubview: okButton];
      [[_win contentView] addSubview: cancelButton];

      [okButton setFrame:NSMakeRect(tempRect.size.width -
				      [okButton frame].size.width-(spacer * 2),
				    spacer,
				    [okButton frame].size.width,
				    [okButton frame].size.height)];
      [cancelButton setFrame:NSMakeRect([okButton frame].origin.x -
				        [cancelButton frame].size.width - (spacer * 2),
					spacer,
					[cancelButton frame].size.width,
					[cancelButton frame].size.height)]; 
      RELEASE(okButton);
      RELEASE(cancelButton);

      [userNameField setNextKeyView:passwdField]; 
      [passwdField setNextKeyView: hostField];
      [hostField setNextKeyView: portField];
      [portField setNextKeyView: databasesCombo];
      [databasesCombo setNextKeyView:newDatabaseButton];
      [newDatabaseButton setNextKeyView:okButton];
      [okButton setNextKeyView:cancelButton];
      [cancelButton setNextKeyView:userNameField];
      [_win makeFirstResponder:userNameField]; 
    }
  return self;
}

- (NSArray *)_databaseNames
{
  EOModel       *aMod;
  EOAdaptor         *adaptor;
  EOAdaptorContext  *context;
  EOAdaptorChannel  *channel;
  NSArray *databaseNames = nil;
  BOOL exceptionOccured = NO;

  aMod = [EOModel new];
  [aMod   setName: @"AvailableDatabases"];
  [aMod   setAdaptorName: @"PostgreSQL"];
  /* 
     we need a connection to a known database template1 should exist 
  */
  [aMod   setConnectionDictionary:
    [NSDictionary dictionaryWithObjects:
                       [NSArray arrayWithObjects:@"template1", 
                                                 [userNameField stringValue],
						 [passwdField stringValue],
						 [hostField stringValue],
						 [portField stringValue],
						 nil]
                                forKeys:[NSArray 
					  arrayWithObjects:@"databaseName",
					                   @"userName",
							   @"password",
							   @"databaseServer",
							   @"port",
							   nil]]];
  adaptor = [EOAdaptor adaptorWithModel: aMod];
  context = [adaptor createAdaptorContext];
  channel = [context createAdaptorChannel];
  /* TODO eliminate some of these channels*/ 
  NS_DURING
    [adaptor assertConnectionDictionaryIsValid];
  NS_HANDLER
    NSRunAlertPanel(@"Invalid logon information",[localException reason],
                    nil,nil,nil);
    exceptionOccured = YES; 
  NS_ENDHANDLER
  
  if (!exceptionOccured)
    {
      [channel openChannel];
      databaseNames = [(PostgreSQLChannel*)channel describeDatabaseNames];
      [channel closeChannel];
      RELEASE(aMod); 
    } 
 return databaseNames;
}

/* login panel stuff */

- (NSDictionary *)administrativeConnectionDictionaryForAdaptor:(EOAdaptor *)adaptor
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
/* private functions */
-(void)_assertConnectionDictionaryIsValidForAdaptor:(EOAdaptor *)adaptor
       requiresAdministration:(BOOL)adminFlag
{
  NSException *exception = nil;
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
      NS_ENDHANDLER;

      if ([adaptorChannel isOpen])
        {
          if (adminFlag)
            {
              BOOL isAdmin = [(PostgreSQLChannel*)adaptorChannel 
                 userNameIsAdministrative: [userNameField stringValue]];
              if (!isAdmin)
                {
                  exception = [NSException 
                                 exceptionWithName:@"RequiresAdministrator"
                                 reason:@"User is not a valid administrator"
                                 userInfo:nil]; 
                } 
            }

          [adaptorChannel closeChannel];
        }

      if (exception)
        [exception raise];
    }
}
 
- (NSDictionary *)_runPanelForAdaptor:(EOAdaptor *)adaptor
                             validate:(BOOL)flag
                       allowsCreation:(BOOL)allowsCreation
	       requiresAdministration:(BOOL)adminFlag
{
  int modalCode;
  volatile BOOL keepLooping = YES;
  NSDictionary *connDict; 
  [_win makeFirstResponder:userNameField];

  while (keepLooping)
  {
    [newDatabaseButton setEnabled:allowsCreation];
    
    if (!flag)
      keepLooping = NO; 
    
    insideModalLoop = YES;
    modalCode = [NSApp runModalForWindow: _win]; 
    
    if (modalCode == NSRunStoppedResponse)
      {
        insideModalLoop = NO;
	connDict = [[NSDictionary alloc] 
	                initWithObjectsAndKeys:[databasesCombo stringValue],
					       @"databaseName", 
					       [userNameField stringValue],
					       @"userName", 
					       [passwdField stringValue],
					       @"password",
					       [adaptor name],
					       @"adaptorName",
					       [hostField stringValue],
					       @"databaseServer",
					       [portField stringValue],
					       @"port",
					       nil];
        [adaptor setConnectionDictionary:connDict];
	
	if (flag) 
	  {
	    NSString *reason;
	    NS_DURING
	      [self _assertConnectionDictionaryIsValidForAdaptor:adaptor
	                                  requiresAdministration:adminFlag];  
	      /* shouldn't get here if there was an exception */ 
	      keepLooping = NO; 
	    NS_HANDLER
	      reason = [localException reason];
	      if ([reason hasPrefix:@"FATAL: "])
	        reason = [reason stringByDeletingPrefix:@"FATAL: "];
              NSRunAlertPanel(@"Unable to login",
	                      reason, 
			      nil,nil,nil); 
	    NS_ENDHANDLER;
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


/* button actions */

-(void)showDatabases:(id)sender
{
  ASSIGN(_databases,[self _databaseNames]);
  [databasesCombo reloadData];
}


-(void)newDatabase:(id)sender
{
  NSDictionary *connDict;
  NSDictionary *adminDict;
  EOAdaptor *adaptor;
  NSString *reason; 
  
  connDict=[[NSDictionary alloc] 
               initWithObjectsAndKeys:[databasesCombo stringValue],
	                              @"databaseName",
			              nil];
  adminDict=[[NSDictionary alloc] 
               initWithObjectsAndKeys:@"template1",@"databaseName",
		                      [userNameField stringValue],@"userName",
				      [passwdField stringValue], @"password",
		                      nil];
  adaptor = [EOAdaptor adaptorWithName:@"PostgreSQL"]; 
  [adaptor setConnectionDictionary:connDict]; 
 
  // hmm if the user isn't an admin the error is kinda ugly.. 
  // but states its point
  
  NS_DURING
    [adaptor createDatabaseWithAdministrativeConnectionDictionary:adminDict]; 
  NS_HANDLER
    reason = [localException reason];
    if ([reason hasPrefix:@"FATAL: "])
      reason = [reason stringByDeletingPrefix:@"FATAL: "];
    NSRunAlertPanel(@"Unable to create database",
                              reason,
                              nil,nil,nil);
  NS_ENDHANDLER;
  RELEASE(adminDict);
  RELEASE(connDict);
  [self showDatabases:self];
}

-(void)ok:(id)sender
{
  if (insideModalLoop) /* in case of double click */
    [NSApp stopModalWithCode:NSRunStoppedResponse]; 
}

-(void)cancel:(id)sender
{
  if (insideModalLoop) /* in case of double click */
    [NSApp stopModalWithCode:NSRunAbortedResponse];
}

/* table view action */
-(void) doubleAction:(id)sender
{
  [self ok: self]; 
}

/* databases table stuff */

-(int)numberOfItemsInComboBox:(NSComboBox*)cbox
{
   return [_databases count];
}

- (id)comboBox:(NSComboBox*) cbox 
      objectValueForItemAtIndex:(int)row
{
  return [_databases objectAtIndex:row];
}
- (void) comboBoxWillPopUp:(NSNotification *)notif
{
  [self showDatabases:self]; 
}

@end

