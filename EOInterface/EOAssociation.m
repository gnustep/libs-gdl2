/**
   EOAssociation.m

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

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSMapTable.h>
#else
#include <Foundation/Foundation.h>
#endif

#include <GNUstepBase/GSObjCRuntime.h>

#include "EODisplayGroup.h"

#include "EOAssociation.h"

/*++ TEMPORARY LOCAL DEFINITION ++*/
static inline NSArray *
GSObjCAllSubclassesOfClass(Class baseClass)
{
  if (!baseClass)
    return nil;
  
  {
    Class aClass;
    NSMutableArray *result = [NSMutableArray array];
    #ifdef GNU_RUNTIME
    for (aClass = baseClass->subclass_list;
	 aClass;
	 aClass=aClass->sibling_class)
      {
	[result addObject:aClass];
	[result addObjectsFromArray: GSObjCAllSubclassesOfClass(aClass)];
      }
    #endif 
    return AUTORELEASE([result copy]);
  }
}
/*++ TEMPORARY LOCAL DEFINITION ++*/

@implementation EOAssociation
static NSArray *_emptyArray = nil;
static NSMutableArray *_associationClasses = nil;
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

  [_associationClasses count];
  arr = [NSMutableArray arrayWithCapacity: count];
  
  for (i = 0; i < count; i++)
    {
      cls = [_associationClasses objectAtIndex: i];
      if ([cls isUsableWithObject: cls])
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
  return [self initWithObject: nil];
}

- (id)initWithCoder: (NSCoder *)coder
{
  return [self init];
}

- (void) encodeWithCoder: (NSCoder*)coder
{
}

- (void)dealloc
{
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
      Class EOObserverCenterClass = [EOObserverCenter class];

      displayGroupEnum = NSEnumerateMapTable(_displayGroupMap);
      while (NSNextMapEnumeratorPair(&displayGroupEnum,
				     0, (void*)&displayGroup))
	{
	  [EOObserverCenterClass addObserver: self forObject: displayGroup];
	}
      NSEndMapTableEnumeration (&displayGroupEnum);
      _isConnected = YES;
      
      //TODO: cause _object to retain us
    }
}
- (void)breakConnection
{
  if (_isConnected)
    {
      NSMapEnumerator displayGroupEnum;
      EODisplayGroup *displayGroup;
      Class EOObserverCenterClass = [EOObserverCenter class];

      displayGroupEnum = NSEnumerateMapTable(_displayGroupMap);
      while (NSNextMapEnumeratorPair(&displayGroupEnum,
				     0, (void *)&displayGroup))
	{
	  [EOObserverCenterClass removeObserver: self forObject: displayGroup];
	}
      NSEndMapTableEnumeration (&displayGroupEnum);
      _isConnected = YES;
      
      //TODO: cause _object to release us
    }
}

- (void)copyMatchingBindingsFromAssociation: (EOAssociation *)association
{
}

- (BOOL)canBindAspect: (NSString *)aspectName
	 displayGroup: (EODisplayGroup *)displayGroup
		  key: (NSString *)key
{
  return NO;
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

- (void)subjectChanged
{
}

- (BOOL)endEditing
{
  return NO;
}

- (id)valueForAspect: (NSString *)aspectName
{
  return nil;
}
- (BOOL)setValue: (id)value forAspect: (NSString *)aspectName
{
  return NO;
}

- (id)valueForAspect: (NSString *)aspectName 
	     atIndex: (unsigned int)index
{
  return nil;
}
- (BOOL)setValue: (id)value
       forAspect: (NSString *)aspectName
	 atIndex: (unsigned int)index
{
  return NO;
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

- (NSString *)debugDescription
{
  NSLog(@"self:%p", self);
  /*
  NSLog(@"_end1:%p", &_end1);
  NSLog(@"_end2:%p", &_end2);
  */
  NSLog(@"dGM :%p", &_displayGroupMap);
  NSLog(@"dGKM:%p", &_displayGroupKeyMap);
  return nil;
}
@end

