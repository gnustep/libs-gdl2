/*
   EODisplayGroup.m

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: David Ayers <d.ayers@inode.at>

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

#include "config.h"

RCS_ID("$Id$")


#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSValue.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <EOControl/EODataSource.h>
#include <EOControl/EOQualifier.h>

#include "EODisplayGroup.h"
/*
#include "EOAssociation.h"
*/


@implementation EODisplayGroup

 /* TODO: Check default setting */
static NSString *_globalDefaultStringMatchOperator = nil;
+ (NSString *)globalDefaultStringMatchOperator
{
  return _globalDefaultStringMatchOperator;
}
+ (void)setGlobalDefaultStringMatchOperator: (NSString *)operator
{
  ASSIGNCOPY(_globalDefaultStringMatchOperator, operator);
}

/* TODO: Check default setting */
static BOOL _globalDefaultForValidatesChangesImmediately= NO;
+ (BOOL)globalDefaultForValidatesChangesImmediately
{
  return _globalDefaultForValidatesChangesImmediately;
}
+ (void)setGlobalDefaultForValidatesChangesImmediately: (BOOL)flag
{
  _globalDefaultForValidatesChangesImmediately = flag ? YES : NO;
}

- (id)init
{
  if ((self = [super init]))
    {
    }
  return self;
}

- (void)dealloc
{
  DESTROY(_dataSource);
  DESTROY(_allObjects);
  DESTROY(_displayedObjects);

  DESTROY(_selection);
  DESTROY(_sortOrdering);
  DESTROY(_qualifier);
  DESTROY(_localKeys);
  DESTROY(_selectedObjects);
  DESTROY(_observerNotificationBeginProxy);
  DESTROY(_observerNotificationEndProxy);
  DESTROY(_insertedObjectDefaultValues);
  DESTROY(_savedAllObjects);
  DESTROY(_queryMatch);
  DESTROY(_queryMin);
  DESTROY(_queryMax);
  DESTROY(_queryOperator);
  DESTROY(_defaultStringMatchOperator);
  DESTROY(_defaultStringMatchFormat);
  DESTROY(_queryBindings);
  DESTROY(_editingAssociation);

  [super dealloc];
}

- (id)initWithCoder: (NSCoder *)coder
{
  return [self init];
}
- (void)encodeWithCoder: (NSCoder *)coder
{
}

- (BOOL)fetchesOnLoad
{
  return _flags.autoFetch;
}
- (void)setFetchesOnLoad: (BOOL)flag
{
  _flags.autoFetch = flag ? YES : NO;
}

- (BOOL)selectsFirstObjectAfterFetch
{
  return _flags.selectsFirstObjectAfterFetch;
}
- (void)setSelectsFirstObjectAfterFetch: (BOOL)flag
{
  _flags.selectsFirstObjectAfterFetch = flag ? YES : NO;
}

- (BOOL)validatesChangesImmediately
{
  return _flags.validateImmediately;
}
- (void)setValidatesChangesImmediately: (BOOL)flag
{
  _flags.validateImmediately = flag ? YES : NO;
}

- (BOOL)usesOptimisticRefresh
{
  return _flags.optimisticRefresh;
}
- (void)setUsesOptimisticRefresh: (BOOL)flag
{
  _flags.optimisticRefresh = flag ? YES : NO;
}

- (NSDictionary *)queryBindingValues
{
  return AUTORELEASE([_queryBindings copy]);
}
- (void)setQueryBindingValues: (NSDictionary *)values
{
  ASSIGN(_queryBindings, [values mutableCopyWithZone: [self zone]]);
}

- (NSDictionary *)queryOperatorValues
{
  return AUTORELEASE([_queryOperator copy]);
}
- (void)setQueryOperatorValues: (NSDictionary *)values
{
  ASSIGN(_queryOperator,
	 AUTORELEASE([values mutableCopyWithZone: [self zone]]));
}

- (NSString *)defaultStringMatchFormat
{
  return _defaultStringMatchFormat;
}
- (void)setDefaultStringMatchFormat: (NSString *)format
{
  ASSIGNCOPY(_defaultStringMatchFormat, format);
}

- (NSString *)defaultStringMatchOperator
{
  return _defaultStringMatchOperator;
}
- (void)setDefaultStringMatchOperator: (NSString *)operator
{
  ASSIGNCOPY(_defaultStringMatchOperator, operator);
}

- (EODataSource *)dataSource
{
  return _dataSource;
}
- (void)setDataSource: (EODataSource *)dataSource
{
  ASSIGN(_dataSource, dataSource);
}

- (EOQualifier *)qualifier
{
  return _qualifier;
}
- (void)setQualifier: (EOQualifier *)qualifier
{
  ASSIGN(_qualifier, qualifier);
}

- (NSArray *)sortOrderings
{
  return _sortOrdering;
}
- (void)setSortOrderings: (NSArray *)orderings
{
  ASSIGNCOPY(_sortOrdering, orderings);
}

- (EOQualifier *)qualifierFromQueryValues
{
  return nil;
}

- (NSDictionary *)equalToQueryValues
{
  return nil;
}
- (void)setEqualToQueryValues: (NSDictionary *)values
{
}

- (NSDictionary *)greaterThanQueryValues
{
  return nil;
}
- (void)setGreaterThanQueryValues: (NSDictionary *)values
{
}

- (NSDictionary *)lessThanQueryValues
{
  return nil;
}
- (void)setLessThanQueryValues: (NSDictionary *)values
{
}

- (void)qualifyDisplayGroup
{
}
- (void)qualifyDataSource
{
}

- (BOOL)inQueryMode
{
  return _flags.queryMode;
}
- (void)setInQueryMode: (BOOL)flag
{
  _flags.queryMode = flag ? YES : NO;
}

- (BOOL)fetch
{
  return NO;
}

- (NSArray *)allObjects
{
  return AUTORELEASE([_allObjects copy]);
}
- (void)setObjectArray: (NSArray *)objects
{
  ASSIGN(_allObjects,
	 AUTORELEASE([objects mutableCopyWithZone: [self zone]]));
}
- (NSArray *)displayedObjects
{
  return AUTORELEASE([_displayedObjects copy]);
}

- (void)redisplay
{
}
- (void)updateDisplayedObjects
{
}

- (NSArray *)selectionIndexes
{
  return nil;
}

- (BOOL)setSelectionIndexes: (NSArray *)selection
{
  return NO;
}

- (BOOL)selectObject: (id)object
{
  return NO;
}
- (BOOL)selectObjectsIdenticalTo: (NSArray *)selection
{
  return NO;
}
- (BOOL)selectObjectsIdenticalTo: (NSArray *)selection 
	    selectFirstOnNoMatch: (BOOL)flag
{
  return NO;
}

- (BOOL)selectNext
{
  return NO;
}
- (BOOL)selectPrevious
{
  return NO;
}

- (BOOL)clearSelection
{
  return NO;
}

- (NSArray *)selectedObjects
{
  return nil;
}
- (void)setSelectedObjects: (NSArray *)objects
{
}

- (id)selectedObject
{
  return nil;
}
- (void)setSelectedObject: (id)object
{
}

- (id)insertObjectAtIndex: (unsigned)index
{
  return nil;
}
- (void)insertObject: (id)object atIndex: (unsigned)index
{
}

- (NSDictionary *)insertedObjectDefaultValues
{
  return _insertedObjectDefaultValues;
}
- (void)setInsertedObjectDefaultValues: (NSDictionary *)values
{
  ASSIGNCOPY(_insertedObjectDefaultValues, values);
}

- (BOOL)deleteObjectAtIndex: (unsigned)index
{
  return NO;
}
- (BOOL)deleteSelection
{
  return NO;
}

- (NSArray *)localKeys
{
  return _localKeys;
}
- (void)setLocalKeys: (NSArray *)keys
{
  ASSIGNCOPY(_localKeys, keys);
}

- (id)delegate
{
  return _delegate;
}
- (void)setDelegate: (id)delegate
{
  _delegate = delegate;
}

- (NSArray *)observingAssociations
{
  return nil;
}
- (EOAssociation *)editingAssociation
{
  return _editingAssociation;
}
- (BOOL)endEditing
{
  return NO;
}

@end

@implementation EODisplayGroup (EODisplayGroupTargetAction)
/* TODO: check for return value handling and exception handling.  */
- (void)selectNext: (id)sender
{
  [self selectNext];
}
- (void)selectPrevious: (id)sender
{
  [self selectPrevious];
}

- (void)fetch: (id)sender
{
  [self fetch];
}
- (void)insert: (id)sender
{
  NSArray *selections = [self selectionIndexes];
  NSNumber *index = [selections lastObject];
  unsigned idx = [index unsignedIntValue];
  [self insertObjectAtIndex: idx];
}
- (void)delete: (id)sender
{
  [self deleteSelection];
}

- (void)qualifyDataSource: (id)sender
{
  [self qualifyDataSource];
}
- (void)qualifyDisplayGroup: (id)sender
{
  [self qualifyDisplayGroup];
}

- (void)enterQueryMode: (id)sender
{
  [self setInQueryMode: YES];
}

@end

@implementation EODisplayGroup (EOAssociationInteraction)

- (BOOL)selectionChanged
{
  return NO;
}
- (BOOL)contentsChanged
{
  return NO;
}
- (int)updatedObjectIndex
{
  return 0;
}

- (id)valueForObject: (id)object key: (NSString *)key
{
  return nil;
}
- (id)selectedObjectValueForKey: (NSString *)key
{
  return nil;
}

- (id)valueForObjectAtIndex: (unsigned)index key: (NSString *)key
{
  return nil;
}

- (BOOL)setValue: (id)value forObject: (id)object key: (NSString *)key
{
  return NO;
}

- (BOOL)setSelectedObjectValue: (id)value forKey: (NSString *)key
{
  return NO;
}

- (BOOL)setValue: (id)value forObjectAtIndex: (unsigned)index 
	     key: (NSString *)key
{
  return NO;
}

- (BOOL)enabledToSetSelectedObjectValueForKey:(NSString *)key
{
  return NO;
}

- (BOOL)association: (EOAssociation *)association 
failedToValidateValue: (NSString *)value
	     forKey: (NSString *)key 
	     object: (id)object
   errorDescription: (NSString *)description
{
  return NO;
}
- (void)associationDidBeginEditing: (EOAssociation *)association
{
}
- (void)associationDidEndEditing: (EOAssociation *)association
{
}

@end

@implementation EODisplayGroup (EOEditors)
- (BOOL)editorHasChangesForEditingContext: (EOEditingContext *)editingContext
{
  return NO;
}
- (void)editingContextWillSaveChanges: (EOEditingContext *)editingContext
{
}
@end

@implementation EODisplayGroup (EOMessageHandlers)
- (void)editingContext: (EOEditingContext *)editingContext
   presentErrorMessage: (NSString *)message
{
}
@end


