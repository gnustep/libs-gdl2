/** -*-ObjC-*-
   Postgres95LoginPanel.m

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: Matt Rice  <ratmice@yahoo.com>
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

#include "Postgres95LoginPanel.h"

static BOOL insideModalLoop;

static NSString *windowTitle = @"Postgresql login";
static NSString *tableViewTitle = @"Databases";
static NSString *newDatabaseTitle = @"New";
static NSString *userNameTitle = @"Username: ";
static NSString *passwordTitle = @"Password: ";
static NSString *databaseNameTitle = @"Database: ";
static NSString *showDatabasesTitle = @"List";
static NSString *okTitle = @"Ok";
static NSString *cancelTitle = @"Cancel";
// used to size text fields using the default font size...
static NSString *someString = @"wwwwwwww";



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



@implementation Postgres95LoginPanel : EOLoginPanel

- (void) dealloc
{
  DESTROY(_databases);
  DESTROY(_win);
}

- (id)init
{
  if ((self = [super init]))
    {
      NSTableColumn *tableColumn;
      NSRect rect1,rect2,rect3; 
      float maxLabelWidth;
      float maxLabelHeight;
      float maxButtonWidth;
      float maxButtonHeight;
// this doesn't have a height because it'll be the same as the label
      float maxFieldWidth;

      float spacer = 3.0;
      NSRect tempRect;
      NSSize screenSize = [[NSScreen mainScreen] frame].size;
      
      _databases = nil;
      
      showDatabasesButton =
        [[NSButton alloc] initWithFrame: NSMakeRect(spacer,spacer,0,0)];
      [showDatabasesButton setTarget:self];
      [showDatabasesButton setAction:@selector(showDatabases:)];
      [showDatabasesButton setTitle:showDatabasesTitle];
      [showDatabasesButton setEnabled:YES];
      [showDatabasesButton sizeToFit];

      newDatabaseButton =
	[[NSButton alloc] 
	  initWithFrame:NSMakeRect(spacer +
				   [showDatabasesButton frame].origin.x +
				   [showDatabasesButton frame].size.width,
				   spacer,0,0)];
      [newDatabaseButton setTarget:self];
      [newDatabaseButton setAction:@selector(newDatabase:)];
      [newDatabaseButton setTitle:newDatabaseTitle];
      [newDatabaseButton setEnabled:NO];
      [newDatabaseButton sizeToFit];

      okButton = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,0,0)];
      [okButton setTitle:okTitle];
      [okButton setTarget:self];
      [okButton setAction:@selector(ok:)];
      [okButton setImagePosition:NSImageRight];
      [okButton setImage:[NSImage imageNamed:@"common_ret"]];
      [okButton setAlternateImage:[NSImage imageNamed:@"common_rectH"]];
      [okButton setKeyEquivalent:@"\r"];
      [okButton sizeToFit];

      cancelButton = [[NSButton alloc] initWithFrame: NSMakeRect(0,0,0,0)];
      [cancelButton setTitle:cancelTitle];
      [cancelButton setTarget:self];
      [cancelButton setAction:@selector(cancel:)];
      [cancelButton sizeToFit];

      rect1 = [cancelButton frame];
      rect2 = [okButton frame];

      maxButtonWidth  = vfmaxf(2,rect1.size.width,rect2.size.width);
      maxButtonHeight = vfmaxf(2,rect1.size.height,rect2.size.height);

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



      tableScrollView = [[NSScrollView alloc] 
			  initWithFrame: NSMakeRect(0,0,0,0)];
      [tableScrollView setHasHorizontalScroller:YES];
      [tableScrollView setHasVerticalScroller:YES];
      [tableScrollView setBorderType: NSLineBorder]; 
       
      databases = [[NSTableView alloc] 
		    initWithFrame: NSMakeRect(0,0,maxButtonWidth*2,0)];
      [databases setDataSource:self];
      [databases setDelegate:self];
      [databases setAllowsColumnSelection:NO];
      [databases setAutoresizesAllColumnsToFit:YES]; 
      [databases setTarget:self]; 
      [databases setAction:@selector(tableAction:)];
      [databases setDoubleAction:@selector(doubleAction:)];
      
      [tableScrollView setDocumentView: databases]; 
      RELEASE(databases);
       
      tableColumn = [(NSTableColumn*)[NSTableColumn alloc] initWithIdentifier: tableViewTitle];
      [[tableColumn headerCell] setStringValue: tableViewTitle];    
      [tableColumn setEditable:NO];
      [tableColumn sizeToFit];
      [tableColumn setMinWidth: [tableColumn width]];
      [tableColumn setResizable:YES];
      [databases addTableColumn: tableColumn]; 
      [databases sizeToFit]; 
      
      /* resize the table view so no horizontal scroller shows up.. 
         add 3 to the width because of the scroll view border,
	 and make it square */
      [tableScrollView setFrame:
          NSMakeRect(spacer,
                     spacer + [showDatabasesButton frame].origin.y +
		     [showDatabasesButton frame].size.height,
                     3+[[tableScrollView verticalScroller] frame].size.width +
		     [databases frame].size.width,
                     3+[[tableScrollView verticalScroller] frame].size.width +
		     [databases frame].size.width)];
      RELEASE(tableColumn); 
      
      userNameLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(0,0,0,0)];
      [userNameLabel setStringValue:userNameTitle]; 
      [userNameLabel setAlignment:NSRightTextAlignment];
      [userNameLabel setEditable:NO]; 
      [userNameLabel setSelectable:NO]; 
      [userNameLabel setDrawsBackground:NO]; 
      [userNameLabel setBordered:NO];
      [userNameLabel setBezeled:NO];
      [userNameLabel sizeToFit];

      passwdLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,0,0)];
      [passwdLabel setStringValue:passwordTitle];
      [passwdLabel setAlignment:NSRightTextAlignment];
      [passwdLabel setEditable:NO];
      [passwdLabel setSelectable:NO];
      [passwdLabel setDrawsBackground:NO];
      [passwdLabel setBordered:NO];
      [passwdLabel setBezeled:NO];
      [passwdLabel sizeToFit];

      databaseLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(0,0,0,0)];
      [databaseLabel setStringValue:databaseNameTitle];
      [databaseLabel setAlignment:NSRightTextAlignment];
      [databaseLabel setEditable:NO];
      [databaseLabel setSelectable:NO];
      [databaseLabel setDrawsBackground:NO];
      [databaseLabel setBordered:NO];
      [databaseLabel setBezeled:NO];
      [databaseLabel sizeToFit];
       
      rect1=[databaseLabel frame];
      rect2=[userNameLabel frame];
      rect3=[passwdLabel frame]; 
      
      maxLabelWidth = vfmaxf(3,
			     rect1.size.width,
			     rect2.size.width,
			     rect3.size.width);

      maxLabelHeight = vfmaxf(3,
			      rect1.size.height,
			      rect2.size.height,
			      rect3.size.height);
      
      tempRect = [databaseLabel frame]; 
      tempRect.size.width  = maxLabelWidth;
      tempRect.size.height = maxLabelHeight;
      tempRect.origin.x = [tableScrollView frame].origin.x +
	                  [tableScrollView frame].size.width + spacer; 
      tempRect.origin.y = [okButton frame].origin.y +
	                  [okButton frame].size.height + (spacer*2);
      [databaseLabel setFrame:tempRect]; 
      
      tempRect = [passwdLabel frame]; 
      tempRect.size.width  = maxLabelWidth;
      tempRect.size.height = maxLabelHeight;
      tempRect.origin.x = [tableScrollView frame].origin.x +
	                  [tableScrollView frame].size.width + spacer; 
      tempRect.origin.y = [databaseLabel frame].origin.y + 
	                  [databaseLabel frame].size.height + (spacer*3);
      [passwdLabel setFrame:tempRect];
      
      tempRect = [userNameLabel frame]; 
      tempRect.size.width  = maxLabelWidth;
      tempRect.size.height = maxLabelHeight;
      tempRect.origin.x = [tableScrollView frame].origin.x +
	                  [tableScrollView frame].size.width + spacer; 
      tempRect.origin.y = [passwdLabel frame].origin.y + 
	                  [databaseLabel frame].size.height + (spacer*3);
      [userNameLabel setFrame:tempRect];
      
      tempRect = NSMakeRect([userNameLabel frame].origin.x +
			    [userNameLabel frame].size.width+spacer,
			    [userNameLabel frame].origin.y,
			    0,0);
      userNameField = [[NSTextField alloc] initWithFrame: tempRect];
       
      [userNameField setStringValue:someString];
      [userNameField sizeToFit];
      [userNameField setStringValue:NSUserName()]; 
      [userNameField setTarget:self];
      [userNameField setAction:@selector(ok:)];
      
      maxFieldWidth=[userNameField frame].size.width; 

      tempRect = NSMakeRect([passwdLabel frame].origin.x +
			    [passwdLabel frame].size.width + spacer,
			    [passwdLabel frame].origin.y,
			    0, 0);
      passwdField = [[NSSecureTextField alloc] initWithFrame: tempRect];

      [passwdField setStringValue:someString];
      [passwdField sizeToFit]; 
      [passwdField setStringValue:@""];
      [passwdField setTarget:self];
      [passwdField setAction:@selector(self:)];

      tempRect = NSMakeRect([databaseLabel frame].origin.x +
			    [databaseLabel frame].size.width + spacer,
			    [databaseLabel frame].origin.y,
			    0,0); 
      databaseField = [[NSTextField alloc] initWithFrame: tempRect];

      [databaseField setStringValue:someString];
      [databaseField sizeToFit];
      [databaseField setStringValue:@""];
      [databaseField setTarget:self];
      [databaseField setAction:@selector(ok:)];
      
      /* make a rect that will fit all the controls, 
	 center it and create a window that size
         add all subviews.. */

      tempRect = NSMakeRect(0,0,
		            (spacer *6)+[tableScrollView frame].size.width +
			    vfmaxf(2,
				   (maxLabelWidth+maxFieldWidth),
				   (maxButtonWidth*2)),
		            vfmaxf(2,
				   ([tableScrollView frame].origin.y +
				    [tableScrollView frame].size.height +
				    spacer),
				   (maxLabelHeight*3)+
				   maxButtonHeight + (spacer *5)));
       
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
      [[_win contentView] addSubview: showDatabasesButton];
      RELEASE(showDatabasesButton);
      [[_win contentView] addSubview: newDatabaseButton];
      RELEASE(newDatabaseButton);
      [[_win contentView] addSubview:tableScrollView];  
      RELEASE(tableScrollView);
      [[_win contentView] addSubview: userNameLabel];
      RELEASE(userNameLabel);
      [[_win contentView] addSubview: databaseLabel];
      RELEASE(databaseLabel);
      [[_win contentView] addSubview: passwdLabel];
      RELEASE(passwdLabel);
      [[_win contentView] addSubview: userNameField];
      RELEASE(userNameField);
      [[_win contentView] addSubview: passwdField];
      RELEASE(passwdField);
      [[_win contentView] addSubview: databaseField];
      RELEASE(databaseField);
      
      [[_win contentView] addSubview: okButton];
      [[_win contentView] addSubview: cancelButton];

      [okButton setFrame:NSMakeRect(tempRect.size.width -
				      [okButton frame].size.width-spacer,
				    spacer,
				    [okButton frame].size.width,
				    [okButton frame].size.height)];
      [cancelButton setFrame:NSMakeRect([okButton frame].origin.x -
					  [cancelButton frame].size.width -
					  spacer,
					spacer,
					[cancelButton frame].size.width,
					[cancelButton frame].size.height)]; 
      RELEASE(okButton);
      RELEASE(cancelButton);

      [userNameField setNextKeyView:passwdField]; 
      [passwdField setNextKeyView:databaseField];
      [databaseField setNextKeyView:showDatabasesButton]; 
      [showDatabasesButton setNextKeyView:newDatabaseButton];
      [newDatabaseButton setNextKeyView:databases];
      [databases setNextKeyView:okButton];
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
  [aMod   setAdaptorName: @"Postgres95"];
  /* 
     we need a connection to a known database template1 should exist 
  */
  [aMod   setConnectionDictionary:
    [NSDictionary dictionaryWithObjects:
                       [NSArray arrayWithObjects:@"template1", 
                                                 [userNameField stringValue],
						 [passwdField stringValue],nil]
                                forKeys:[NSArray 
					  arrayWithObjects:@"databaseName",
					                   @"userName",
							   @"password",nil]]];
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
      databaseNames = [(Postgres95Channel*)channel describeDatabaseNames];
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
              BOOL isAdmin = [(Postgres95Channel*)adaptorChannel 
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
	                initWithObjectsAndKeys:[databaseField stringValue],
					       @"databaseName", 
					       [userNameField stringValue],
					       @"userName", 
					       [passwdField stringValue],
					       @"password", 
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
  [databases reloadData];
}


-(void)newDatabase:(id)sender
{
  NSDictionary *connDict;
  NSDictionary *adminDict;
  EOAdaptor *adaptor;
  NSString *reason; 
  
  connDict=[[NSDictionary alloc] 
               initWithObjectsAndKeys:[databaseField stringValue],
	                              @"databaseName",
			              nil];
  adminDict=[[NSDictionary alloc] 
               initWithObjectsAndKeys:@"template1",@"databaseName",
		                      [userNameField stringValue],@"userName",
				      [passwdField stringValue], @"password",
		                      nil];
  adaptor = [EOAdaptor adaptorWithName:@"Postgres95"]; 
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

-(int)numberOfRowsInTableView:(NSTableView *)tableView
{
   return [_databases count];
}

- (void)tableViewSelectionDidChange:(NSNotification *) not
{
  [databaseField setStringValue: 
             [_databases objectAtIndex:
                                [databases selectedRow]]]; 
}

- (id)tableView:(NSTableView *) tableView
      objectValueForTableColumn:(NSTableColumn *) tableColumn
      row:(int) row
{
  return [_databases objectAtIndex:row];
}

@end

