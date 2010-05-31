
/*
 ConnectionDictionaryInspector.m
 
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
 This file is part of EOModelEditor.
 
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
 */

#include "ConnectionDictionaryInspector.h"

#include <EOAccess/EOEntity.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EOAttribute.h>

#include <EOModeler/EOModelerApp.h>
#include "../EOMEDocument.h"
#include "../EOMEEOAccessAdditions.h"

#include <Foundation/Foundation.h>

#import "../TableViewController.h"

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#endif

@implementation ConnectionDictionaryInspector

- (NSString *) displayName
{
  return @"Connection Dictionary";
}

- (void) dealloc
{
  DESTROY(_dataArray);
  DESTROY(_tableViewController);
  DESTROY(_selectedDict);

  [super dealloc];
}


- (void) awakeFromGSMarkup
{
  _tableViewController = [TableViewController new];

  [_tableView setDataSource:_tableViewController];
  [_tableView setDelegate:_tableViewController];
  [_textView setRichText:NO];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tableViewSelectionDidChange:) 
                                               name:NSTableViewSelectionDidChangeNotification 
                                             object:_tableView];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textDidChange:) 
                                               name:NSTextDidChangeNotification 
                                             object:_textView];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(tableViewDataDidChange:) 
                                               name:TableViewDataHasChangedNotification 
                                             object:_tableViewController];
  
}

- (float) displayOrder
{
  return 1;
}

- (BOOL) canInspectObject:(id)anObject
{
  BOOL weCan = [anObject isKindOfClass:[EOModel class]];
  return weCan;
}

- (void) commitChanges
{
  NSMutableDictionary * mDict = [NSMutableDictionary dictionary];
  
  if ((_dataArray) && ([_dataArray count])) {
    NSEnumerator * aEnumer = [_dataArray objectEnumerator];
    NSDictionary * myDict = nil;
    
    while ((myDict = [aEnumer nextObject])) {
      [mDict setObject:[myDict objectForKey:@"value"]
                forKey:[myDict objectForKey:@"key"]];
    }

  }
  [(EOModel *)[self selectedObject] setConnectionDictionary:mDict];
}


- (void) setDataFromDictionary:(NSDictionary*) aDictionary
{
  NSEnumerator * keyEnumer;
  NSString     * currentKey;
    
  DESTROY(_dataArray);
  _dataArray = [NSMutableArray array];
  RETAIN(_dataArray);
  
  // make sure we are using ordered keys.
  keyEnumer = [[[aDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
  
  while ((currentKey = [keyEnumer nextObject])) {
    NSMutableDictionary * mDict;
    
    mDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
             [aDictionary objectForKey:currentKey], @"value",
             currentKey,@"key", nil];
    
    [_dataArray addObject:mDict];
  }
  
  [_tableViewController setRepresentedObject:_dataArray];
  [_tableView reloadData];
  [_textView setString:@""];        

}

- (void) refresh
{  
  [self setDataFromDictionary:[(EOModel *)[self selectedObject] connectionDictionary]];
  DESTROY(_selectedDict);

}

- (void) textDidChange:(NSNotification *)notif
{
  id obj = [notif object];
  
  if (_selectedDict) {
    if ((obj == _textView)) {
      // I dont know why that stringWithString is needed here,
      // but it seems to fix an OSX bug that messes up values -- dw
      [_selectedDict setObject:[NSString stringWithString:[_textView string]]
                        forKey:@"value"];
      [_tableView reloadData];
      [self commitChanges];
    } 
  }
  
}

- (IBAction) add:(id) sender
{
  NSMutableDictionary * mDict;
  NSUInteger  aCount = [_dataArray count];
  
  mDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
           @"newValue", @"value",
           [NSString stringWithFormat:@"newKey%d", aCount],@"key", nil];
  
  [_dataArray addObject:mDict];
  [_tableView reloadData];
}

- (IBAction) remove:(id) sender
{
  [_dataArray removeObjectsInArray:[_tableViewController selectedObjects]];
  [_tableView reloadData];
  [self commitChanges];
}

- (IBAction) tableViewClicked:(id) sender
{
}

- (void)tableViewSelectionDidChange:(NSNotification *) notification
{
  NSArray * selectedObjects = nil;
  
  selectedObjects = [_tableViewController selectedObjects];
  
  if ([selectedObjects count] > 0) {
    NSMutableDictionary * dict = [selectedObjects objectAtIndex:0];
    NSString * value = [dict objectForKey:@"value"];
    
    ASSIGN(_selectedDict, dict);
    
    [_textView setString:(value) ? value : @""];        
  } else {
    DESTROY(_selectedDict);
  }

  
}

- (void) tableViewDataDidChange: (NSNotification*) notification
{
  NSDictionary * userInfo = [notification userInfo];

  if ([[userInfo objectForKey:@"keyPath"] isEqual:@"value"]) {
    [_textView setString:[userInfo objectForKey:@"newValue"]];        
  }
  [self commitChanges];
  
}


@end

