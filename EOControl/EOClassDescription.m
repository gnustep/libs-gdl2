/** 
   EOClassDescription.m <title>EOClassDescription Class</title>

   Copyright (C) 2000, 2001, 2002, 2003, 2004, 2005 
   Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
   Date: February 2000

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: November 2001

   $Revision$
   $Date$

   <abstract></abstract>

   This file is part of the GNUstep Database Library.

   <license>
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   </license>
**/

#include "config.h"

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSFormatter.h>
#include <Foundation/NSException.h>
#include <Foundation/NSMapTable.h>
#include <Foundation/NSZone.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <GNUstepBase/GSLock.h>

#include <EOControl/EOClassDescription.h>
#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EONull.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EOCheapArray.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>
#include <EOControl/EOMutableKnownKeyDictionary.h>
#include <EOControl/EOCustomObject.h>

#include "EOPrivate.h"

// NOTE: (stephane@sente.ch) Should we subclass NSClassDescription?

/*
   ayers@fsfe.org:  Yes, once we wish to support code written for
   for EOF > WO4.5. No, for now because we don't have direct access
   to the NSMapTable of base/Foundation so we would loose efficiency
   and gain no real benefit.
*/

@interface NSObject (SupressCompilerWarnings)
+(id)defaultGroup;
@end

NSString *EOClassDescriptionNeededNotification 
      = @"EOClassDescriptionNeededNotification";

NSString *EOClassDescriptionNeededForClassNotification 
      = @"EOClassDescriptionNeededForClassNotification";

NSString *EOClassDescriptionNeededForEntityNameNotification
      = @"EOClassDescriptionNeededForEntityNameNotification";

NSString *EOValidationException = @"EOValidationException";
NSString *EOAdditionalExceptionsKey = @"EOAdditionalExceptionsKey";
NSString *EOValidatedObjectUserInfoKey = @"EOValidatedObjectUserInfoKey";
NSString *EOValidatedPropertyUserInfoKey = @"EOValidatedPropertyUserInfoKey";

/*
 * Globals
 */

static NSMapTable *classDescriptionForEntity = NULL;
static NSMapTable *classDescriptionForClass = NULL;
static id classDelegate = nil;
static NSRecursiveLock *local_lock = nil;

@implementation EOClassDescription

+ (void) initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      Class cls = Nil;

      initialized=YES;

      GDL2_PrivateInit();

      cls = NSClassFromString(@"EOModelGroup");


      local_lock = [GSLazyRecursiveLock new];
      classDescriptionForClass = NSCreateMapTable(NSObjectMapKeyCallBacks, 
						  NSObjectMapValueCallBacks,
						  32);

      classDescriptionForEntity = NSCreateMapTable(NSObjectMapKeyCallBacks, 
						   NSObjectMapValueCallBacks,
						   32);
      if (cls != Nil)
	[cls defaultGroup]; // Insure correct initialization.

    }
}


/*
 *  Methods
 */

+ (id)classDelegate
{
  id      delegate;
  
  [local_lock lock];
  delegate = classDelegate;
  
  if (delegate != nil)
    {
      AUTORELEASE(RETAIN(delegate));
    }
  [local_lock unlock];

  return delegate;
}

+ (EOClassDescription *)classDescriptionForClass:(Class)aClass
{
  EOClassDescription *classDescription;

  NSAssert(aClass, @"No class");

  classDescription = NSMapGet(classDescriptionForClass, aClass);  

  if (!classDescription)
    {
      [[NSNotificationCenter defaultCenter]
	postNotificationName: EOClassDescriptionNeededForClassNotification
	object: aClass];

      classDescription = NSMapGet(classDescriptionForClass, aClass);

      if (!classDescription)
        {
          NSLog(@"Warning: No class description for class named: %@",
		NSStringFromClass(aClass));
	  NSMapInsert(classDescriptionForClass, aClass, GDL2_EONull);
        }
    }

  return classDescription == (id)GDL2_EONull ? nil : classDescription;
}

+ (EOClassDescription *)classDescriptionForEntityName: (NSString *)entityName
{
  EOClassDescription* classDescription;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"entityName=%@", entityName);

  classDescription = NSMapGet(classDescriptionForEntity, entityName);
  NSDebugMLLog(@"gsdb", @"classDescription=%@", classDescription);

  if (!classDescription)
    {
      [[NSNotificationCenter defaultCenter]
	postNotificationName: EOClassDescriptionNeededForEntityNameNotification
	object: entityName];

      classDescription = NSMapGet(classDescriptionForEntity, entityName);
      NSDebugMLLog(@"gsdb", @"classDescription=%@", classDescription);

      if (!classDescription)
        {
          NSLog(@"Warning: No class description for entity named: %@",
		entityName);
        }
    }

  EOFLOGObjectFnStop();

  return classDescription;
}

+ (void)invalidateClassDescriptionCache
{
  NSResetMapTable(classDescriptionForClass);
  NSResetMapTable(classDescriptionForEntity);
}

+ (void)registerClassDescription: (EOClassDescription *)description
                        forClass: (Class)aClass
{
  NSString *entityName;

  EOFLOGObjectFnStart();

  NSAssert(description, @"No class description");
  NSAssert(aClass, @"No class");
  NSDebugMLLog(@"gsdb", @"description=%@", description);

  entityName = [description entityName];
  //NSAssert(entityName,@"No Entity Name");
  NSDebugMLLog(@"gsdb", @"entityName=%@", entityName);

  NSMapInsert(classDescriptionForClass, aClass, description);
  if (entityName)
    {
      NSMapInsert(classDescriptionForEntity, entityName, description);
    }
  NSDebugMLLog(@"gsdb", @"end");

  EOFLOGObjectFnStop();
}

+ (void)setClassDelegate:(id)delegate
{
  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb",@"delegate %p=%@", delegate, delegate);
  classDelegate = delegate;

  EOFLOGObjectFnStop();
}

- (NSArray *)attributeKeys
{
  return nil;
}

/** returns a new autoreleased mutable dictionary to store properties **/
- (NSMutableDictionary *)dictionaryForInstanceProperties
{
  // Default implementation create a new EOMKKDInitializer. But subclass 
  // implementation like EOEntityClassDescription can (should :-) use the 
  // same EOMKKDInitializer to save memory.

  NSMutableArray* classPropertyNames=nil;
  NSMutableDictionary* dictionary=nil;

  EOFLOGObjectFnStart();

  // Get class properties (attributes + relationships)
  classPropertyNames = [[NSMutableArray alloc]
                         initWithArray: [self attributeKeys]];
  [classPropertyNames addObjectsFromArray:
                        [self toOneRelationshipKeys]];
  [classPropertyNames addObjectsFromArray:
                        [self toManyRelationshipKeys]];
  
  NSAssert1([classPropertyNames count] > 0,
            @"No classPropertyNames in %@", self);
  
  dictionary = [EOMutableKnownKeyDictionary
                 dictionaryWithInitializer:
                   [[EOMKKDInitializer newWithKeyArray: classPropertyNames] autorelease]];
  [classPropertyNames release];

  EOFLOGObjectFnStop();

  return dictionary;
}

- (void)awakeObject: (id)object
fromFetchInEditingContext: (EOEditingContext *)editingContext
{
  //OK
  //nothing to do
  return;
}

- (void)awakeObject: (id)object
fromInsertionInEditingContext: (EOEditingContext *)editingContext
{
  //Near OK
  NSArray *toManyRelationshipKeys = nil;
  int toManyCount = 0;

  EOFLOGObjectFnStart();

  toManyRelationshipKeys = [self toManyRelationshipKeys];
  toManyCount = [toManyRelationshipKeys count];

  if (toManyCount > 0)
    {
      int i;
      IMP oaiIMP=NULL;
      IMP objectTSVFK=NULL; // takeStoredValue:forKey:
      IMP objectSVFK=NULL; // storedValueForKey:

      for (i = 0; i < toManyCount; i++)
        {
          id key = GDL2_ObjectAtIndexWithImpPtr(toManyRelationshipKeys,&oaiIMP,i);
          id value = GDL2_StoredValueForKeyWithImpPtr(object,&objectSVFK,key);
          NSDebugMLLog(@"gsdb", @"key=%@ value=%@",key,value);

          if (value)
            {
              //Do nothing ??
            }
          else
            {
              GDL2_TakeStoredValueForKeyWithImpPtr(object,&objectTSVFK,
                                                  [EOCheapCopyMutableArray arrayWithCapacity: 2],
                                                  key);
            }
        }
    }
  EOFLOGObjectFnStop();
}

- (EOClassDescription *)classDescriptionForDestinationKey: (NSString *)detailKey
{
  return nil;
}

- (id)createInstanceWithEditingContext: (EOEditingContext *)editingContext
                              globalID: (EOGlobalID *)globalID
                                  zone: (NSZone *)zone
{
  EOFLOGObjectFnStart();
  EOFLOGObjectFnStop();

  return nil;
}

- (NSFormatter *)defaultFormatterForKey: (NSString *)key
{
  return nil;
}

- (NSFormatter *)defaultFormatterForKeyPath: (NSString *)keyPath
{
  return nil; //TODO
}

- (EODeleteRule)deleteRuleForRelationshipKey: (NSString *)relationshipKey
{
  //OK
  EOFLOGObjectFnStart();
  EOFLOGObjectFnStop();

  return EODeleteRuleNullify;
}

- (NSString *)displayNameForKey: (NSString *)key
{
  const char *s, *ckey = [key cString];
  NSMutableString *str = [NSMutableString stringWithCapacity:[key length]];
  char c;
  BOOL init = NO;
  IMP strAS=NULL;

  s = ckey;

  while (*s)
    {
      if (init && s == ckey && islower(*s))
        {
	  c = toupper(*s);
	  GDL2_AppendStringWithImpPtr(str,&strAS,
                                     GDL2_StringWithCStringAndLength(&c,1));
        }
      else if (isupper(*s) && s != ckey)
        {
	  GDL2_AppendStringWithImpPtr(str,&strAS,
                                     GDL2_StringWithCStringAndLength(ckey,s - ckey));
	  GDL2_AppendStringWithImpPtr(str,&strAS,@" ");
	  ckey = s;
        }

      init = NO;
      s++;
    }

  if (s != ckey)
    GDL2_AppendStringWithImpPtr(str,&strAS,
                               GDL2_StringWithCStringAndLength(ckey,s - ckey));

  return AUTORELEASE([key copy]);
}

- (NSString *)entityName
{
  //OK
  return nil;
}

- (NSString *)inverseForRelationshipKey: (NSString *)relationshipKey
{
  return nil;
}

- (BOOL)ownsDestinationObjectsForRelationshipKey: (NSString *)relationshipKey
{
  return NO;
}

- (void)propagateDeleteForObject: (id)object
                  editingContext: (EOEditingContext *)editingContext
{
  NSArray *toRelArray;
  NSEnumerator *toRelEnum;
  NSString *key; //, *inverseKey = nil;
  id destination = nil;
  id classDelegate;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb",@"object %p=%@", object, object);

  if (object==GDL2_EONull)
    {
      NSWarnMLog(@"Warning: object is an EONull");
    }
  else
    {
      IMP objectSVFK=NULL; // storedValueForKey:
      IMP objectVFK=NULL;
      IMP toRelEnumNO=NULL;

      classDelegate = [[self class] classDelegate];

      NSDebugMLLog(@"gsdb", @"classDelegate%p=%@",
                   classDelegate,
                   classDelegate);
      
      toRelArray = [object toOneRelationshipKeys];
      toRelEnum = [toRelArray objectEnumerator];
      
      while ((key = GDL2_NextObjectWithImpPtr(toRelEnum,&toRelEnumNO)))
        {
          BOOL shouldPropagate = YES;
          
          NSDebugMLLog(@"gsdb", @"ToOne key=%@", key);
          
          if (classDelegate)
	    {
	      shouldPropagate 
		= [classDelegate shouldPropagateDeleteForObject: object
				 inEditingContext: editingContext
				 forRelationshipKey: key];
	    }
          
          NSDebugMLLog(@"gsdb", @"ToOne key=%@ shouldPropagate=%s", key,
                       (shouldPropagate ? "YES" : "NO"));
          
          if (shouldPropagate)
            {
              destination = GDL2_StoredValueForKeyWithImpPtr(object,&objectSVFK,key);
              NSDebugMLLog(@"gsdb", @"destination %p=%@",
                           destination, destination);
              
              if (!_isNilOrEONull(destination))
                {
                  EODeleteRule deleteRule = [object deleteRuleForRelationshipKey:
                                                      key];

                  NSDebugMLLog(@"gsdb", @"deleteRule=%d", (int)deleteRule);

                  switch (deleteRule)
                    {
                    case EODeleteRuleNullify:
                      EOFLOGObjectLevel(@"gsdb", @"EODeleteRuleNullify");
                      
                        [(EOCustomObject*) object removeObject: destination
                            fromBothSidesOfRelationshipWithKey: key];
                      /*
                        [object takeValue:nil
                        forKey:key];
                        inverseKey = [object inverseForRelationshipKey:key];
                        NSDebugMLLog(@"gsdb",@"inverseKey=%@",inverseKey);
                        
                        if (inverseKey)
                        // p.ex. : the statement  [employee inverseForRelationshipKey:@"department"] --> returns "employees"
                        [destination removeObject:object
                        fromPropertyWithKey:inverseKey];
                      */
                      break;
                      
                    case EODeleteRuleCascade:
                      //OK
                      EOFLOGObjectLevel(@"gsdb", @"EODeleteRuleCascade");
                      [object removeObject: destination
                              fromBothSidesOfRelationshipWithKey: key];
                      [editingContext deleteObject: destination];
                      [destination propagateDeleteWithEditingContext: editingContext];
                      break;
                      
                    case EODeleteRuleDeny:
                      EOFLOGObjectLevel(@"gsdb", @"EODeleteRuleDeny");
                      // TODO don't know how to do yet, if raise an exception
                      // or something else.
                      NSEmitTODO();  
                      [self notImplemented: _cmd];
                      break;
                      
                    case EODeleteRuleNoAction:
                      EOFLOGObjectLevel(@"gsdb", @"EODeleteRuleNoAction");
                      break;
                    }
                }
            }
        }
    
      toRelArray = [self toManyRelationshipKeys];
      toRelEnum = [toRelArray objectEnumerator];
      toRelEnumNO=NULL;

      while ((key = GDL2_NextObjectWithImpPtr(toRelEnum,&toRelEnumNO)))
        {
          BOOL shouldPropagate = YES;

          NSDebugMLLog(@"gsdb", @"ToMany key=%@", key);

          if (classDelegate)
	    {
	      shouldPropagate 
		= [classDelegate shouldPropagateDeleteForObject: object
				 inEditingContext: editingContext
				 forRelationshipKey: key];
	    }
          NSDebugMLLog(@"gsdb", @"ToMany key=%@ shouldPropagate=%s", key,
                       (shouldPropagate ? "YES" : "NO"));

          if (shouldPropagate)
            {
              NSArray *toManyArray;
              IMP toManyArrayLO=NULL;
              EODeleteRule deleteRule;

              toManyArray = GDL2_ValueForKeyWithImpPtr(object,&objectVFK,key);
              NSDebugMLLog(@"gsdb", @"toManyArray %p=%@", toManyArray, toManyArray);

              deleteRule = [object deleteRuleForRelationshipKey: key];
              NSDebugMLLog(@"gsdb", @"deleteRule=%d", (int)deleteRule);

              switch (deleteRule)
                {
                case EODeleteRuleNullify:
                  EOFLOGObjectLevel(@"gsdb", @"EODeleteRuleNullify");
                  NSDebugMLLog(@"gsdb", @"toManyArray %p=%@", toManyArray,
                               toManyArray);

                  while ((destination = GDL2_LastObjectWithImpPtr(toManyArray,&toManyArrayLO)))
                    {
                      NSDebugMLLog(@"gsdb", @"destination %p=%@", destination,
                                   destination);

                      [object removeObject: destination
                              fromBothSidesOfRelationshipWithKey: key];
                      /*
                        inverseKey = [self inverseForRelationshipKey:key];
                        NSDebugMLLog(@"gsdb",@"inverseKey=%@",inverseKey);

                        if (inverseKey)
                        [destination removeObject:object
                        fromPropertyWithKey:inverseKey];
                      */
                    }
                  NSDebugMLLog(@"gsdb", @"toManyArray %p=%@",
                               toManyArray, toManyArray);
                  break;

                case EODeleteRuleCascade:
                  //OK
                  EOFLOGObjectLevel(@"gsdb", @"EODeleteRuleCascade");
                  NSDebugMLLog(@"gsdb", @"toManyArray %p=%@",
                               toManyArray, toManyArray);

                  while ((destination = GDL2_LastObjectWithImpPtr(toManyArray,&toManyArrayLO)))
                    {
                      NSDebugMLLog(@"gsdb", @"destination %p=%@",
                                   destination, destination);

                      [object removeObject: destination
                              fromBothSidesOfRelationshipWithKey: key];
                      [editingContext deleteObject: destination];
                      [destination propagateDeleteWithEditingContext: editingContext];
                    }
                  NSDebugMLLog(@"gsdb", @"toManyArray %p=%@",
                               toManyArray, toManyArray);
                  break;

                case EODeleteRuleDeny:
                  EOFLOGObjectLevel(@"gsdb", @"EODeleteRuleDeny");
                  NSDebugMLLog(@"gsdb", @"toManyArray %p=%@",
                               toManyArray, toManyArray);
                  if ([toManyArray count] > 0)
                    {
                      // TODO don't know how to do yet, if raise an exception
                      // or something else.
                      NSEmitTODO();  
                      [self notImplemented: _cmd];
                    }
                  break;

                case EODeleteRuleNoAction:
                  EOFLOGObjectLevel(@"gsdb", @"EODeleteRuleNoAction");
                  break;
                }
            }
        }
    }

  EOFLOGObjectFnStop();
}

- (NSArray *)toManyRelationshipKeys
{
  //OK
  return nil;
}

- (NSArray *)toOneRelationshipKeys
{
  //OK
  return nil;
}

- (EORelationship *)relationshipNamed:(NSString *)relationshipName
{
  //OK
  return nil;
}

- (EORelationship *)anyRelationshipNamed:(NSString *)relationshipName
{
  return nil;
}

- (NSString *)userPresentableDescriptionForObject:(id)object
{
  NSArray *attrArray = [self attributeKeys];
  NSEnumerator *attrEnum = [attrArray objectEnumerator];
  NSMutableString *values 
    = [NSMutableString stringWithCapacity: 4 * [attrArray count]];
  NSString *key;
  BOOL init = YES;

  attrEnum = [attrArray objectEnumerator];

  while ((key = [attrEnum nextObject]))
    {
      if (!init)
	[values appendString: @","];

      [values appendString: [[self valueForKey: key] description]];
      init = NO;
    }
  
  return values;
}

- (NSException *)validateObjectForDelete: (id)object
{
  return nil;
}

- (NSException *)validateObjectForSave:(id)object
{
  return nil;
}

- (NSException *)validateValue: (id *)valueP
                        forKey: (NSString *)key
{
  return nil;
}


@end

@implementation EOClassDescription (Deprecated)

+ (void)setDelegate: (id)delegate
{
  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"delegate %p=%@", delegate, delegate);

  [EOClassDescription setClassDelegate: delegate];

  EOFLOGObjectFnStop();
}

+ (id)delegate
{
  return [EOClassDescription classDelegate];
}

@end

@interface GDL2CDNSObject
@end
@interface GDL2CDNSObject (EOClassDescription) <NSObject>
+ (EOClassDescription*) classDescriptionForClass: (Class)aClass;
- (id) valueForKey: (NSString*)aKey;
- (void) takeValue: (id)anObject forKey: (NSString*)aKey;
@end


@implementation NSArray (EOShallowCopy)

- (NSArray *)shallowCopy
{
  return [[NSArray alloc] initWithArray: self];
}

@end


@implementation NSException (EOValidationError)

+ (NSException *)validationExceptionWithFormat: (NSString *)format, ...
{
  NSException *exp = nil;
  NSString *aName = nil;
  va_list args;

  va_start(args, format);

  aName = AUTORELEASE([[NSString alloc] initWithFormat: format
					arguments: args]);
  exp = [NSException exceptionWithName: EOValidationException
		     reason: aName
		     userInfo: nil];

  va_end(args);

  return exp;
}

+ (NSException *)aggregateExceptionWithExceptions: (NSArray *)subexceptions
{
  NSException *exp = nil;

  if ([subexceptions count] == 1)
    exp = [subexceptions objectAtIndex: 0];
  else if ([subexceptions count] > 1)
    {
      NSString *aName = nil, *aReason = nil;
      NSMutableDictionary *aUserInfo = nil;

      exp = [subexceptions objectAtIndex: 0];

      aName     = [exp name];
      aReason   = [exp reason];
      aUserInfo = AUTORELEASE([[exp userInfo] mutableCopy]);

      [aUserInfo setObject: subexceptions
		 forKey: EOAdditionalExceptionsKey];

      exp = [NSException exceptionWithName: aName
                         reason: aReason
                         userInfo: aUserInfo];
    }

  return exp;
}

- (NSException *)exceptionAddingEntriesToUserInfo: (NSDictionary *)additions
{
  NSException *exp = nil;
  NSString *aName = nil, *aReason = nil;
  NSMutableDictionary *aUserInfo = nil;

  aName     = [self name];
  aReason   = [self reason];
  aUserInfo = AUTORELEASE([[self userInfo] mutableCopy]);

  [aUserInfo setObject: [additions allValues]
	     forKey: EOValidatedObjectUserInfoKey];
  [aUserInfo setObject: [additions allKeys]
	     forKey: EOValidatedPropertyUserInfoKey];

  exp = [NSException exceptionWithName: aName
		     reason: aReason
		     userInfo: aUserInfo];

  return exp;
}

@end


@implementation NSObject (EOClassDescriptionClassDelegate)

- (BOOL)shouldPropagateDeleteForObject: (id)object
                      inEditingContext: (EOEditingContext *)editingContext
                    forRelationshipKey: (NSString *)key
{
  return YES;
}

@end



