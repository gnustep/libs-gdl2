/** -*-ObjC-*-
   Postgres95LoginPanel.m

   Copyright (C) 2004 Free Software Foundation, Inc.

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. 
*/

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <EOAccess/EOAccess.h>
#include "Postgres95LoginPanel.h"

static BOOL insideModalLoop;

@implementation Postgres95LoginPanel : EOLoginPanel
- (void) dealloc
{
  RELEASE(_databases);
  RELEASE(_win);
}
- (id)init
{
  if ((self = [super init]))
    {
      NSTableColumn *tableColumn;
      float spacer = 3.0;
      float textHeight = 25.0;
      float textWidth = 75.0;
      float scrollerSize = (textWidth*2)+spacer;
      float winWidth = (textWidth*4)+(spacer*6);
      float winHeight = (scrollerSize+(spacer*3)+textHeight);
      NSSize screenSize = [[NSScreen mainScreen] frame].size;
      NSRect winRect = NSMakeRect((screenSize.width/2) - (winWidth/2),
                                  (screenSize.height/2) - (winHeight/2),
				  winWidth,winHeight);
      _databases = nil;
      _win = [[NSWindow alloc]
                  initWithContentRect: winRect 
                            styleMask: NSTitledWindowMask
                              backing: NSBackingStoreRetained
                                defer: YES];
      [_win setTitle: @"Postgresql logon"];
      [_win setDelegate:self]; 
      tableScrollView = [[NSScrollView alloc] initWithFrame:
                           NSMakeRect(spacer,
                                      spacer,
			              scrollerSize,
				      scrollerSize)];
      [tableScrollView setHasHorizontalScroller:YES];
      [tableScrollView setHasVerticalScroller:YES];
      [[_win contentView] addSubview:tableScrollView];  
      RELEASE(tableScrollView);
       
      databases = [[NSTableView alloc] initWithFrame: [tableScrollView bounds]];
      [databases setDataSource:self];
      [databases setDelegate:self];
      [databases setAllowsColumnSelection:NO];
      [databases setAutoresizesAllColumnsToFit:YES]; 
      [databases setTarget:self]; 
      [databases setAction:@selector(tableAction:)];
      [databases setDoubleAction:@selector(doubleAction:)];
       
      [tableScrollView setDocumentView: databases]; 
      RELEASE(databases);
       
      tableColumn = [[NSTableColumn alloc] initWithIdentifier: @"Databases"];
      [[tableColumn headerCell] setStringValue:@"Databases"];    
      [tableColumn setEditable:NO];
      /* there's probably a correct way to do this.. -+
                                                      v */
      [tableColumn setMinWidth: scrollerSize - [[databases headerView] frame].size.width];
      [tableColumn setResizable:YES];
      [databases addTableColumn: tableColumn]; 
      RELEASE(tableColumn); 
      
      userNameLabel = [[NSTextField alloc] initWithFrame:
                         NSMakeRect(scrollerSize+(spacer*2),
                                    winRect.size.height-textHeight-spacer,
			            textWidth,
				    textHeight)];
      [userNameLabel setStringValue:@"login: "]; 
      [userNameLabel setAlignment:NSRightTextAlignment];
      [userNameLabel setEditable:NO]; 
      [userNameLabel setSelectable:NO]; 
      [userNameLabel setDrawsBackground:NO]; 
      [userNameLabel setBordered:NO];
      [userNameLabel setBezeled:NO];
      [[_win contentView] addSubview: userNameLabel];
      RELEASE(userNameLabel);

      passwdLabel = [[NSTextField alloc] initWithFrame:
                      NSMakeRect(scrollerSize+(spacer*2),
                                 winRect.size.height-(textHeight*2)-(spacer*2),
			         textWidth,
			         textHeight)];
      [passwdLabel setStringValue:@"password: "];
      [passwdLabel setAlignment:NSRightTextAlignment];
      [passwdLabel setEditable:NO];
      [passwdLabel setSelectable:NO];
      [passwdLabel setDrawsBackground:NO];
      [passwdLabel setBordered:NO];
      [passwdLabel setBezeled:NO];
      [[_win contentView] addSubview: passwdLabel];
      RELEASE(passwdLabel);

      databaseLabel = [[NSTextField alloc] initWithFrame: 
                       NSMakeRect(scrollerSize+(spacer*2),
                                  winRect.size.height-(textHeight*3)-(spacer*3),
		                  textWidth,
			          textHeight)];
      [databaseLabel setStringValue:@"database: "];
      [databaseLabel setAlignment:NSRightTextAlignment];
      [databaseLabel setEditable:NO];
      [databaseLabel setSelectable:NO];
      [databaseLabel setDrawsBackground:NO];
      [databaseLabel setBordered:NO];
      [databaseLabel setBezeled:NO];
      [[_win contentView] addSubview: databaseLabel];
      RELEASE(databaseLabel);
      
      userNameField = [[NSTextField alloc] initWithFrame:
                    NSMakeRect(winRect.size.width-textWidth-spacer,
                               winRect.size.height-textHeight-spacer,
			       textWidth,
			       textHeight)];
      [userNameField setStringValue:NSUserName()]; 
      [[_win contentView] addSubview: userNameField];
      RELEASE(userNameField);
      
      showDatabasesButton = 
        [[NSButton alloc] initWithFrame:
             NSMakeRect(spacer,
		        scrollerSize+(spacer*2),
		        textWidth, textHeight)];
      [showDatabasesButton setTarget:self];
      [showDatabasesButton setAction:@selector(showDatabases:)];
      [showDatabasesButton setTitle:@"Select DB"];
      [showDatabasesButton setEnabled:YES];
      [[_win contentView] addSubview: showDatabasesButton];
      RELEASE(showDatabasesButton);

      newDatabaseButton = 
          [[NSButton alloc] initWithFrame:
             NSMakeRect((spacer *2)+(textWidth),
			scrollerSize+(spacer*2), 
                        textWidth,textHeight)];
      [newDatabaseButton setTarget:self];
      [newDatabaseButton setAction:@selector(newDatabase:)];
      [newDatabaseButton setTitle:@"New"];
      [newDatabaseButton setEnabled:NO];
      [[_win contentView] addSubview: newDatabaseButton];
      RELEASE(newDatabaseButton);		

      passwdField = [[NSSecureTextField alloc] initWithFrame:
                   NSMakeRect(winRect.size.width-textWidth-spacer,
                              winRect.size.height-(textHeight*2)-(spacer*2),
			      textWidth,textHeight)];
      [[_win contentView] addSubview: passwdField];
      RELEASE(passwdField);
      
      databaseField = [[NSTextField alloc] initWithFrame:
                    NSMakeRect(winRect.size.width-textWidth-spacer,
                               winRect.size.height-(textHeight*3)-(spacer*3),
			       textWidth,textHeight)]; 
      [[_win contentView] addSubview: databaseField];
      RELEASE(databaseField);
     
      okButton = [[NSButton alloc] initWithFrame: 
               NSMakeRect(winRect.size.width-textWidth-(spacer),
                          winRect.size.height-scrollerSize-textHeight-(spacer*2),
			  textWidth,textHeight)];
      [okButton setTitle:@"Ok"]; 
      [okButton setTarget:self]; 
      [okButton setAction:@selector(ok:)];
      [[_win contentView] addSubview: okButton];
      RELEASE(okButton); 
      
      cancelButton = [[NSButton alloc] initWithFrame:
                   NSMakeRect(winRect.size.width-(textWidth*2)-(spacer*2),
                              winRect.size.height-scrollerSize-textHeight-(spacer*2),
			      textWidth,textHeight)];
      [cancelButton setTitle:@"Cancel"]; 
      [cancelButton setTarget:self]; 
      [cancelButton setAction:@selector(cancel:)];
      [[_win contentView] addSubview: cancelButton];
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

