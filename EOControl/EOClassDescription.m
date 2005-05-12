/** 
   EOClassDescription.m <title>EOClassDescription Class</title>

   Copyright (C) 2000, 2001, 2002, 2003 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
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
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
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

#include "EOPrivate.h"

// NOTE: (stephane@sente.ch) Should we subclass NSClassDescription?

/*
   d.ayers@inode.at:  Yes, once we wish to support code written for
   for EOF > WO4.5. No, for now because we don't have direct access
   to the NSMapTable of base/Foundation so we would loose efficiency
   and gain no real benefit.
*/

@interface NSObject (SupressCompilerWarnings)
+(id)defaultGroup;
@end

@implementation EOClassDescription

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

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"aClass=%@", aClass);
  NSAssert(aClass, @"No class");
  NSDebugMLLog(@"gsdb", @"class name=%s", GSNameFromClass(aClass));

  classDescription = NSMapGet(classDescriptionForClass, aClass);  

  NSDebugMLLog(@"gsdb", @"classDescription=%@", classDescription);
  if (!classDescription)
    {
      [[NSNotificationCenter defaultCenter]
	postNotificationName: EOClassDescriptionNeededForClassNotification
	object: aClass];

      classDescription = NSMapGet(classDescriptionForClass, aClass);
      NSDebugMLLog(@"gsdb", @"classDescription=%@", classDescription);

      if (!classDescription)
        {
          NSLog(@"Warning: No class description for class named: %s",
		GSNameFromClass(aClass));
        }
    }

  EOFLOGObjectFnStop();

  return classDescription;
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
};

- (void)awakeObject: (id)object
fromFetchInEditingContext: (EOEditingContext *)anEditingContext
{
  //OK
  //nothing to do
}

- (void)awakeObject: (id)object
fromInsertionInEditingContext: (EOEditingContext *)anEditingContext
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

- (id)createInstanceWithEditingContext: (EOEditingContext *)anEditingContext
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
                  editingContext: (EOEditingContext *)context
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
            shouldPropagate = [classDelegate shouldPropagateDeleteForObject: object
                                             inEditingContext: context
                                             forRelationshipKey: key];
          
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
                      
                      [object removeObject: destination
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
                      [context deleteObject: destination];
                      [destination propagateDeleteWithEditingContext: context];
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
            shouldPropagate = [classDelegate shouldPropagateDeleteForObject: object
                                             inEditingContext: context
                                             forRelationshipKey: key];
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
                      [context deleteObject: destination];
                      [destination propagateDeleteWithEditingContext: context];
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

- (EORelationship *)anyRelationshipNamed:(NSString *)relationshipNamed
{
  return nil;
}

- (NSString *)userPresentableDescriptionForObject:(id)anObject
{
  NSArray *attrArray = [self attributeKeys];
  NSEnumerator *attrEnum = [attrArray objectEnumerator];
  NSMutableString *values = [NSMutableString stringWithCapacity:
					       4 * [attrArray count]];
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

@implementation NSObject (EOInitialization)

- (id)initWithEditingContext: (EOEditingContext *)ec
	    classDescription: (EOClassDescription *)classDesc
		    globalID: (EOGlobalID *)globalID;
{
  return [self init];
}

@end


@implementation NSObject (EOClassDescriptionPrimitives)

- (void)GDL2CDNSObjectICategoryID
{
}

+ (void)load
{
  GDL2_ActivateCategory("NSObject",
                        @selector(GDL2CDNSObjectICategoryID), YES);
}

// when you enable the NSDebugMLLogs here you will have a loop. dave
- (EOClassDescription *)classDescription
{
  EOClassDescription *cd;

  EOFLOGObjectFnStart();
  //NSDebugMLLog(@"gsdb", @"self (%p)=%@ class=%@", self, self, [self class]);

  cd = (EOClassDescription *)[EOClassDescription classDescriptionForClass:
						   [self class]];
  //NSDebugMLLog(@"gsdb", @"classDescription=%@", cd);

  EOFLOGObjectFnStop();

  return cd;
}

- (NSString *)entityName
{
  NSString *entityName;

  EOFLOGObjectFnStart();

  entityName = [[self classDescription] entityName];

  EOFLOGObjectFnStop();

  return entityName;
}

- (NSArray *)attributeKeys
{
  NSArray *attributeKeys;

  EOFLOGObjectFnStart();

  attributeKeys = [[self classDescription] attributeKeys];

  EOFLOGObjectFnStop();

  return attributeKeys;
}

- (NSArray *)toOneRelationshipKeys
{
  NSArray *toOneRelationshipKeys;

  EOFLOGObjectFnStart();

  toOneRelationshipKeys = [[self classDescription] toOneRelationshipKeys];

  EOFLOGObjectFnStop();

  return toOneRelationshipKeys;
}

- (NSArray *)toManyRelationshipKeys
{
  NSArray *toManyRelationshipKeys;

  EOFLOGObjectFnStart();

  toManyRelationshipKeys = [[self classDescription] toManyRelationshipKeys];

  EOFLOGObjectFnStop();

  return toManyRelationshipKeys;
}

- (NSString *)inverseForRelationshipKey: (NSString *)relationshipKey
{
  NSString *inverse;

  EOFLOGObjectFnStart();

  inverse = [[self classDescription]
	      inverseForRelationshipKey: relationshipKey];

  EOFLOGObjectFnStop();

  return inverse;
}

- (EODeleteRule)deleteRuleForRelationshipKey: (NSString *)relationshipKey
{
  EODeleteRule rule;
  EOClassDescription *cd;

  EOFLOGObjectFnStart();
  NSDebugMLLog(@"gsdb", @"self %p=%@", self, self);

  cd = [self classDescription];
  NSDebugMLLog(@"gsdb", @"cd %p=%@", cd, cd);

  rule = [cd deleteRuleForRelationshipKey: relationshipKey];

  EOFLOGObjectFnStop();

  return rule;
}

- (BOOL)ownsDestinationObjectsForRelationshipKey: (NSString *)relationshipKey
{
  BOOL owns;

  EOFLOGObjectFnStart();

  owns = [[self classDescription]
	   ownsDestinationObjectsForRelationshipKey: relationshipKey];

  EOFLOGObjectFnStop();

  return owns;
}

- (EOClassDescription *)classDescriptionForDestinationKey:(NSString *)detailKey
{
  EOClassDescription *cd;

  EOFLOGObjectFnStart();
  NSDebugMLLog(@"gsdb", @"detailKey=%@", detailKey);

  cd = [[self classDescription] classDescriptionForDestinationKey: detailKey];

  EOFLOGObjectFnStop();

  return cd;
}

- (NSString *)userPresentableDescription
{
  NSString *userPresentableDescription = nil;
  NSArray *attrArray;
  NSEnumerator *attrEnum;
  NSString *key;

  EOFLOGObjectFnStart();

  attrArray = [self attributeKeys];
  attrEnum = [attrArray objectEnumerator];

  while ((key = [attrEnum nextObject]))
    {
      if ([key isEqualToString: @"name"])
	return key;
    }

  attrEnum = [attrArray objectEnumerator];
  while ((key = [attrEnum nextObject]))
    {
      if ([key isEqualToString: @"name"])
	return key;
    }

  userPresentableDescription = [[self classDescription]
				 userPresentableDescription];

  EOFLOGObjectFnStop();

  return userPresentableDescription;
}

- (NSException *)validateValue: (id *)valueP
                        forKey: (NSString *)key
{
  NSException *exception;
  EOClassDescription *selfClassDescription;

  EOFLOGObjectFnStart();

  NSAssert(valueP, @"No value pointer");
  NSDebugMLog(@"self (%p) [of class %@]=%@", self, [self class], self);

  selfClassDescription = [self classDescription];
  NSDebugMLog(@"selfClassDescription=%@",selfClassDescription);

  exception = [selfClassDescription validateValue: valueP
                                    forKey: key];
  if (exception)
    {
      NSDictionary *userInfo
	= [NSDictionary dictionaryWithObjectsAndKeys:
			  self, @"EOValidatedObjectUserInfoKey",
			key, @"EOValidatedPropertyUserInfoKey",
			nil];

      exception = [NSException exceptionWithName: [exception name]
			       reason: [exception reason]
			       userInfo: userInfo];
    }

  if (exception == nil)
    {
      int size = [key length];

      if (size < 1)
        {
          [NSException raise: NSInvalidArgumentException
                       format: @"storedValueForKey: ... empty key"];
        }
      else
        {
	  SEL validateSelector;
	  unsigned length = [key length];
	  unsigned char buf[length + 10];

	  strcpy(buf, "validate");
	  [key getCString: &buf[8]];
	  buf[8] = toupper(buf[8]);
	  buf[length + 8] = ':';
	  buf[length + 9] = 0;

	  validateSelector = GSSelectorFromName(buf);
          if (validateSelector && [self respondsToSelector: validateSelector])
	    {
	      exception = [self performSelector: validateSelector
				withObject: *valueP];
	    }
        }
    }

  EOFLOGObjectFnStop();

  return exception;
}

- (NSException *)validateForSave
{
  NSMutableArray *expArray = nil;
  NSException* exception;
  int which;
  IMP selfVFK=NULL; // valueForKey:
  IMP selfVVFK=NULL; // validateValue:forKey:
  IMP selfTVFK=NULL; // takeValue:forKey:

  EOFLOGObjectFnStart();

  exception = [[self classDescription] validateObjectForSave: self];

  if (exception)
    {
      if (!expArray)
        expArray = [NSMutableArray array];
      [expArray  addObject:exception];
    }

  for (which = 0; which < 3; which++)
    {
      NSArray *keys;

      if (which == 0)
        keys = [self attributeKeys];
      else if (which == 1)
        keys = [self toOneRelationshipKeys];
      else
        keys = [self toManyRelationshipKeys];

      if (keys)
        {
          int keysCount = [keys count];
          int i;
          IMP oaiIMP=NULL;

          for (i = 0; i < keysCount; i++)
            {
              NSString *key = GDL2_ObjectAtIndexWithImpPtr(keys,&oaiIMP,i);
              id value = GDL2_ValueForKeyWithImpPtr(self,&selfVFK,key);
              id newValue = value;
              BOOL isEqual=NO;

              exception = GDL2_ValidateValueForKeyWithImpPtr(self,&selfVVFK,&newValue,key);
              if (exception)
                {
                  if (!expArray)
                    expArray = [NSMutableArray array];
                  [expArray addObject: exception];
                }              
              if (newValue==value)
                isEqual = YES;
              else if (_isNilOrEONull(newValue))
                isEqual = _isNilOrEONull(value);
              else 
                isEqual = [newValue isEqual: value];

              if (isEqual == NO)
                {
                  NSDebugMLLog(@"gsdb", @"key=%@ newValue='%@' (class=%@) value='%@' (class=%@)",
                               key,newValue,[newValue class],value,[value class]);
                  GDL2_TakeValueForKeyWithImpPtr(self,&selfTVFK,newValue,key);
                };
            }
        }
    }

  EOFLOGObjectFnStop();

  return [NSException aggregateExceptionWithExceptions: expArray];
}

- (NSException *)validateForDelete
{
  NSException *exception;

  EOFLOGObjectFnStart();

  exception = [[self classDescription] validateObjectForDelete: self];

  EOFLOGObjectFnStop();

  return exception;
}

- (void)awakeFromInsertionInEditingContext: (EOEditingContext *)editingContext
{
  EOFLOGObjectFnStart();

  [[self classDescription] awakeObject: self
			   fromInsertionInEditingContext: editingContext];

  EOFLOGObjectFnStop();
}

- (void)awakeFromFetchInEditingContext: (EOEditingContext *)editingContext
{
  EOFLOGObjectFnStart();

  [[self classDescription] awakeObject: self
			   fromFetchInEditingContext: editingContext];

  EOFLOGObjectFnStop();
}

@end


@implementation NSArray (EOShallowCopy)

- (NSArray *)shallowCopy
{
  return [[NSArray alloc] initWithArray: self];
}

@end


@implementation NSObject (EOClassDescriptionExtras)

- (NSDictionary *)snapshot
{
  //OK Can be Improved may be by using a dictionaryinitializer
  NSMutableDictionary *snapshot;
  NSArray *attributeKeys;
  NSArray *toOneRelationshipKeys;
  NSArray *toManyRelationshipKeys;

  unsigned attributeKeyCount;
  unsigned toOneRelationshipKeyCount;
  unsigned toManyRelationshipKeyCount;
  unsigned i;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"self=%@", self);

  if (self==GDL2_EONull)
    {
      static id emptyDict = nil;
      if (emptyDict == nil)
	{
	  emptyDict = [NSDictionary new];
	}
      NSWarnMLog(@"Warning: self is the EONull instance");
      snapshot = emptyDict;
    }
  else
    {
      IMP selfSVFK=NULL; // storedValueForKey:
      IMP snapshotSOFK=NULL; // setObject:forKey:

      attributeKeys = [self attributeKeys];
      NSDebugMLLog(@"gsdb", @"attributeKeys=%@", attributeKeys);

      toOneRelationshipKeys = [self toOneRelationshipKeys];
      toManyRelationshipKeys = [self toManyRelationshipKeys];

      attributeKeyCount = [attributeKeys count];
      toOneRelationshipKeyCount = [toOneRelationshipKeys count];
      toManyRelationshipKeyCount = [toManyRelationshipKeys count];

      NSDebugMLLog(@"gsdb", 
		   @"attributeKeyCount=%d toOneRelationshipKeyCount=%d "
                   @"toManyRelationshipKeyCount=%d",
                   attributeKeyCount, toOneRelationshipKeyCount,
                   toManyRelationshipKeyCount);

      snapshot 
	= AUTORELEASE([GDL2_alloc(NSMutableDictionary) initWithCapacity:
				   (attributeKeyCount +
				    toOneRelationshipKeyCount +
				    toManyRelationshipKeyCount)]);
      NSDebugMLLog(@"gsdb", @"attributeKeys=%@", attributeKeys);

      if (attributeKeyCount>0)
        {
          IMP oaiIMP=NULL;

          for (i = 0; i < attributeKeyCount; i++)
            {
              id key = GDL2_ObjectAtIndexWithImpPtr(attributeKeys,&oaiIMP,i);
              id value = GDL2_StoredValueForKeyWithImpPtr(self,&selfSVFK,key);
              
              if (!value)
                value = GDL2_EONull;
              
              NSDebugMLLog(@"gsdb", @"snap=%p key=%@ ==> value %p=%@",
                           snapshot, key, value, value);
              GDL2_SetObjectForKeyWithImpPtr(snapshot,&snapshotSOFK,value,key);
            }
        };
      NSDebugMLLog(@"gsdb",
		   @"toOneRelationshipKeys=%@", toOneRelationshipKeys);

      if (toOneRelationshipKeyCount>0)
        {
          IMP oaiIMP=NULL;

          for (i = 0; i < toOneRelationshipKeyCount; i++)
            {
              id key = GDL2_ObjectAtIndexWithImpPtr(toOneRelationshipKeys,
						   &oaiIMP,i);
              id value = GDL2_StoredValueForKeyWithImpPtr(self,&selfSVFK,key);
              
              if (!value)
                value = GDL2_EONull;
              
              NSDebugMLLog(@"gsdb", @"TOONE snap=%p key=%@ ==> value %p=%@",
                           snapshot, key, value, value);
              
              GDL2_SetObjectForKeyWithImpPtr(snapshot,&snapshotSOFK,value,key);
            }
        };

      NSDebugMLLog(@"gsdb",
		   @"toManyRelationshipKeys=%@", toManyRelationshipKeys);

      if (toManyRelationshipKeyCount>0)
        {
          IMP oaiIMP=NULL;

          for (i = 0; i < toManyRelationshipKeyCount; i++)
            {
              id key = GDL2_ObjectAtIndexWithImpPtr(toManyRelationshipKeys,
						   &oaiIMP,i);
              id value = GDL2_StoredValueForKeyWithImpPtr(self,&selfSVFK,key);
              
              if (value)
                {
                  NSDebugMLLog(@"gsdb",
			       @"TOMANY snap=%p key=%@ ==> value %p=%@",
                               snapshot, key, value, value);
                  
                  value = AUTORELEASE([(NSArray *)value shallowCopy]);
                  NSDebugMLLog(@"gsdb",
			       @"TOMANY snap=%p key=%@ ==> value %p=%@",
                               snapshot, key, value, value);
                  
                  GDL2_SetObjectForKeyWithImpPtr(snapshot,&snapshotSOFK,
						value,key);
                }
              /*    //TODO-VERIFY or set it to eonull ?
                    else
                    value=GDL2_EONull;
              */
            }
        };
    }

  NSDebugMLLog(@"gsdb", @"self=%p snapshot=%p", self, snapshot);
  NSDebugMLLog(@"gsdb", @"self %p=%@\nsnapshot %p=%@", self, self, snapshot,
	       snapshot);

  EOFLOGObjectFnStop();

  NSDebugMLLog(@"gsdb", @"self=%p snapshot=%p count=%d",
	       self, snapshot, [snapshot count]);

  return snapshot;
}

- (void)updateFromSnapshot: (NSDictionary *)snapshot
{
  NSEnumerator *snapshotEnum = [snapshot keyEnumerator];
  NSString *key;
  id val;
  IMP selfTSVFK=NULL; // takeStoredValue:forKey:
  IMP snapshotOFK=NULL;
  IMP enumNO=NULL; // nextObject

  while ((key = GDL2_NextObjectWithImpPtr(snapshotEnum,&enumNO)))
    {
      val = GDL2_ObjectForKeyWithImpPtr(snapshot,&snapshotOFK,key);
      
      if (val==GDL2_EONull)
	val = nil;

      if ([val isKindOfClass: GDL2_NSArrayClass])
	val = AUTORELEASE([val mutableCopy]);

      GDL2_TakeStoredValueForKeyWithImpPtr(self,&selfTSVFK,val,key);
    }
}

- (BOOL)isToManyKey: (NSString *)key
{
  NSArray *toMany = [self toManyRelationshipKeys];
  NSEnumerator *toManyEnum = [toMany objectEnumerator];
  NSString *relationship;
  IMP enumNO=NULL; // nextObject

  while ((relationship = GDL2_NextObjectWithImpPtr(toManyEnum,&enumNO)))
    {
      if ([relationship isEqualToString: key])
	return YES;
    }

  return NO;
}

- (NSException *)validateForInsert
{
  NSException *exception;

  EOFLOGObjectFnStart();

  exception = [self validateForSave];

  EOFLOGObjectFnStop();

  return exception;
}

- (NSException *)validateForUpdate
{
  NSException *exception;

  EOFLOGObjectFnStart();

  exception = [self validateForSave];

  EOFLOGObjectFnStop();

  return exception;
}

- (NSArray *)allPropertyKeys
{
  NSArray *toOne;
  NSArray *toMany;
  NSArray *attr;
  NSMutableArray *ret;

  attr = [self attributeKeys];
  toOne = [self toOneRelationshipKeys];
  toMany = [self toManyRelationshipKeys];

  ret = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity:
				 [attr count] + [toOne count] 
			       + [toMany count]]);

  [ret addObjectsFromArray: attr];
  [ret addObjectsFromArray: toOne];
  [ret addObjectsFromArray: toMany];

  return ret;
}

- (void)clearProperties
{
  NSArray *toOne = nil;
  NSArray *toMany = nil;
  NSEnumerator *relEnum = nil;
  NSString *key = nil;
  IMP selfTSVFK=NULL; // takeStoredValue:forKey:
  IMP enumNO=NULL; // nextObject

  EOFLOGObjectFnStart();

  toOne = [self toOneRelationshipKeys];
  toMany = [self toManyRelationshipKeys];

  relEnum = [toOne objectEnumerator];
  enumNO=NULL;

  while ((key = GDL2_NextObjectWithImpPtr(relEnum,&enumNO)))
    GDL2_TakeStoredValueForKeyWithImpPtr(self,&selfTSVFK,nil,key);

  
  relEnum = [toMany objectEnumerator];
  enumNO=NULL;

  while ((key = GDL2_NextObjectWithImpPtr(relEnum,&enumNO)))
    GDL2_TakeStoredValueForKeyWithImpPtr(self,&selfTSVFK,nil,key);

  EOFLOGObjectFnStop();
}

- (void)propagateDeleteWithEditingContext: (EOEditingContext *)editingContext
{
  EOFLOGObjectFnStart();

  [[self classDescription] propagateDeleteForObject: self
			   editingContext: editingContext];

  EOFLOGObjectFnStop();
}

- (NSString *)eoShallowDescription
{
  [self notImplemented: _cmd];
  return nil; //TODO
}

- (NSString *)eoDescription
{
  NSArray *attrArray = [self allPropertyKeys];
  NSEnumerator *attrEnum = [attrArray objectEnumerator];
  NSString *key;
  IMP attrEnumNO=NULL; // nextObject
  IMP retAS=NULL; // appendString:
  IMP selfVFK=NULL; // valueForKey:

  NSMutableString *ret = [NSMutableString
			   stringWithCapacity: 5 * [attrArray count]];

  GDL2_AppendStringWithImpPtr(ret,&retAS,
                             [NSString stringWithFormat:@"<%@ (%p)",
                                       NSStringFromClass([self class]), self]);

  while ((key = GDL2_NextObjectWithImpPtr(attrEnum,&attrEnumNO)))
    {
      GDL2_AppendStringWithImpPtr(ret,&retAS,
                                 [NSString stringWithFormat: @" %@=%@",
                                           key, 
                                           GDL2_ValueForKeyWithImpPtr(self,&selfVFK,key)]);
    }

  GDL2_AppendStringWithImpPtr(ret,&retAS,@">");

  return ret; //TODO
}

@end


@implementation NSObject (EOKeyRelationshipManipulation)

- (void)addObject: (id)object
toPropertyWithKey: (NSString *)key
{
  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"self=%@", self);
  NSDebugMLLog(@"gsdb", @"object=%@", object);
  NSDebugMLLog(@"gsdb", @"key=%@", key);

  if (self==GDL2_EONull)
    {
      NSWarnMLog(@"Warning: self is an EONull. key=%@ object=%@",key,object);
    }
  else
    {
      int size = [key length];

      if (size < 1)
        {
          [NSException raise: NSInvalidArgumentException
                       format: @"addObject:toPropertyWithKey: ... empty key"];
        }
      else
        {
          char buf[size+7];
          GDL2IMP_BOOL rtsIMP=NULL;
          SEL sel=NULL;

          // Test addToKey:

          strcpy(buf, "addTo");
          [key getCString: &buf[5]];
          buf[5] = toupper(buf[5]);
          buf[size+5] = ':';
          buf[size+6] = '\0';

          EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
				@"A aKey=%@ Method [addToKey:] name=%s",
                                key, buf);

          sel = GSSelectorFromName(buf);

          if (sel && GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == YES)
            {
              NSDebugMLLog(@"gsdb", @"selector=%@", NSStringFromSelector(sel));

              [self performSelector: sel
                    withObject: object];
            }
          else
            {
              id val = nil;

              if ([self isToManyKey: key] == YES)
                {
                  EOFLOGObjectLevel(@"gsdb", @"to many");

                  val = [self valueForKey: key]; //should use storedValueForKey: ?

                  NSDebugMLLog(@"gsdb", @"to many val=%@ (%@)", val, [val class]);

                  if ([val containsObject: object])
                    {
                      NSDebugMLog(@"Object %p already in too many val=%@ (%@)",
                                  object, val, [val class]);
                    }
                  else
                    {
                      if ([val isKindOfClass: GDL2_NSMutableArrayClass])
                        {
                          EOFLOGObjectLevel(@"gsdb", @"to many2");
                          [self willChange];
                          [val addObject: object];
                        }
                      else
                        {
                          NSMutableArray *relArray;

			  relArray = (val)
                            ? AUTORELEASE([val mutableCopy])
                            : AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 10]);

                          NSDebugMLLog(@"gsdb", @"relArray=%@ (%@)",
                                       relArray, [relArray class]);

                          [relArray addObject: object];
                          NSDebugMLLog(@"gsdb", @"relArray=%@ (%@)",
                                       relArray, [relArray class]);

                          [self takeValue: relArray
                                forKey: key];
                        }
                    }
                }
              else
                {
                  EOFLOGObjectLevel(@"gsdb", @"key is not to many");

                  [self takeValue: object
                        forKey: key];
                }
            }
        }
    }

  NSDebugMLLog(@"gsdb", @"self=%@", self);
  NSDebugMLLog(@"gsdb", @"object=%@", object);

  EOFLOGObjectFnStop();
}

- (void)removeObject: (id)object
 fromPropertyWithKey: (NSString *)key
{
//self valueForKey:

  EOFLOGObjectFnStart();
  NSDebugMLLog(@"gsdb", @"self=%@", self);
  NSDebugMLLog(@"gsdb", @"object=%@", object);
  NSDebugMLLog(@"gsdb", @"key=%@ class=%@", key, [key class]);

  if (self==GDL2_EONull)
    {
      NSWarnMLog(@"Warning: self is an EONull. key=%@ object=%@",key,object);
    }
  else
    {
      int size = [key length];

      if (size < 1)
        {
          [NSException raise: NSInvalidArgumentException
                       format: @"removeObject:fromPropertyWithKey: ... empty key"];
        }
      else
        {
          char buf[size+12];
          GDL2IMP_BOOL rtsIMP=NULL;
          SEL sel=NULL;

          // Test removeFromKey:

          strcpy(buf, "removeFrom");
          [key getCString: &buf[10]];
	  buf[10] = toupper(buf[10]);
          buf[size+10] = ':';
          buf[size+11] = '\0';

          EOFLOGObjectLevelArgs(@"EOGenericRecordKVC",
				@"A aKey=%@ Method [removeFromKey:] name=%s",
                                key, buf);

          sel = GSSelectorFromName(buf);

          if (sel && GDL2_RespondsToSelectorWithImpPtr(self,&rtsIMP,sel) == YES)
            {
              EOFLOGObjectLevel(@"gsdb", @"responds=YES");
              [self performSelector: sel
                    withObject: object];
            }
          else
            {
              id val = nil;

              EOFLOGObjectLevel(@"gsdb", @"responds=NO");
	  
              if ([self isToManyKey:key] == YES)
                {
                  EOFLOGObjectLevel(@"gsdb", @"key is to many");

                  val = [self valueForKey: key];
                  NSDebugMLLog(@"gsdb", @"val=%@", val);

                  if ([val isKindOfClass: GDL2_NSMutableArrayClass])
                    {
                      [self willChange];
                      [val removeObject: object];
                    }
                  else
                    {
                      NSMutableArray *relArray = nil;

                      if (val)
                        {
                          relArray = AUTORELEASE([val mutableCopy]);

                          [relArray removeObject: object];
                          [self takeValue: relArray
                                forKey: key];
                        }
                    }
                }
              else
                {
                  EOFLOGObjectLevel(@"gsdb", @"key is not to many");
                  [self takeValue: nil
                        forKey: key];
                }
            }
        }
    }

  NSDebugMLLog(@"gsdb", @"self=%@", self);
  NSDebugMLLog(@"gsdb", @"object=%@", object);

  EOFLOGObjectFnStop();
}

- (void)_setObject: (id)object
forBothSidesOfRelationshipWithKey: (NSString*)key
{
  //Near OK
  NSString *inverseKey;
  id oldObject;

  EOFLOGObjectFnStart();
  NSDebugMLLog(@"gsdb", @"self=%@", self);
  NSDebugMLLog(@"gsdb", @"object=%@", object);
  NSDebugMLLog(@"gsdb", @"key=%@", key);

  if (self==GDL2_EONull)
    {
      NSWarnMLog(@"Warning: self is an EONull. key=%@ object=%@",key,object);
    }
  else
    {
      inverseKey = [self inverseForRelationshipKey:key];
      NSDebugMLLog(@"gsdb", @"inverseKey=%@", inverseKey);

      oldObject = [self valueForKey: key];
      NSDebugMLLog(@"gsdb", @"oldObject=%@", oldObject);

      if (inverseKey)
        {
          if (oldObject==GDL2_EONull)
            {
              NSWarnMLog(@"Warning: oldObject is an EONull. self=%@ key=%@ object=%@",self,key,object);
            }
          else
            {
              [oldObject removeObject: self
                         fromPropertyWithKey: inverseKey];
              [object addObject: self
                      toPropertyWithKey: inverseKey];
              /*      if ([object isToManyKey:inverseKey])
                      {
                      //??
                      EOFLOGObjectLevel(@"gsdb",@"Inverse is to many");
                      [oldObject removeObject:self
                      fromPropertyWithKey:inverseKey];
                      [object addObject:self
                      toPropertyWithKey:inverseKey];
                      }
                      else
                      {
                      EOFLOGObjectLevel(@"gsdb",@"Inverse is not to many");
                      //OK
                      //MIRKO      if ((inverseKey = [oldObject inverseForRelationshipKey:key]))
                      //MIRKO [oldObject removeObject:self
                      //           fromPropertyWithKey:inverseKey];
                      [oldObject takeValue:nil
                      forKey:inverseKey];
                      [object  takeValue:self
                      forKey:inverseKey];
                      };
              */
            }
        }

      [self takeValue: object
            forKey: key];
    }

  NSDebugMLLog(@"gsdb", @"self=%@", self);
  NSDebugMLLog(@"gsdb", @"object=%@", object);

  EOFLOGObjectFnStop();
}

- (void)addObject: (id)object
toBothSidesOfRelationshipWithKey: (NSString *)key
{
  EOFLOGObjectFnStart();

  NSDebugMLLog(@"gsdb", @"self=%@", self);
  NSDebugMLLog(@"gsdb", @"object=%@", object);
  NSDebugMLLog(@"gsdb", @"key=%@", key);

  if (self==GDL2_EONull)
    {
      NSWarnMLog(@"Warning: self is an EONull. key=%@ object=%@",key,object);
    }
  else
    {
      // 2 differents cases: to-one and to-many relation
      if ([self isToManyKey:key]) // to-many
        {
          //See if there's an inverse relationship
          NSString *inverseKey = [self inverseForRelationshipKey: key];

          NSDebugMLLog(@"gsdb", @"self %p=%@,object %p=%@ key=%@ inverseKey=%@",
                       self,
                       self,
                       object,
                       object,
                       key,
                       inverseKey);

          // First add object to self relation array
          [self addObject: object
                toPropertyWithKey: key];

          if (inverseKey) //if no inverse relation do nothing 
            {
              if (object==GDL2_EONull)
                {
                  NSWarnMLog(@"Warning: object is an EONull. self=%@ key=%@ object=%@",self,key,object);
                }
              else
                {
                  // See if inverse relationship is to-many or to-one
                  if ([object isToManyKey: inverseKey])
                    {
                      //TODO VERIFY
                      [object addObject:self
                              toPropertyWithKey:inverseKey];
                    }
                  else
                    {
                      // Previous value, if any
                      id oldObject = [object valueForKey: inverseKey];

                      NSDebugMLLog(@"gsdb", @"oldObject=%@", oldObject);

                      if (oldObject)
                        {
                          //TODO VERIFY
                          [object removeObject:oldObject
                                  fromPropertyWithKey:inverseKey];
                        }

                      // Just set self into object relationship property
                      [object takeValue: self
                              forKey: inverseKey];
                    }
                }
            }
        }
      else
        {
          [self _setObject: object
                forBothSidesOfRelationshipWithKey: key];
        }
    }

  NSDebugMLLog(@"gsdb", @"self=%@", self);
  NSDebugMLLog(@"gsdb", @"object=%@", object);

  EOFLOGObjectFnStop();
}

- (void)removeObject: (id)object
fromBothSidesOfRelationshipWithKey: (NSString *)key
{
  EOFLOGObjectFnStart();

  if (self==GDL2_EONull)
    {
      NSWarnMLog(@"Warning: self is an EONull. key=%@ object=%@",key,object);
    }
  else
    {
      NSString *inverseKey=nil;

      [self removeObject: object
            fromPropertyWithKey: key];

      if ((inverseKey = [self inverseForRelationshipKey: key]))
        {
          if (object==GDL2_EONull)
            {
              NSWarnMLog(@"Warning: object is an EONull. self=%@ key=%@",self,key);
            }
          else
            {
              [object removeObject: self
                      fromPropertyWithKey: inverseKey];
            }
        };
    }

  EOFLOGObjectFnStop();
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
                      inEditingContext: (EOEditingContext *)ec
                    forRelationshipKey: (NSString *)key
{
  return YES;
}

@end


@implementation NSObject (_EOValueMerging)

- (void)mergeValue: (id)value
            forKey: (id)key
{
  [self notImplemented:_cmd];
  return;
}

- (void)mergeChangesFromDictionary: (NSDictionary *)changes
{
  [self notImplemented:_cmd];
  return;
}

- (NSDictionary *)changesFromSnapshot: (NSDictionary *)snapshot
{
  id propertiesList[2];
  NSArray *properties;
  int h, i, count;
  NSMutableArray *newKeys
    = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 16]);
  NSMutableArray *newVals
    = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 16]);
  NSString *key;
  IMP selfSVFK=NULL; // storedValueForKey:
  IMP snapshotSVFK=NULL; // storedValueForKey:
  IMP newKeysAO=NULL;
  IMP newValsAO=NULL;

  propertiesList[0] = [self attributeKeys];
  propertiesList[1] = [self toOneRelationshipKeys];

  for (h = 0; h < 2; h++)
    {
      id val, oldVal;
      IMP oaiIMP=NULL;

      properties = propertiesList[h];
      count = [properties count];

      for(i = 0; i < count; i++)
        {
          key = GDL2_ObjectAtIndexWithImpPtr(properties, &oaiIMP, i);
          val = GDL2_StoredValueForKeyWithImpPtr(self, &selfSVFK, key);
          oldVal = GDL2_StoredValueForKeyWithImpPtr(snapshot, &snapshotSVFK, key);
          
          if (val == oldVal || [val isEqual: oldVal] == YES)
            continue;
          
          GDL2_AddObjectWithImpPtr(newKeys,&newKeysAO,key);
          GDL2_AddObjectWithImpPtr(newVals,&newValsAO,val);
        };
    }

  properties = [self toManyRelationshipKeys];
  count = [properties count];

  if (count>0)
    {
      IMP oaiIMP=NULL;
      for(i = 0; i < count; i++)
        {
          NSMutableArray *array, *objects;
          NSArray *val, *oldVal;
          int valCount, oldValCount;

          key = GDL2_ObjectAtIndexWithImpPtr(properties, &oaiIMP, i);
          val = GDL2_StoredValueForKeyWithImpPtr(self, &selfSVFK, key);
          oldVal = GDL2_StoredValueForKeyWithImpPtr(snapshot, &snapshotSVFK, key);
          
          if ((id)val == GDL2_EONull)
            val = nil;
          
          if ((id)oldVal == GDL2_EONull)
            oldVal = nil;
          
          if (!val && !oldVal)
            continue;
          
          valCount = [val count];
          oldValCount = [oldVal count];
          
          if (valCount == 0 && oldValCount == 0)
            continue;
          
          array 
	    = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 2]);

          if (val && valCount>0)
            {
              objects 
		= AUTORELEASE([GDL2_alloc(NSMutableArray) initWithArray: val]);
              [objects removeObjectsInArray: oldVal];
            }
          else
            objects 
	      = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 1]);
          
          [array addObject: objects];
          
          if (val && valCount > 0)
            {
              objects 
		= AUTORELEASE([GDL2_alloc(NSMutableArray) initWithArray: oldVal]);
              [objects removeObjectsInArray: val];
            }
          else
            objects 
	      = AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: 1]);
          
          [array addObject: objects];
          
          GDL2_AddObjectWithImpPtr(newKeys,&newKeysAO,key);
          GDL2_AddObjectWithImpPtr(newVals,&newValsAO,array);
        }
    };

  return [NSDictionary dictionaryWithObjects: newVals forKeys: newKeys];
}

- (void)reapplyChangesFromSnapshot: (NSDictionary *)changes
{
  [self notImplemented: _cmd];
}

@end

@implementation NSObject (_EOEditingContext)

- (EOEditingContext*)editingContext
{
  return [EOObserverCenter observerForObject: self
                           ofClass: [EOEditingContext class]];
}

@end

