/** -*-ObjC-*-
   EODisplayGroup.h

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Author: David Ayers <ayers@fsfe.org>

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

#ifndef __EOInterface_EODisplayGroup_h__
#define __EOInterface_EODisplayGroup_h__

#ifdef GNUSTEP
#include <Foundation/NSObject.h>
#else
#include <Foundation/Foundation.h>
#endif

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSNotification;

@class EOEditingContext;
@class EODataSource;
@class EOQualifier;

@class EOAssociation;

@interface EODisplayGroup : NSObject <NSCoding>
{
@private
  EODataSource   *_dataSource; /*Retained*/
  NSMutableArray *_allObjects;
  NSMutableArray *_displayedObjects;

  id              _delegate;   /*Not Retained*/

  NSArray        *_selection;
  NSArray        *_sortOrdering;
  EOQualifier    *_qualifier;

  NSArray        *_localKeys;

  NSMutableArray *_selectedObjects;
  id              _observerNotificationBeginProxy;
  id              _observerNotificationEndProxy;
  int             _updatedObjectIndex;
  NSDictionary   *_insertedObjectDefaultValues;
  NSMutableArray *_savedAllObjects;

  NSMutableDictionary *_queryMatch;
  NSMutableDictionary *_queryMin;
  NSMutableDictionary *_queryMax;
  NSMutableDictionary *_queryOperator;

  NSString       *_defaultStringMatchOperator;
  NSString       *_defaultStringMatchFormat;
  NSMutableDictionary *_queryBindings;
  void           *_reserved;
  struct {
    unsigned selectsFirstObjectAfterFetch:1;
    unsigned didChangeContents:1;
    unsigned didChangeSelection:1;
    unsigned autoFetch:1;
    unsigned haveFetched:1;
    unsigned validateImmediately:1;
    unsigned queryMode:1;
    unsigned optimisticRefresh:1;
    unsigned fetchAll:1;
    unsigned _initialized:1;
    unsigned _reserved:22;
  } _flags;
  EOAssociation  *_editingAssociation;
}

/* Global configurations.  */
+ (NSString *)globalDefaultStringMatchOperator;
+ (void)setGlobalDefaultStringMatchOperator: (NSString *)operator;

+ (BOOL)globalDefaultForValidatesChangesImmediately;
+ (void)setGlobalDefaultForValidatesChangesImmediately: (BOOL)flag;


/* Configuring behavior.  */
- (BOOL)fetchesOnLoad;
- (void)setFetchesOnLoad: (BOOL)flag;

- (BOOL)selectsFirstObjectAfterFetch;
- (void)setSelectsFirstObjectAfterFetch: (BOOL)flag;

- (BOOL)validatesChangesImmediately;
- (void)setValidatesChangesImmediately: (BOOL)flag;

- (BOOL)usesOptimisticRefresh;
- (void)setUsesOptimisticRefresh: (BOOL)flag;

- (NSDictionary *)queryBindingValues;
- (void)setQueryBindingValues: (NSDictionary *)values;

- (NSDictionary *)queryOperatorValues;
- (void)setQueryOperatorValues: (NSDictionary *)values;

- (NSString *)defaultStringMatchFormat;
- (void)setDefaultStringMatchFormat: (NSString *)format;

- (NSString *)defaultStringMatchOperator;
- (void)setDefaultStringMatchOperator: (NSString *)operator;

/* Configuring data source.  */

- (EODataSource *)dataSource;
- (void)setDataSource: (EODataSource *)dataSource;

/* Configuring qualifier.  */
- (EOQualifier *)qualifier;
- (void)setQualifier: (EOQualifier *)qualifier;

/* Configuring sort orderings.  */
- (NSArray *)sortOrderings;
- (void)setSortOrderings: (NSArray *)orderings;

/* Managing queries.  */
- (EOQualifier *)qualifierFromQueryValues;

- (NSDictionary *)equalToQueryValues;
- (void)setEqualToQueryValues: (NSDictionary *)values;

- (NSDictionary *)greaterThanQueryValues;
- (void)setGreaterThanQueryValues: (NSDictionary *)values;

- (NSDictionary *)lessThanQueryValues;
- (void)setLessThanQueryValues: (NSDictionary *)values;

- (void)qualifyDisplayGroup;
- (void)qualifyDataSource;

- (BOOL)inQueryMode;
- (void)setInQueryMode: (BOOL)flag;

/* Fetching.  */
- (BOOL)fetch;

/* Accessing objects.  */
- (NSArray *)allObjects;
- (void)setObjectArray: (NSArray *)objects;
- (NSArray *)displayedObjects;

/* Updating displayed values.  */
- (void)redisplay;
- (void)updateDisplayedObjects;

/* Manage selection.  */
- (NSArray *)selectionIndexes;
- (BOOL)setSelectionIndexes: (NSArray *)selection;

- (BOOL)selectObject: (id)object;
- (BOOL)selectObjectsIdenticalTo: (NSArray *)selection;
- (BOOL)selectObjectsIdenticalTo: (NSArray *)selection 
	    selectFirstOnNoMatch: (BOOL)flag;

- (BOOL)selectNext;
- (BOOL)selectPrevious;

- (BOOL)clearSelection;

- (NSArray *)selectedObjects;
- (void)setSelectedObjects: (NSArray *)objects;

- (id)selectedObject;
- (void)setSelectedObject: (id)object;

/* Inserting objects.  */
- (id)insertObjectAtIndex: (unsigned)index;
- (void)insertObject: (id)object atIndex: (unsigned)index;

- (NSDictionary *)insertedObjectDefaultValues;
- (void)setInsertedObjectDefaultValues: (NSDictionary *)values;

/* Deleting objects.  */
- (BOOL)deleteObjectAtIndex: (unsigned)index;
- (BOOL)deleteSelection;

/* Manage local keys.  */
- (NSArray *)localKeys;
- (void)setLocalKeys: (NSArray *)keys;

/* Manage delegate.  */
- (id)delegate;
- (void)setDelegate: (id)delegate;

/* Associations.  */
- (NSArray *)observingAssociations;
- (EOAssociation *)editingAssociation;
- (BOOL)endEditing;

@end

@interface EODisplayGroup (EODisplayGroupTargetAction)

- (void)selectNext: (id)sender;
- (void)selectPrevious: (id)sender;

- (void)fetch: (id)sender;
- (void)insert: (id)sender;
- (void)delete: (id)sender;

- (void)qualifyDataSource: (id)sender;
- (void)qualifyDisplayGroup: (id)sender;

- (void)enterQueryMode: (id)sender;

@end

@interface EODisplayGroup (EOAssociationInteraction)

- (BOOL)selectionChanged;
- (BOOL)contentsChanged;
- (int)updatedObjectIndex;

- (id)valueForObject: (id)object key: (NSString *)key;
- (id)selectedObjectValueForKey: (NSString *)key;
- (id)valueForObjectAtIndex: (unsigned)index key: (NSString *)key;

- (BOOL)setValue: (id)value forObject: (id)object key: (NSString *)key;
- (BOOL)setSelectedObjectValue: (id)value forKey: (NSString *)key;
- (BOOL)setValue: (id)value forObjectAtIndex: (unsigned)index 
	     key: (NSString *)key;
- (BOOL)enabledToSetSelectedObjectValueForKey:(NSString *)key;

- (BOOL)association: (EOAssociation *)association 
failedToValidateValue: (NSString *)value
	     forKey: (NSString *)key 
	     object: (id)object
   errorDescription: (NSString *)description;
- (void)associationDidBeginEditing: (EOAssociation *)association;
- (void)associationDidEndEditing: (EOAssociation *)association;

@end

@interface EODisplayGroup (EOEditors)
- (BOOL)editorHasChangesForEditingContext: (EOEditingContext *)editingContext;
- (void)editingContextWillSaveChanges: (EOEditingContext *)editingContext;
@end

@interface EODisplayGroup (EOMessageHandlers)
- (void)editingContext: (EOEditingContext *)editingContext
   presentErrorMessage: (NSString *)message;
@end

@interface NSObject (EODisplayGroupDelegate)

- (BOOL)displayGroup: (EODisplayGroup *)displayGroup
shouldRedisplayForEditingContextChangeNotification: (NSNotification *)notif;

- (BOOL)displayGroup: (EODisplayGroup *)displayGroup 
shouldRefetchForInvalidatedAllObjectsNotification: (NSNotification *)notif;

- (BOOL)displayGroup: (EODisplayGroup *)displayGroup
shouldChangeSelectionToIndexes: (NSArray *)indices;

- (void)displayGroupDidChangeSelection: (EODisplayGroup *)displayGroup;
- (void)displayGroupDidChangeSelectedObjects: (EODisplayGroup *)displayGroup;

- (BOOL)displayGroupShouldFetch: (EODisplayGroup *)displayGroup;

- (void)displayGroup: (EODisplayGroup *)displayGroup
     didFetchObjects: (NSArray *)objects;

- (NSArray *)displayGroup: (EODisplayGroup *)displayGroup
   displayArrayForObjects: (NSArray *)objects;
- (void)displayGroup: (EODisplayGroup *)displayGroup
	 didSetValue: (id)value
	   forObject: (id)object
		 key: (NSString *)key;
- (void)displayGroup: (EODisplayGroup *)displayGroup
createObjectFailedForDataSource: (EODataSource *)dataSource;

- (BOOL)displayGroup: (EODisplayGroup *)displayGroup
  shouldInsertObject: (id)object
	     atIndex: (unsigned)index;

- (void)displayGroup: (EODisplayGroup *)displayGroup 
     didInsertObject: (id)object;

- (BOOL)displayGroup: (EODisplayGroup *)displayGroup
  shouldDeleteObject: (id)object;

- (void)displayGroup: (EODisplayGroup *)displayGroup
     didDeleteObject: (id)object;

- (void)displayGroupDidChangeDataSource: (EODisplayGroup *)displayGroup;
- (BOOL)displayGroup: (EODisplayGroup *)displayGroup
shouldDisplayAlertWithTitle: (NSString *)title
	     message: (NSString *)message;

@end

#endif


