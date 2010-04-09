/*
   EODisplayGroup.m

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: David Ayers <ayers@fsfe.org>

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
#include <Foundation/NSScanner.h>

#include <AppKit/NSPanel.h>
#else
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#endif

#include <GNUstepBase/GNUstep.h>
#include <EOAccess/EODatabaseDataSource.h>
#include <EOControl/EOClassDescription.h>
#include <EOControl/EODataSource.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EOFetchSpecification.h>
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
#define DG_DID_DELETE_OBJECT \
     @selector(displayGroup:didDeleteObject:)
#define DG_SHOULD_DELETE_OBJECT \
     @selector(displayGroup:shouldDeleteObject:)

/* undocumented notification */
NSString *EODisplayGroupWillFetchNotification = @"EODisplayGroupWillFetch";

@interface NSArray (private)
- (NSArray *)indexesForObjectsIdenticalTo: (NSArray *)array;
@end
@implementation NSArray (private)
- (NSArray *)indexesForObjectsIdenticalTo: (NSArray *)array
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

NSArray *emptyArray;
NSDictionary *emptyDictionary;
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
  EOEditingContext *context = [_dataSource editingContext];

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [context removeEditor:self];
  if ([context messageHandler] == self)
    [context setMessageHandler:nil];

  DESTROY(_dataSource);
  if (_allObjects != emptyArray)
    DESTROY(_allObjects);
  DESTROY(_displayedObjects);
  if (_selection != emptyArray)
    DESTROY(_selection);
  DESTROY(_sortOrdering);
  DESTROY(_qualifier);
  DESTROY(_localKeys);
  DESTROY(_selectedObjects);
  [EOObserverCenter removeObserver:_observerNotificationBeginProxy
			 forObject:self];
  [EOObserverCenter removeObserver:_observerNotificationEndProxy
			 forObject:self];
  DESTROY(_observerNotificationBeginProxy);
  DESTROY(_observerNotificationEndProxy);
  if (_insertedObjectDefaultValues != emptyDictionary)
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

- (void) awakeFromNib
{
  if (_flags.autoFetch)
    {
      [self fetch];
    }
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

- (EOQualifier *) _qualifierForKey:(NSString *)key
		 value:(id)val
		 defaultOperator:(char)defaultOp
{
  NSString *op;
  SEL selector = NULL;
  NSString *fmt = nil;
  
  EOClassDescription *classDesc = [_dataSource classDescriptionForObjects];
   
  [[classDesc validateValue:&val forKey:key] raise]; 
  op = [_queryOperator objectForKey:key];
  if (op == nil)
    {
      switch (defaultOp)
	{
	  case '=':
	    if ([val isKindOfClass:[NSString class]])
	      {
	        op = _defaultStringMatchOperator; 
		fmt = _defaultStringMatchFormat;
	      }
            else
	      {
	        selector = EOQualifierOperatorEqual;
	      }
	    break;
	  case '>':
	    selector = EOQualifierOperatorGreaterThanOrEqualTo;
	   break;
	  case '<':
	    selector = EOQualifierOperatorLessThanOrEqualTo;
	   break;

	}
    }
  if (op) 
    selector = [EOKeyValueQualifier operatorSelectorForString:op];

  if (fmt)
    val = [NSString stringWithFormat:fmt, val];
  
  return [EOKeyValueQualifier
             	qualifierWithKey:key
                   operatorSelector:selector
                   value: val];
}

- (EOQualifier *)qualifierFromQueryValues
{
  NSMutableArray *quals = [NSMutableArray array];
  int i, c, j;
  id dicts[3];
  char ops[3] = { '=', '<', '>' };
  dicts[0] = _queryMatch;
  dicts[1] = _queryMax;
  dicts[2] = _queryMin;
  for (j = 0; j < 3; j++)
    {   
      NSArray *keys = [dicts[j] allKeys];

      for (i = 0, c = [keys count]; i < c; i++)
        { 
	  NSString *key = [keys objectAtIndex:i];
	  id val = [dicts[j] objectForKey:key];
          
	  [quals addObject:[self _qualifierForKey:key
		  			value:val
					defaultOperator:ops[j]]];
        }
    }
  return [EOAndQualifier qualifierWithQualifierArray:quals];
}

- (NSDictionary *)equalToQueryValues
{
  return AUTORELEASE([_queryMatch copy]);
}

- (void)setEqualToQueryValues: (NSDictionary *)values
{
  ASSIGN(_queryMatch,
         AUTORELEASE([values mutableCopyWithZone: [self zone]]));
}

- (NSDictionary *)greaterThanQueryValues
{
  return AUTORELEASE([_queryMin copy]);
}
- (void)setGreaterThanQueryValues: (NSDictionary *)values
{
  ASSIGN(_queryMin,
         AUTORELEASE([values mutableCopyWithZone: [self zone]]));
}

- (NSDictionary *)lessThanQueryValues
{
  return AUTORELEASE([_queryMax copy]);
}
- (void)setLessThanQueryValues: (NSDictionary *)values
{
  ASSIGN(_queryMax,
         AUTORELEASE([values mutableCopyWithZone: [self zone]]));
}

- (void)qualifyDisplayGroup
{
  [self setQualifier:[self qualifierFromQueryValues]];
  [self updateDisplayedObjects];
  _flags.queryMode = NO;
}

- (void)qualifyDataSource
{
  /* only works with EODatabaseDataSource ?? */
  [[(EODatabaseDataSource *)_dataSource fetchSpecification]
	  			setQualifier:[self qualifierFromQueryValues]];
  _flags.queryMode = NO;
  [self fetch];
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
	  [center postNotificationName: EODisplayGroupWillFetchNotification
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
  if (objects == nil)
    {
      objects = emptyArray;
    }
  
  ASSIGN(_allObjects,
	 AUTORELEASE([objects mutableCopyWithZone: [self zone]]));

  [self updateDisplayedObjects];

  [self selectObjectsIdenticalTo:[self selectedObjects] 
	   selectFirstOnNoMatch:_flags.selectsFirstObjectAfterFetch];
 

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
//  [EOObserverCenter notifyObserversObjectWillChange: nil];
  [self willChange];
}

- (void)updateDisplayedObjects
{
  NSArray *oldSelection = [self selectedObjects];
  volatile NSArray *displayedObjects = [self allObjects];

  if (_delegate 
      && [_delegate respondsToSelector: DG_DISPLAY_ARRAY_FOR_OBJECTS])
    {
      displayedObjects = [_delegate displayGroup: self
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
	      object = (index < count)
		       ? [_displayedObjects objectAtIndex: index]
		       : nil;
	      if (object != nil)
		{
		  [newObjects addObject: object];
		}
	    }
	  
	  if ([_selectedObjects isEqual:newObjects] == NO
	      || [_selection isEqual:selection] == NO)
	    {
	      ASSIGNCOPY(_selectedObjects, newObjects);
	      newSelection = [_displayedObjects
	 	     	        indexesForObjectsIdenticalTo: _selectedObjects];
	      /* don't release emptyArray */
	      (_selection == emptyArray) ? _selection = RETAIN(newSelection)
		  		         : ASSIGN(_selection, newSelection);
	      _flags.didChangeSelection = YES;
	      if ([_delegate respondsToSelector: DG_DID_CHANGE_SELECTION])
	        {
	          [_delegate displayGroupDidChangeSelection:self];
	        }
	      
	      [self willChange];
	    }
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
  indices = [_displayedObjects indexesForObjectsIdenticalTo: selection];
  if ([selection count] && ![indices count]) return NO;
  return [self setSelectionIndexes: indices];
}

- (BOOL)selectObjectsIdenticalTo: (NSArray *)selection 
	    selectFirstOnNoMatch: (BOOL)flag
{
  BOOL selected = [self selectObjectsIdenticalTo: selection];

  if (!selected)
    {
      unsigned c = [_displayedObjects count];
      if (flag && c != 0)
        {
	  id object = [_displayedObjects objectAtIndex: 0];
          selected = [self selectObject: object];
	}
#if 0 
      // this really doesn't seem like it belongs here.
      else if (c) 
        {
	  [self setSelectionIndexes:_selection]; 
	}
#endif
      else
	{
	  [self clearSelection];
	}
    }
  
  return selected;
}

- (BOOL)selectNext
{
  id selObj = [self selectedObject];
  unsigned idx;
  
  if (selObj == nil) return NO;

  idx = [[self displayedObjects]
	  	indexOfObjectIdenticalTo:[self selectedObject]];
  
  if (idx == UINT_MAX) return NO;

  return [self setSelectionIndexes:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:++idx]]];
}
- (BOOL)selectPrevious
{
  id selObj = [self selectedObject];
  unsigned idx;
  
  if (selObj == nil) return NO;

  idx = [[self displayedObjects]
	  	indexOfObjectIdenticalTo:[self selectedObject]];
  
  if (idx == 0) return NO;

  return [self setSelectionIndexes:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:--idx]]];
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
  ASSIGNCOPY(_selectedObjects, objects);
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
	  
	  if (_delegate
	      && [_delegate respondsToSelector: DG_DID_INSERT_OBJECT])
	    {
	      [_delegate displayGroup: self didInsertObject: object];
	    }

	  [self selectObject: object];
	  [self redisplay];
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
  id object = [_displayedObjects objectAtIndex:index];
  if (!_delegate
      || ([_delegate respondsToSelector:DG_SHOULD_DELETE_OBJECT]
      	  && [_delegate displayGroup:self shouldDeleteObject:object]))
    {
      NS_DURING
	[_dataSource deleteObject:object];	      
        if ([_delegate respondsToSelector:DG_DID_DELETE_OBJECT])
	  {
	    [_delegate displayGroup:self didDeleteObject:object];
	  }
	[_displayedObjects removeObjectAtIndex:index];
	[_allObjects removeObject:object];
	NS_VALUERETURN(YES, BOOL);
      NS_HANDLER
        return NO;
      NS_ENDHANDLER
    }
	    
  return NO;
}
- (BOOL)deleteSelection
{
  BOOL flag = YES;
  NSArray *sel = [self selectionIndexes];
  int c = [sel count];

  if (c == 0)
    {
      return YES;
    }

  if ((flag = [self endEditing]))
    {
      int i;

      [self redisplay];
      for (i = 0; i < c && flag; i++)
        {
	  unsigned int index = [[sel objectAtIndex:i] unsignedIntValue];
	  id selection = [self selectedObjects];
	  flag = [self deleteObjectAtIndex:index];
	  [self selectObjectsIdenticalTo:selection selectFirstOnNoMatch:NO];
	}
    }
  return flag;
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
  [self redisplay];
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
  return -1;
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

- (NSMutableDictionary *)_queryDictForOperator:(NSString *)op
{
  if ([op isEqual:@"<"])
    return _queryMax;
  
  if ([op isEqual:@">"])
    return _queryMin; 
  
  if ([op isEqual:@"="])
    return _queryMatch;

  if ([op isEqual:@"Op"])
    return _queryOperator;
  
  return nil;
}

- (BOOL)setValue: (id)value forObject: (id)object key: (NSString *)key
{
  SEL didSetValue = @selector(displayGroup:didSetValue:forObject:key:);
  NSException *exception = nil;
  
  if ([key hasPrefix:@"@query"])
    {
      NSString *oper = [NSString string];
      NSScanner *scn = [NSScanner scannerWithString:key];
      NSMutableDictionary *_queryDict = nil;
      
      [scn setScanLocation:6];
      
      if ([scn scanUpToString:@"." intoString:&oper]
          && [scn scanString:@"." intoString:NULL]
          && [scn scanLocation] != [key length])
        {
          NSString *realKey = [key substringFromIndex:[scn scanLocation]];
	  _queryDict = [self _queryDictForOperator:oper];
	  [_queryDict setObject:value forKey:realKey];
        }
        if (!_queryDict)
          [[NSException exceptionWithName:NSInvalidArgumentException
			reason:@"Invalid query operator, expected '<', '>', '=',or 'Op'"
			 userInfo:nil] raise];
	return _queryDict != nil;
    }
  else
    { 
  
      NS_DURING
        {
          [object takeValue:value forKeyPath:key];
        } 
      NS_HANDLER
         /* -userInfo likely contains useful information... */
          NSLog(@"Exception in %@ name:%@ reason:%@ userInfo:%@", NSStringFromSelector(_cmd), [localException name], [localException reason], [localException userInfo]); 
          return NO;
      NS_ENDHANDLER

      exception = [object validateValue: &value forKey: key];

      if (exception && _flags.validateImmediately)
        {
          [self _presentAlertWithTitle:@"Validation error"
	      		   message:[exception reason]];
          return NO;
        }
      else if ([_delegate respondsToSelector:didSetValue])
        {
          [_delegate displayGroup: self 
		  didSetValue: value
		    forObject: object
			  key: key];
        }
    }    
  return YES;
}

- (BOOL)setSelectedObjectValue: (id)value forKey: (NSString *)key
{
  return [self setValue: value forObject: [self selectedObject]  key: key];
}

- (BOOL)setValue: (id)value forObjectAtIndex: (unsigned)index 
	     key: (NSString *)key
{
  if ([_displayedObjects count] > index)
    return [self setValue: value 
  	      forObject: [_displayedObjects objectAtIndex: index]
	            key: key];
  return NO;
}

- (BOOL)enabledToSetSelectedObjectValueForKey:(NSString *)key
{
  return [self selectedObject] || [key hasPrefix: @"@query"] || _flags.queryMode;
}

- (BOOL)association: (EOAssociation *)association 
failedToValidateValue: (NSString *)value
	     forKey: (NSString *)key 
	     object: (id)object
   errorDescription: (NSString *)description
{
  [self _presentAlertWithTitle:@"Validation error" message:description];
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
/* FIXME GDL2 currently never calls this.. */
- (BOOL)editorHasChangesForEditingContext: (EOEditingContext *)editingContext
{
  /* check */
  [self endEditing];
  return _flags.didChangeContents;
}
- (void)editingContextWillSaveChanges: (EOEditingContext *)editingContext
{
  [self endEditing];
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
/*
  // hmmm this doesn't work because of relationships.... (WHY?)
  NSDictionary *userInfo = [notif userInfo];
  NSArray *upd = [userInfo objectForKey:EOUpdatedKey];
  NSArray *ins = [userInfo objectForKey:EOInsertedKey];
  NSArray *del = [userInfo objectForKey:EODeletedKey];
  _flags.didChangeContents = [_allObjects firstObjectCommonWithArray:upd]
	  		     || [_allObjects firstObjectCommonWithArray:ins]
  			     || [_allObjects firstObjectCommonWithArray:del];
*/
  /* FIXME this doesn't seem correct.
   * display groups/data sources can share editing contexts.
   * which will lead to spurious updates 
   */ 
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
