/**
   EOAssociation.m

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

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSException.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <GNUstepBase/GSObjCRuntime.h>

#include "EODisplayGroup.h"

#include "EOAssociation.h"

/* For GDL2NonRetainingArray */
#include "../EOControl/EOPrivate.h"

@implementation EOAssociation
static NSArray *_emptyArray = nil;
static NSMutableArray *_associationClasses = nil;
static NSMapTable *_objectToAssociations;

+ (void) objectDeallocated:(id)object
{
  GDL2NonRetainingMutableArray *associations;
  associations = NSMapGet(_objectToAssociations, object);
  
  if (associations)
    {
      [associations makeObjectsPerform: @selector(breakConnection)];
      NSMapRemove(_objectToAssociations, object);
    }
}

+ (void)bundleLoaded: (NSNotification *)notification
{
  DESTROY(_associationClasses);
}

+ (void)initialize
{
  if (_emptyArray == nil)
    {
      NSNotificationCenter *nc;
      _emptyArray = [NSArray new];
      nc = [NSNotificationCenter defaultCenter];
      [nc addObserver: self
	  selector: @selector(bundleLoaded:)
	  name: NSBundleDidLoadNotification
	  object: nil];
     _objectToAssociations = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks,
		     			     NSObjectMapValueCallBacks,
					     32);
    }
}

+ (NSArray *)aspects
{
  return _emptyArray;
}

+ (NSArray *)aspectSignatures
{
  unsigned int count = [[self aspects] count];
  unsigned int i;
  NSMutableArray *sigs = [NSMutableArray arrayWithCapacity: count];
  
  for (i = count; i < count; i++)
    {
      [sigs addObject: @"A1M"];
    }

  return AUTORELEASE([sigs copy]);
}

+ (NSArray *)objectKeysTaken
{
  return _emptyArray;
}

+ (BOOL)isUsableWithObject: (id)object
{
  return NO;
}

+ (NSArray *)associationClassesSuperseded
{
  return _emptyArray;
}

+ (NSString *)displayName
{
  return NSStringFromClass(self);
}

+ (NSString *)primaryAspect
{
  return nil;
}

+ (NSArray *)associationClassesForObject: (id)object
{
  unsigned int i, count;
  NSMutableArray *arr;
  Class cls;

  if (_associationClasses == nil)
    {
      _associationClasses 
	= RETAIN(GSObjCAllSubclassesOfClass([EOAssociation class]));
    }

  count = [_associationClasses count];
  arr = [NSMutableArray arrayWithCapacity: count];
  
  for (i = 0; i < count; i++)
    {
      cls = [_associationClasses objectAtIndex: i];
      if ([cls isUsableWithObject: object])
	{
	  [arr addObject: cls];
	}
    }
  return AUTORELEASE([arr copy]);
}


- (id)initWithObject: (id)object
{
  if ((self = [super init]))
    {
      unsigned int count = [[[self class] aspects] count];
      NSZone *zone = [self zone];
      _object = object;
      _displayGroupMap 
	= NSCreateMapTableWithZone(NSObjectMapKeyCallBacks,
				   NSNonRetainedObjectMapValueCallBacks,
				   count, zone);
      _displayGroupKeyMap
	= NSCreateMapTableWithZone(NSObjectMapKeyCallBacks,
				   NSNonRetainedObjectMapValueCallBacks,
				   count, zone);
    }
  return self;
}

- (id)init
{
  self = [self initWithObject: nil];
  return self;
}

- (id)initWithCoder: (NSCoder *)coder
{
  _object = [coder decodeObject];
  self = [self initWithObject:_object];
  
  return self;
}

- (void) encodeWithCoder: (NSCoder*)coder
{
  [coder encodeObject:_object];
}

- (void)dealloc
{
  [self discardPendingNotification];
  NSFreeMapTable (_displayGroupMap);
  NSFreeMapTable (_displayGroupKeyMap);
  [super dealloc];
}

- (void)bindAspect: (NSString *)aspectName
      displayGroup: (EODisplayGroup *)displayGroup
	       key: (NSString *)key
{
  NSMapInsert(_displayGroupMap, aspectName, displayGroup);
  NSMapInsert(_displayGroupKeyMap, aspectName, key);
}

- (void)establishConnection
{
  if (_isConnected == NO)
    {
      NSMapEnumerator displayGroupEnum;
      EODisplayGroup *displayGroup;
      void *unusedKey;
      GDL2NonRetainingMutableArray *associations;

      displayGroupEnum = NSEnumerateMapTable(_displayGroupMap);
      while (NSNextMapEnumeratorPair(&displayGroupEnum,
				     &unusedKey, (void*)&displayGroup))
	{
	  [displayGroup retain];
	  [EOObserverCenter addObserver:self forObject:displayGroup];
	}
      NSEndMapTableEnumeration (&displayGroupEnum);
      
      /* registerAssociationForDeallocHack is implemented in
         EOControl/EOEditingContext.m this causes +objectDeallocated:
	 to be called when '_object' is deallocated, which will break the
	 connection which releases the association instance. */
      [self retain];
      [self registerAssociationForDeallocHack:_object];

      associations = (id)NSMapGet(_objectToAssociations, _object);

      if (!associations)
	{
	  associations = [[GDL2NonRetainingMutableArray alloc] initWithCapacity:32];
          [associations addObject:self];
	  NSMapInsert(_objectToAssociations, _object, associations);
	}
      else
	{
	  [associations addObject:self];
	}
      
      _isConnected = YES;
    }
}

- (void)breakConnection
{
  if (_isConnected)
    {
      NSMapEnumerator displayGroupEnum;
      EODisplayGroup *displayGroup;
      void *unusedKey;

      Class EOObserverCenterClass = [EOObserverCenter class];

      displayGroupEnum = NSEnumerateMapTable(_displayGroupMap);
      while (NSNextMapEnumeratorPair(&displayGroupEnum,
				     &unusedKey, (void *)&displayGroup))
	{
	  [displayGroup release];
	  [EOObserverCenterClass removeObserver: self forObject: displayGroup];
	}

      NSEndMapTableEnumeration (&displayGroupEnum);
      [self discardPendingNotification];
      _isConnected = NO;
      [self release]; 
    }
}

- (void)copyMatchingBindingsFromAssociation: (EOAssociation *)association
{
}

- (BOOL)canBindAspect: (NSString *)aspectName
	 displayGroup: (EODisplayGroup *)displayGroup
		  key: (NSString *)key
{
  return YES;
}

- (id)object
{
  return _object;
}

- (EODisplayGroup *)displayGroupForAspect: (NSString *)aspectName
{
  return NSMapGet(_displayGroupMap, aspectName);
}

- (NSString *)displayGroupKeyForAspect: (NSString *)aspectName;
{
  return NSMapGet(_displayGroupKeyMap, aspectName);
}

/** Implemented by subclasses. */
- (void)subjectChanged
{
}

- (BOOL)endEditing
{
  return NO;
}

- (id)valueForAspect: (NSString *)aspectName
{
  EODisplayGroup *dg = [self displayGroupForAspect: aspectName];
  NSString *key;
  
  if (dg == nil)
    return nil;
  
  key = [self displayGroupKeyForAspect: aspectName];
  
  if (key == nil)
    return nil;
   
  return [dg selectedObjectValueForKey: key];
}

- (BOOL)setValue: (id)value forAspect: (NSString *)aspectName
{
  EODisplayGroup *dg = [self displayGroupForAspect: aspectName];
  NSString *key;
  
  if (dg == nil)
    return NO;
  
  key = [self displayGroupKeyForAspect: aspectName];
  
  if (key == nil)
    return NO;
  
  return [dg setSelectedObjectValue: value forKey: key];
}

- (id)valueForAspect: (NSString *)aspectName 
	     atIndex: (unsigned int)index
{
  EODisplayGroup *dg = [self displayGroupForAspect: aspectName];
  NSString *key;

  if (dg == nil)
    return nil;
  
  key = [self displayGroupKeyForAspect: aspectName];
  if (key == nil)
    return NO;
  
  return [dg valueForObjectAtIndex:index 
  			       key: key];
  
}

- (BOOL)setValue: (id)value
       forAspect: (NSString *)aspectName
	 atIndex: (unsigned int)index
{
  EODisplayGroup *dg = [self displayGroupForAspect: aspectName];
  NSString *key;
  BOOL flag;
  
  if (dg == nil)
    {
      return NO;
    }
  
  key = [self displayGroupKeyForAspect: aspectName];
  
  if (key == nil)
    {
      return NO;
    }
  
  flag = [dg setValue: value forObjectAtIndex: index key: key];

  return flag;
}

- (BOOL)shouldEndEditingForAspect: (NSString *)aspectName 
		     invalidInput: (NSString *)input
		 errorDescription: (NSString *)description
{
  EODisplayGroup *displayGroup;
  BOOL reply = YES;

  displayGroup = [self displayGroupForAspect: aspectName];
  if (displayGroup)
    {
      NSString *displayGroupString 
	= [self displayGroupKeyForAspect: aspectName];
      id selectedObject = [displayGroup selectedObject];
      reply = [displayGroup association: self
			    failedToValidateValue: input
			    forKey: displayGroupString
			    object: selectedObject
			    errorDescription: description];
    }
  
  return reply;
}
- (BOOL)shouldEndEditingForAspect: (NSString *)aspectName
		     invalidInput: (NSString *)input
		 errorDescription: (NSString *)description
			    index: (unsigned int)index
{
  EODisplayGroup *displayGroup;
  BOOL reply = YES;

  displayGroup = [self displayGroupForAspect: aspectName];
  if (displayGroup)
    {
      NSString *displayGroupString 
	= [self displayGroupKeyForAspect: aspectName];
      NSArray *displayedObjects = [displayGroup displayedObjects];
      id object = [displayedObjects objectAtIndex: index];
      reply = [displayGroup association: self
			    failedToValidateValue: input
			    forKey: displayGroupString
			    object: object
			    errorDescription: description];
    }
  
  return reply;
}

@end

