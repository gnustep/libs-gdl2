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
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSPanel.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include <EOControl/EOClassDescription.h>
#include <EOControl/EODataSource.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EOObserver.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOSortOrdering.h>

#include "EODisplayGroup.h"
#include "EODeprecated.h"
#include "EOAssociation.h"

#include <limits.h>

#define DG_SHOULD_CHANGE_SELECTION_TO_IDX \
     @selector(displayGroup:shouldChangeSelectionToIndexes:)
#define DG_DISPLAY_ARRAY_FOR_OBJECTS \
     @selector(displayGroup:displayArrayForObjects:)
#define DG_SHOULD_DISPLAY_ALERT \
     @selector(displayGroup:shouldDisplayAlertWithTitle:message:)
#define DG_DID_FETCH_OBJECTS \
     @selector(displayGroup:didFetchObjects:)
#define DG_CREATE_OBJECT_FAILED \
     @selector(displayGroup:createObjectFailedForDataSource:)
#define DG_SHOULD_INSERT_OBJECT \
     @selector(displayGroup:shouldInsertObject:atIndex:)
#define DG_DID_INSERT_OBJECT \
     @selector(displayGroup:didInsertObject:)
#define DG_DID_CHANGE_SELECTION \
     @selector(displayGroupDidChangeSelection:)
/* undocumented notification */

NSString *EODisplayGroupWillFetchNotification = @"EODisplayGroupWillFetch";

@interface EOIEmptyArray : NSArray
@end

@implementation EOIEmptyArray : NSArray
- (void) release
{
  [super release];
}
- (void) dealloc
{
  [super dealloc];
}
- (id) autorelease
{
  return [super autorelease];
}
@end
@interface GSInlineArray : NSObject
@end
@implementation GSInlineArray(foo)
- (void) release
{  
  
}
- (void) dealloc
{

}

- (id) autorelease
{
  return self;
}
@end
@interface NSArray (private)
- (NSArray *)indexesForObjectsIndenticalTo: (NSArray *)array;
@end
@implementation NSArray (private)
- (NSArray *)indexesForObjectsIndenticalTo: (NSArray *)array
{
  unsigned idx, i, c = [array count];
  NSMutableArray *indices = (id)[NSMutableArray arrayWithCapacity: c];
  id object;
  NSNumber *number;

  for (i = 0; i < c; i++)
    {
      object = [array objectAtIndex: i];
      idx = [self indexOfObjectIdenticalTo: object];
      if (idx != NSNotFound)
	{
	  /* We should cache all these numbers.  */
	  number = [NSNumber numberWithUnsignedInt: idx];
	  [indices addObject: number];
	}
    }
  return AUTORELEASE ([indices copy]);
}
@end

@interface EODisplayGroup (private)
- (void)_presentAlertWithTitle:(NSString *)title
		       message:(NSString *)message;
@end

@implementation EODisplayGroup (private)
- (void)_presentAlertWithTitle:(NSString *)title
		       message:(NSString *)message
{
  if (_delegate
      && [_delegate respondsToSelector: DG_SHOULD_DISPLAY_ALERT]
      && [_delegate displayGroup: self
		    shouldDisplayAlertWithTitle: title
		    message: message] == NO)
    {
      return;
    }
  NSRunAlertPanel(title, message, nil, nil, nil);
}

@end

/**
 * The EODisplayGoup keeps track of all enterprise objects from
 * a particular EODataSource to coordinate their internal state
 * with other objects such as UI elements and other EODisplayGroups.
 * Commonly the data source is a EODatabaseDataSource (EOAccess)
 * which manages the objects of a single entity for a specific
 * editing context.  The display group is connected to the UI elements
 * or other display groups via EOAssociations.  This framework is
 * responsible to update the enterprise objects when the contents
 * and state of the UI elements are changed and to update the UI
 * elements when the state of the enterprise objects are changed.
 */

@implementation EODisplayGroup

static EOIEmptyArray *emptyArray;
static NSDictionary *emptyDictionary;
+ (void)initialize
{
  if (emptyArray == nil)
    {
      emptyArray = [NSArray new];
      emptyDictionary = [NSDictionary new];
    }
}

static NSString *_globalDefaultStringMatchOperator = @"caseInsensitiveLike";
+ (NSString *)globalDefaultStringMatchOperator
{
  return _globalDefaultStringMatchOperator;
}
+ (void)setGlobalDefaultStringMatchOperator: (NSString *)operator
{
  ASSIGNCOPY(_globalDefaultStringMatchOperator, operator);
}

static BOOL _globalDefaultForValidatesChangesImmediately = NO;
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
      _allObjects = [NSMutableArray new];
      _displayedObjects = [NSMutableArray new];

      _selection = emptyArray;
      _observerNotificationBeginProxy 
	= [[EOObserverProxy alloc] initWithTarget: self
				   action:
				     @selector(_beginObserverNotification:)
				   priority: EOObserverPriorityFirst];
      [EOObserverCenter addObserver: _observerNotificationBeginProxy
      			  forObject: self];
      
      _observerNotificationEndProxy
	= [[EOObserverProxy alloc] initWithTarget: self
				   action:
				     @selector(_endObserverNotification:)
				   priority: EOObserverPrioritySixth];
      [EOObserverCenter addObserver: _observerNotificationEndProxy
      			  forObject: self];

      _insertedObjectDefaultValues = emptyDictionary;

      _queryMatch = [NSMutableDictionary new];
      _queryMin = [NSMutableDictionary new];
      _queryMax = [NSMutableDictionary new];
      _queryOperator = [NSMutableDictionary new];

      _defaultStringMatchOperator 
	= [[self class] globalDefaultStringMatchOperator];
      _defaultStringMatchFormat = @"%@*";

      _queryBindings = [NSMutableDictionary new];

      _flags.selectsFirstObjectAfterFetch = YES;
      _flags._initialized = YES;
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

- (id) initWithCoder:(NSCoder *)decoder
{
  int tmpI;

  self = [self init]; 
  [self setDataSource:[decoder decodeObject]]; 
  _delegate = [decoder decodeObject]; 
  ASSIGN(_sortOrdering, [decoder decodeObject]);
  ASSIGN(_qualifier, [decoder decodeObject]);
  ASSIGN(_localKeys, [decoder decodeObject]);
  /* encode _query*, _defaultStringMatch* ?? */
  [decoder decodeValueOfObjCType: @encode(int) at: &tmpI];
  _flags.selectsFirstObjectAfterFetch = tmpI; 
  [decoder decodeValueOfObjCType: @encode(int) at: &tmpI];
  _flags.autoFetch = tmpI;
  return self;
}

- (void)encodeWithCoder: (NSCoder *)encoder
{
  int tmpI;
  
  [encoder encodeObject: _dataSource]; 
  [encoder encodeObject: _delegate];
  [encoder encodeObject: _sortOrdering];
  [encoder encodeObject: _qualifier];
  [encoder encodeObject: _localKeys];
  tmpI = _flags.selectsFirstObjectAfterFetch;
  [encoder encodeValueOfObjCType: @encode(int) at: &tmpI];
  tmpI = _flags.autoFetch;
  [encoder encodeValueOfObjCType: @encode(int) at: &tmpI];

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
  if (_dataSource != dataSource)
    {
      EOEditingContext *context;
      NSNotificationCenter *center;

      center = [NSNotificationCenter defaultCenter];

      if (_dataSource
	  && (context = [_dataSource editingContext]))
	{
	  [context removeEditor: self];

	  if ([context messageHandler] == self)
	    {
	      [context setMessageHandler: nil];
	    }
	  [center removeObserver: self
		  name: EOObjectsChangedInEditingContextNotification
		  object: context];

	  [center removeObserver: self
		  name: EOObjectsChangedInStoreNotification
		  object: context];
	}

      [self setObjectArray: nil];
      ASSIGN(_dataSource, dataSource);
      if ((context = [_dataSource editingContext]))
	{
	  [context addEditor: self];

	  if ([context messageHandler] == nil)
	    {
	      [context setMessageHandler: self];
	    }

	  [center addObserver: self
		  selector: @selector(objectsInvalidatedInEditingContext:)
		  name: EOInvalidatedAllObjectsInStoreNotification
		  object: context];

	  [center addObserver: self
		  selector: @selector(objectsChangedInEditingContext:)
		  name: EOObjectsChangedInEditingContextNotification
		  object: context];
	}
      if (_delegate
	  && [_delegate respondsToSelector: 
			  @selector(displayGroupDidChangeDataSource:)])
	{
	  [_delegate displayGroupDidChangeDataSource: self];
	}
    }
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
  BOOL flag = YES;
  
  if (_dataSource
      && (flag = [self endEditing]))
    {
      if (_delegate
	  && [_delegate respondsToSelector:
			 @selector(displayGroupShouldFetch:)])
	{
	  flag = [_delegate displayGroupShouldFetch: self];
	}

      if (flag)
	{
	  NSNotificationCenter *center;
	  NSArray *objects;

	  center = [NSNotificationCenter defaultCenter];
	  [center  postNotificationName: EODisplayGroupWillFetchNotification
		   object: self];
	  
	  if ([_dataSource respondsToSelector:
			     @selector(setQualifierBindings:)])
	    {
	      [_dataSource setQualifierBindings: _queryBindings];
	    }

	  objects = [_dataSource fetchObjects];
	  [self setObjectArray: objects];

	  if (_delegate
	      && [_delegate respondsToSelector: DG_DID_FETCH_OBJECTS])
	    {
	      [_delegate displayGroup: self
			 didFetchObjects: objects];
	    }

	  flag = objects ? YES : NO;
	}
    }
  
  return flag;
}

- (NSArray *)allObjects
{
  return AUTORELEASE([[NSArray alloc] initWithArray:_allObjects copyItems:NO]);
}

- (void)setObjectArray: (NSArray *)objects
{
  NSArray *oldSelection = [self selectedObjects];
  BOOL selectFirstOnNoMatch = [self selectsFirstObjectAfterFetch];

  if (objects == nil)
    {
      objects = emptyArray;
    }

  ASSIGN(_allObjects,
	 AUTORELEASE([objects mutableCopyWithZone: [self zone]]));

  [self updateDisplayedObjects];

  [self selectObjectsIdenticalTo: oldSelection
	selectFirstOnNoMatch: selectFirstOnNoMatch];

  [self redisplay];
}

- (NSArray *)displayedObjects
{
  return AUTORELEASE([_displayedObjects copy]);
}

- (void)redisplay
{
  /* TODO: Check this again! */
  _flags.didChangeContents = YES;
  [EOObserverCenter notifyObserversObjectWillChange: nil];
  [self willChange];
}

- (void)updateDisplayedObjects
{
  NSArray *oldSelection = [self selectedObjects];
  volatile NSArray *displayedObjects = [self allObjects];

  if (_delegate 
      && [_delegate respondsToSelector: DG_DISPLAY_ARRAY_FOR_OBJECTS])
    {
      displayedObjects 
	= [_delegate displayGroup: self
		     displayArrayForObjects: (id)displayedObjects];
    }
  
  NS_DURING
    {
      displayedObjects 
	= [(id)displayedObjects filteredArrayUsingQualifier: _qualifier];
      displayedObjects
	= [(id)displayedObjects sortedArrayUsingKeyOrderArray: _sortOrdering];
    }
  NS_HANDLER
    {
      [self _presentAlertWithTitle: 
	      @"Exception during sort or filter operatation."
	    message: [localException reason]];
    }
  NS_ENDHANDLER;

  ASSIGN(_displayedObjects,
	 AUTORELEASE([(id)displayedObjects mutableCopyWithZone:[self zone]]));

  [self selectObjectsIdenticalTo: oldSelection
	selectFirstOnNoMatch: NO];

  [self redisplay];
}

- (NSArray *)selectionIndexes
{
  return _selection;
}

- (BOOL)setSelectionIndexes: (NSArray *)selection
{
  if ([self endEditing] && selection)
    {
      if (_delegate
	  && [_delegate respondsToSelector: DG_SHOULD_CHANGE_SELECTION_TO_IDX]
	  && [_delegate displayGroup: self
			shouldChangeSelectionToIndexes: selection] == NO)

	{
	  return NO;
	}
      else
	{
	  NSNumber *number;
	  NSArray *newSelection;
	  NSMutableArray *newObjects;
	  id object;
	  unsigned c, i, count, index;
	  count = [_displayedObjects count];
	  c = [selection count];
	  newObjects = (id)[NSMutableArray arrayWithCapacity: c];
	  
	  for (i = 0; i < c; i++)
	    {
	      number = [selection objectAtIndex: i];
	      index = [number unsignedIntValue];
	      object = index < count 
		? [_displayedObjects objectAtIndex: index] : nil;
	      if (object != nil)
		{
		  [newObjects addObject: object];
		}
	    }
	  ASSIGNCOPY(_selectedObjects, newObjects);
	  newSelection =
	    [_displayedObjects indexesForObjectsIndenticalTo: _selectedObjects];
	  /* don't release emptyArray */
	  (_selection == emptyArray) ? _selection = newSelection : ASSIGN(_selection, newSelection);
	  _flags.didChangeSelection = YES;
	  if ([_delegate respondsToSelector: DG_DID_CHANGE_SELECTION])
	    {
	      [_delegate displayGroupDidChangeSelection:self];
	    }
	  [self willChange];
	  return YES;
	}
    }
  
  return NO;
}

- (BOOL)selectObject: (id)object
{
  NSArray *array;
  if (object) 
    {
      array = [NSArray arrayWithObject: object];
    }
  else
    {
      array = [NSArray array];
    }
  return [self selectObjectsIdenticalTo: array];
}
- (BOOL)selectObjectsIdenticalTo: (NSArray *)selection
{
  NSArray *indices;
  if (selection && [selection count])
    {
      indices = [_displayedObjects indexesForObjectsIndenticalTo: selection];
      if (indices && ![indices count])
        {
	  indices = nil;
	}
    }
  else
    {
      indices = selection;
    }
  return [self setSelectionIndexes: indices];
}

- (BOOL)selectObjectsIdenticalTo: (NSArray *)selection 
	    selectFirstOnNoMatch: (BOOL)flag
{
  BOOL selectflag = [self selectObjectsIdenticalTo: selection];

  if (selectflag && flag
      && [_selection count] == 0
      && [_displayedObjects count] != 0)
    {
      id object = [_displayedObjects objectAtIndex: 0];
      selectflag = [self selectObject: object];
    }

  return selectflag;
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
  return [self setSelectionIndexes: emptyArray];
}

- (NSArray *)selectedObjects
{
  return AUTORELEASE([_selectedObjects copy]);
}
- (void)setSelectedObjects: (NSArray *)objects
{
  ASSIGN (_selectedObjects, 
	  AUTORELEASE([objects mutableCopyWithZone: [self zone]]));
}

- (id)selectedObject
{
  id object = nil;

  if ([_selectedObjects count])
    {
      object = [_selectedObjects objectAtIndex: 0];
    }
    
  return object;
}

- (void)setSelectedObject: (id)object
{
  if (object)
    {
      [self selectObject: object];
    }
  else
    {
      [self clearSelection];
    }
}

- (id)insertObjectAtIndex: (unsigned)index
{
  id object = nil;
  if ([self endEditing])
    {
      object = [_dataSource createObject];
      if (object == nil)
	{
	  if (_delegate
	      && [_delegate respondsToSelector: DG_CREATE_OBJECT_FAILED])
	    {
	      [_delegate displayGroup: self
			 createObjectFailedForDataSource: _dataSource];
	    }
	  else
	    {
	      [self _presentAlertWithTitle: @"EODisplayGroup"
		    message: @"Data source did not provide new object. "];
	    }
	}
      else
	{
	  NSArray *defaultValueKeys = [_insertedObjectDefaultValues allKeys];
	  unsigned i, c = [defaultValueKeys count];
	  NSString *key;
	  id value;

	  /* We cannot use -takeValuesFromDictionary because
	     we need to call -takeValue:forKeyPath:.  */
	  for (i = 0; i < c; i++)
	    {
	      key = [defaultValueKeys objectAtIndex: i];
	      value = [_insertedObjectDefaultValues valueForKeyPath: key];
	      [object smartTakeValue: value forKeyPath: key];
	    }
	  [self insertObject: object atIndex: index];
	}
    }
  return object;
}

- (void)insertObject: (id)object atIndex: (unsigned)index
{
  if ([self endEditing])
    {
      unsigned c = [_displayedObjects count];
      if (c < index)
	{
	  [NSException raise: NSRangeException
		       format: @"-[%@ %@]: Index %d is out of range %d", 
		       NSStringFromClass([self class]),
		       NSStringFromSelector(_cmd),
		       index, c];
	}
      if (_delegate == nil
	  || [_delegate respondsToSelector: DG_SHOULD_INSERT_OBJECT] == NO
	  || [_delegate displayGroup: self
			shouldInsertObject: object
			atIndex: index])
	{
	  NS_DURING
	    {
	      [_dataSource insertObject: object];
	    }
	  NS_HANDLER
	    {
	      [self _presentAlertWithTitle: @"EODisplayGroup insertion error"
		    message: [localException reason]];
	      return;
	    }
	  NS_ENDHANDLER;
	  
	  /* It is safe to use the index for _allObjects but it seems
	     strange. OTOH _allObjects should probably be viewed as set.  */
	  [_allObjects insertObject: object atIndex: index];
	  [_displayedObjects insertObject: object atIndex: index];
	  [self redisplay];
	  
	  if (_delegate
	      && [_delegate respondsToSelector: DG_DID_INSERT_OBJECT])
	    {
	      [_delegate displayGroup: self didInsertObject: object];
	    }

	  [self selectObjectsIdenticalTo: [NSArray arrayWithObject: object]];
	}
    }
}

- (NSDictionary *)insertedObjectDefaultValues
{
  return _insertedObjectDefaultValues;
}
- (void)setInsertedObjectDefaultValues: (NSDictionary *)values
{
   (_insertedObjectDefaultValues == emptyDictionary) ? _insertedObjectDefaultValues = [values copy] : ASSIGNCOPY(_insertedObjectDefaultValues, values);
}

- (BOOL)deleteObjectAtIndex: (unsigned)index
{
  return NO;
}
- (BOOL)deleteSelection
{
  BOOL flag;
  if ([self endEditing])
    {
      NSArray *selections = [self selectedObjects];
      int c = [selections count];
      int i;
      for (i = 0; i < c; i++)
         [[self dataSource] deleteObject: [selections objectAtIndex:i]];
    }
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
  /* not sure if this should be using an EOQualifier somehow */
  NSMutableArray *oa = [[NSMutableArray alloc] init]; 
  NSArray *observers = [EOObserverCenter observersForObject: self]; 
  int i, count;
  
  count = [observers count];
  for (i = 0; i < count; i ++)
    {
      id currentObject = [observers objectAtIndex:i];
      if ([currentObject isKindOfClass:[EOAssociation class]])
        [oa addObject: currentObject];
    }
  
  return AUTORELEASE(oa);
}

- (EOAssociation *)editingAssociation
{
  return _editingAssociation;
}
- (BOOL)endEditing
{
  return _editingAssociation ? [_editingAssociation endEditing] : YES;
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
  unsigned idx = 0;
  NSArray *selections = [self selectionIndexes];

  if ([selections count])
    {
      NSNumber *index = [selections objectAtIndex: 0];
      idx = [index unsignedIntValue];
    }

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
  return _flags.didChangeSelection;
}
- (BOOL)contentsChanged
{
  return _flags.didChangeContents;
}
- (int)updatedObjectIndex
{
  return 0;
}

- (id)valueForObject: (id)object key: (NSString *)key
{
  return [object valueForKeyPath: key];
}
- (id)selectedObjectValueForKey: (NSString *)key
{
  return [self valueForObject: [self selectedObject] key: key];
}

- (id)valueForObjectAtIndex: (unsigned)index key: (NSString *)key
{
  return [self valueForObject: [_displayedObjects objectAtIndex: index] 
  			  key: key];
}

- (BOOL)setValue: (id)value forObject: (id)object key: (NSString *)key
{
  SEL didSetValue = @selector(displayGroup:didSetValue:forKey:);
  NSException *exception = nil;
      
  NS_DURING
    {
      [object takeValue:value forKeyPath:key];
    }
  NS_HANDLER
     /* use NSLog because -userInfo may contain useful information. */
     NSLog(@"Exception in %@ name:%@ reason:%@ userInfo:%@", NSStringFromSelector(_cmd), [localException name], [localException reason], [localException userInfo]); 
    return NO;
  NS_ENDHANDLER

  if ([self validatesChangesImmediately])
    exception = [object validateValue: &value forKey: key];
  
  if (exception == nil && [_delegate respondsToSelector:didSetValue])
    {
      [_delegate displayGroup: self 
		  didSetValue: value
		    forObject: object
			  key: key];
      return YES;
    }
    
  if (exception)
    {
      /* use NSLog because -userInfo may contain useful information. */
      NSLog(@"Exception in %@ name:%@ reason:%@ userInfo:%@", NSStringFromSelector(_cmd), [exception name], [exception reason], [exception userInfo]); 
    }
  return (exception == nil);
}

- (BOOL)setSelectedObjectValue: (id)value forKey: (NSString *)key
{
  return [self setValue: value forObject: [self selectedObject]  key: key];
}

- (BOOL)setValue: (id)value forObjectAtIndex: (unsigned)index 
	     key: (NSString *)key
{
  return [self setValue: value 
  	      forObject: [_displayedObjects objectAtIndex: index]
	            key: key];
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
  ASSIGN(_editingAssociation,association);
}

- (void)associationDidEndEditing: (EOAssociation *)association
{
  ASSIGN(_editingAssociation,nil);
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

@implementation EODisplayGroup (EODeprecated)
- (void)setSortOrdering: (NSArray *)sortOrderings
{
  [self setSortOrderings: sortOrderings];
}
- (NSArray *)sortOrdering
{
  return [self sortOrderings];
}
@end

@implementation EODisplayGroup (notifications)
- (void)objectsInvalidatedInEditingContext: (NSNotification *)notif
{
}
- (void)objectsChangedInEditingContext: (NSNotification *)notif
{
  _flags.didChangeContents = YES;
  [self willChange];
}
@end

@implementation EODisplayGroup (GDL2Private)
- (void) _beginObserverNotification:(id)sender
{
  /* FIXME what goes here?? */
}

- (void) _endObserverNotification:(id)sender
{
  _flags.didChangeContents = NO;
  _flags.didChangeSelection = NO;
  [EOObserverCenter notifyObserversObjectWillChange:nil];
}
@end
