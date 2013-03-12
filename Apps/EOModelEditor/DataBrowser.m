/**
 DataBrowser.h <title>EOMEDocument Class</title>
 
 Copyright (C) Free Software Foundation, Inc.
 
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

#import "DataBrowser.h"
#import <Renaissance/Renaissance.h>
#import "TableViewController.h"
#import <EOControl/EOControl.h>

static DataBrowser *sharedDataBrowser = nil;

@implementation DataBrowser

- (NSWindow*) _window
{
  return _window;
}

+ (DataBrowser *) sharedBrowser;
{
  if (!sharedDataBrowser)
    sharedDataBrowser = [[self alloc] init];

  [[sharedDataBrowser _window] makeKeyAndOrderFront:nil];
  
  return sharedDataBrowser;
}

- (id) init
{
  if (sharedDataBrowser)
  {
    [[NSException exceptionWithName:NSInternalInconsistencyException
                             reason: @"singleton initialized multiple times"
                           userInfo:nil] raise];
    return nil;
  }
  self = [super init];

  [NSBundle loadGSMarkupNamed: @"DataBrowser" owner: self];

  [_window setFrameUsingName:NSStringFromClass([self class])];

  _tableViewController = [TableViewController new];
  [_tableView setDataSource:_tableViewController];
  [_tableView setDelegate:_tableViewController];
  
  
  return self;
}

- (void) removeTableColumns
{
  NSArray        * columns = [_tableView tableColumns];
  NSEnumerator   * colEnumer = [[NSArray arrayWithArray:columns] objectEnumerator];
  NSTableColumn  * column;
   
  while ((column = [colEnumer nextObject])) {
    if ([[column identifier] isEqual:@"_#number"] == NO) {
      [_tableView removeTableColumn:column];
    }
  }
  
}

- (void) setEntity:(EOEntity*) aValue
{
  ASSIGN(_currentEntity, aValue);
  
  if (_currentEntity)  {
    NSEnumerator   * attributeEnumer = [[_currentEntity attributes] objectEnumerator];
    EOAttribute    * currentAttribute = nil;
    
    [_tableViewController setRepresentedObject:[NSArray array]];
    [_tableView reloadData];

    [self removeTableColumns];
    [_entityNameField setStringValue:[_currentEntity name]];
    
    while ((currentAttribute = [attributeEnumer nextObject])) {
      NSString      * attributeName = [currentAttribute name];
      NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:attributeName];
      
      [[column headerCell] setStringValue:attributeName];
      [column setEditable:NO];
      
      [_tableView addTableColumn:column];
      RELEASE(column);
    }

  }

}

- (void) dealloc
{
  sharedDataBrowser = nil;

  DESTROY(_tableViewController);
  DESTROY(_currentEntity);
  DESTROY(_editingContext);
  
  [super dealloc];
}

- (void) awakeFromGSMarkup
{
}

- (IBAction) fetch:(id) sender
{
  EOFetchSpecification	*fetchSpec;
  EOQualifier           *qual = nil;
  NSArray               *results;
  NSMutableArray        *keyPaths = [NSMutableArray array];
  NSEnumerator          *attributeEnumer = [[_currentEntity attributes] objectEnumerator];
  EOAttribute           *attribute;
  
  
  while ((attribute = [attributeEnumer nextObject])) {
    [keyPaths addObject:[attribute name]];
  }
  
  [[EOModelGroup defaultGroup] addModel:[_currentEntity model]];
  
  NS_DURING {
    
    if (!_editingContext) {
      ASSIGN(_editingContext, [EOEditingContext new]);
      RELEASE(_editingContext);
      [_editingContext setInvalidatesObjectsWhenFreed:YES];
    } else {
      [_editingContext invalidateAllObjects];
    }
    
    if ([[qualifierText stringValue] length] > 0)
      qual = [EOQualifier qualifierWithQualifierFormat:[qualifierText stringValue]];
    
    fetchSpec = [EOFetchSpecification fetchSpecificationWithEntityName:[_currentEntity name]
                                                             qualifier:qual
                                                         sortOrderings:nil];
    
    [fetchSpec setFetchLimit:[fetchLimitText intValue]];

    [fetchSpec setRawRowKeyPaths:keyPaths];
    
    results = [_editingContext objectsWithFetchSpecification:fetchSpec];
    
    [_tableViewController setRepresentedObject:results];
    [_tableView reloadData];
    
  } NS_HANDLER {
    NSRunCriticalAlertPanel (@"Problem fetching from Database",
                             @"%@",
                             @"Ok",
                             nil,
                             nil,
                             localException);
  } NS_ENDHANDLER;
  
  [[EOModelGroup defaultGroup] removeModel:[_currentEntity model]];
  
}

- (BOOL)windowShouldClose:(id)sender
{  
  [_window endEditingFor:self];
    
  [_window saveFrameUsingName:NSStringFromClass([self class])];

  [_window setDelegate:nil];
  [_window orderOut:self];
  [self performSelector:@selector(release) withObject:self afterDelay:0.001];
  
  return YES;
}

@end
