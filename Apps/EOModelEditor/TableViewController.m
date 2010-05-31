/**
 TableViewController.m <title>EOMEDocument Class</title>
 
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

#import "TableViewController.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#ifndef GNUSTEP
#import <GNUstepBase/GNUstep.h>
#endif

@implementation TableViewController

- (void) dealloc
{
  DESTROY(_boolColumnNames);
  
  [super dealloc];
}

- (id) init
{
  self = [super init];
  if (self != nil) {
    ASSIGN(_boolColumnNames, [NSMutableSet set]);
  }
  return self;
}

- (NSArray*) selectedObjects
{
  NSMutableArray * array = [NSMutableArray array];
  NSArray        * repObject = [self representedObject]; 
  
  if (_tableView) {
    NSIndexSet     * selectedIndexes = nil;
    selectedIndexes = [_tableView selectedRowIndexes];
    
    if ([selectedIndexes count] > 0) {
      NSUInteger  currentIdx = [selectedIndexes firstIndex];
      [array addObject:[repObject objectAtIndex:currentIdx]];
      
      while ((currentIdx = [selectedIndexes indexGreaterThanIndex:currentIdx]) && (currentIdx != NSNotFound)) 
      {
        [array addObject:[repObject objectAtIndex:currentIdx]];
      }
    }
  }
  return array;
}

- (void) addToBoolColumnNames:(NSString *) aValue
{
  [_boolColumnNames addObject:aValue];
}

- (NSSet*) boolColumnNames
{
  return _boolColumnNames;
}

// representedObject should be anArray like the attributes of an EOEntity

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
  NSArray * representedObject = (NSArray*) [self representedObject];
  
  _tableView = aTableView;
  
  if (!representedObject) {
    return 0;
  }
  return [representedObject count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column 
            row:(NSInteger)row
{
  NSArray * representedObject = (NSArray*) [self representedObject];
  id obj, value, identifier;

  if (!representedObject) {
    return nil;
  }
  
  obj = [representedObject objectAtIndex:row];
  identifier = [column identifier];
  
  // special case to support row numbering
  if ([identifier isEqual:@"_#number"]) {
    return [NSNumber numberWithInteger:row];
  }
  value = [obj valueForKeyPath:identifier];
  
  if ([_boolColumnNames containsObject:identifier]) {
    return [NSNumber numberWithInteger:([value boolValue] ? NSOnState : NSOffState)];
  }
    
  return value;
}

- (void)tableView:(NSTableView *)tableView 
   setObjectValue:(id)value 
   forTableColumn:(NSTableColumn *)column 
              row:(NSInteger)row 
{          
  id obj = [[self representedObject] objectAtIndex:row];
  NSString * identifier = [column identifier];
  NSNotificationCenter * defaultCenter = [NSNotificationCenter defaultCenter];
  id oldVaue = [obj valueForKeyPath:identifier];
  id newValue = value;
  NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                             (oldVaue) ? oldVaue : [NSNull null], @"oldValue",
                             (newValue) ? newValue : [NSNull null], @"newValue",
                             identifier, @"keyPath",
                             nil];
  
  [obj setValue:value
     forKeyPath:identifier];
  
  
  [defaultCenter postNotificationName:TableViewDataHasChangedNotification 
                               object:self 
                             userInfo:userInfo];
}

@end
