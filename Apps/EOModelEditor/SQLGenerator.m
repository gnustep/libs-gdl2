/**
 SQLGenerator.m 
 
 Author: Matt Rice <ratmice@gmail.com>
 Date: 2005, 2006
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
 This file is part of EOModelEditor.
 
 <license>
 EOModelEditor is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.
 
 EOModelEditor is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with EOModelEditor; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 </license>
 **/

#include "SQLGenerator.h"

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSException.h>
#include <Foundation/NSDictionary.h>
#endif

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/NSNibLoading.h>

#include <AppKit/NSButton.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSSavePanel.h>
#include <AppKit/NSWindow.h>
#endif

#include <Renaissance/Renaissance.h>

#include <EOAccess/EOAdaptor.h>
#include <EOAccess/EOAdaptorChannel.h>
#include <EOAccess/EOAdaptorContext.h>
#include <EOAccess/EOSchemaGeneration.h>
#include <EOAccess/EOSQLExpression.h>
#include <EOAccess/EOModel.h>
#include <EOModeler/EOModelerApp.h>
#include <EOModeler/EOModelerDocument.h>
#include <EOControl/EODebug.h>

#include <GNUstepBase/GNUstep.h>

#include "EOMEDocument.h"

static SQLGenerator *sharedGenerator;
static BOOL loadedNib;
static BOOL goodToGo;
static NSMutableArray *adminSwitchButtons;
static NSMutableArray *otherSwitchButtons;
NSMutableDictionary *opts;
static NSString *_adminScript;
static NSString *_otherScript;

@implementation SQLGenerator : NSObject
+ (SQLGenerator *) sharedGenerator;
{
  if (!sharedGenerator)
    sharedGenerator = [[self allocWithZone:NSDefaultMallocZone()] init];
  return sharedGenerator;
}

- (id) init
{
  if (sharedGenerator)
    {
      [[NSException exceptionWithName:NSInternalInconsistencyException
                               reason: @"singleton initialized multiple times"
                             userInfo:nil] raise];
      return nil;
    }
  self = [super init];
  adminSwitchButtons = [[NSMutableArray alloc] initWithCapacity:3];
  otherSwitchButtons = [[NSMutableArray alloc] initWithCapacity:7];
  opts = [[NSMutableDictionary alloc] initWithCapacity:8];
  loadedNib = [NSBundle loadGSMarkupNamed: @"SQLGenerator" owner: self];
  return self;
}

- (void) dealloc
{
  DESTROY(_document);
  
  [super dealloc];
}


- (void) awakeFromGSMarkup
{
  [[dropDatabaseSwitch cell] setRepresentedObject: EODropDatabaseKey];
  [[createDatabaseSwitch cell] setRepresentedObject: EOCreateDatabaseKey];
  [[dropTablesSwitch cell] setRepresentedObject: EODropTablesKey];
  [[createTablesSwitch cell] setRepresentedObject:EOCreateTablesKey];
  [[dropPKSwitch cell] setRepresentedObject:EODropPrimaryKeySupportKey];
  [[createPKSwitch cell] setRepresentedObject:EOCreatePrimaryKeySupportKey];
  [[createPKConstraintsSwitch cell] setRepresentedObject:EOPrimaryKeyConstraintsKey];
  [[createFKConstraintsSwitch cell] setRepresentedObject:EOForeignKeyConstraintsKey];
  
  [adminSwitchButtons addObject:dropDatabaseSwitch];
  [adminSwitchButtons addObject:createDatabaseSwitch];
  [otherSwitchButtons addObject:dropTablesSwitch];
  [otherSwitchButtons addObject:createTablesSwitch];
  [otherSwitchButtons addObject:dropPKSwitch];
  [otherSwitchButtons addObject:createPKSwitch];
  [otherSwitchButtons addObject:createPKConstraintsSwitch];
  [otherSwitchButtons addObject:createFKConstraintsSwitch];
  goodToGo = YES;
}

- (void) openSQLGeneratorForDocument:(EOMEDocument*)sender
{
  NSString *adaptorName;
  ASSIGN(_document, sender);

  while (loadedNib && !goodToGo)
    {
      /* wait.. */ 
    }
  
  adaptorName = [[_document eomodel] adaptorName];
  if (!adaptorName)
    {
      [_document setAdaptor:self];
    }
  
  adaptorName = [[_document eomodel] adaptorName];

  if (adaptorName)
    [_window makeKeyAndOrderFront:self];
}

- (void)windowWillClose:(NSNotification *)notification
{
  DESTROY(_document);
}

- (IBAction) executeSQL:(id)sender
{
  EOModel   *eomodel = [_document eomodel];
  EOAdaptor *adaptor;
  EOAdaptorContext *context;
  EOAdaptorChannel *channel;
  
  adaptor = [EOAdaptor adaptorWithName: [eomodel adaptorName]];

  Class exprClass = [adaptor expressionClass];
  EOSQLExpression *expr;
  NSDictionary *connDict = [adaptor connectionDictionary];
  
  if ([[_sqlOutput string] length] == 0)
    return;
  
  if (!adaptor)
    {
      [_document setAdaptor:self];
      adaptor = [EOAdaptor adaptorWithName: [eomodel adaptorName]];
      connDict = [adaptor connectionDictionary];
    }
  else if ([[connDict allKeys] count] == 0)
    {
      connDict = [adaptor runLoginPanel];

      if (connDict)
        [adaptor setConnectionDictionary:connDict];
    }
 
  if (!adaptor || [[connDict allKeys] count] == 0)
    {
      NSRunAlertPanel(@"Error",
                      @"SQL generator requires a valid adaptor and connection dictionary",
                      @"Ok",
                      nil,
                      nil);
      return;
    }

  RETAIN(connDict); 
  context = [adaptor createAdaptorContext];
  channel = [context createAdaptorChannel];
 
  /* FIXME 
   * this is a hack for PostgreSQL because it requires you to connect to an
   * existing database to run 'CREATE DATABASE' statements, it should probably
   * not be in EOModelEditor.
   */
  if (_adminScript && [_adminScript length] 
      && [[connDict objectForKey:@"adaptorName"] isEqual:@"PostgreSQLEOAdaptor"])
    {
      NSMutableDictionary *tmp = RETAIN([NSMutableDictionary dictionaryWithDictionary:connDict]);
      [tmp setObject:@"template1" forKey:@"databaseName"];
      [adaptor setConnectionDictionary:tmp];
    }
  
  if (_adminScript && [_adminScript length])
    {
      NS_DURING
      [channel openChannel];
      NS_HANDLER
      NSLog(@"admin exception%@ %@ %@", [localException name], [localException reason], [localException userInfo]);
      NS_ENDHANDLER

      expr = [exprClass expressionForString:_adminScript];
      
      NS_DURING
      [channel evaluateExpression:expr];
      NS_HANDLER
      NSLog(@"admin exception%@ %@ %@", [localException name], [localException reason], [localException userInfo]);
      NS_ENDHANDLER
      
      if ([channel isOpen])
        [channel closeChannel];
    }
  
  if (_otherScript && [_otherScript length])
    {
      [adaptor setConnectionDictionary:connDict];
      NS_DURING
      [channel openChannel];
      NS_HANDLER
      NSLog(@"exception %@ %@ %@", [localException name], [localException reason], [localException userInfo]);
      NS_ENDHANDLER
      
      expr = [exprClass expressionForString:_otherScript];
      
      NS_DURING
      [channel evaluateExpression:expr];
      NS_HANDLER
      NSLog(@"exception %@ %@ %@", [localException name], [localException reason], [localException userInfo]);
      NS_ENDHANDLER
      
      if ([channel isOpen])
        [channel closeChannel];
    }

  RELEASE(connDict);
}

- (IBAction) showTables:(id)sender
{
  NSEmitTODO();
}

- (IBAction) saveAs:(id)sender
{
  id savePanel = [NSSavePanel savePanel];
  int result = [savePanel runModal];
  if (result == NSOKButton)
    {
      NSString *path;
      path = [savePanel filename];
      [[_sqlOutput string] writeToFile:path atomically:YES];
    }
}

- (void) generate
{
  EOModel * model = [_document eomodel];
  Class expr;
  EOAdaptor * adaptor;
  NSArray *arr;
  int i, c;
  NSButton *btn;
  
    
  adaptor = [EOAdaptor adaptorWithName: [model adaptorName]];
  expr = [adaptor expressionClass];
  
  if (!expr)
  {
    [_document setAdaptor:self];
    adaptor = [EOAdaptor adaptorWithName: [model adaptorName]];
    
    expr = [adaptor expressionClass];
    if (!expr) return;
  }
  
  for (i = 0, c = [adminSwitchButtons count]; i < c; i++)
  {
    btn = [adminSwitchButtons objectAtIndex:i];
    [opts setObject:([[btn objectValue] boolValue]) ? @"YES" : @"NO"
             forKey: [[btn cell] representedObject]];
  }
  
  for (i = 0, c = [otherSwitchButtons count]; i < c; i++)
  {
    btn = [otherSwitchButtons objectAtIndex:i];
    [opts setObject:@"NO" forKey:[[btn cell] representedObject]];
  }
  
  arr = [model entities];
  _adminScript = RETAIN([expr schemaCreationScriptForEntities:arr
                                                      options:opts]);
  
  for (i = 0, c = [adminSwitchButtons count]; i < c; i++)
  {
    btn = [adminSwitchButtons objectAtIndex:i];
    [opts setObject:@"NO" forKey:[[btn cell] representedObject]];
  }
  
  for (i = 0, c = [otherSwitchButtons count]; i < c; i++)
  {
    btn = [otherSwitchButtons objectAtIndex:i];
    [opts setObject:([[btn objectValue] boolValue]) ? @"YES" : @"NO"
             forKey: [[btn cell] representedObject]];
  }
  
  arr = [model entities];
  _otherScript = RETAIN([expr schemaCreationScriptForEntities:arr
                                                      options:opts]);
  
  [_sqlOutput setString:[_adminScript stringByAppendingString:_otherScript]];
}



- (IBAction) switchChanged:(id)sender
{
  RELEASE(_adminScript);
  RELEASE(_otherScript);
  [self generate];
}

@end
