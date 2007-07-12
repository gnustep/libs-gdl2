/** 
   EOKeyValueArchiver.m <title>EOKeyValueArchiver Class</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: September 2000

   $Revision$
   $Date$

   <abstract>
   EOKeyValueArchiver object is used to archive a tree of objects into a 
   	key/value propertyList.
   EOKeyValueUnarchiver object is used to unarchive from a propertyList a 
	tree of objects archived with a EOKeyValueArchiver.

   Example:

   // Archiving:
   EOKeyValueArchiver* archive=AUTORELEASE([EOKeyValueArchiver new]);
   [archive setDelegate:MyArchivingDelegate];
   [archiver encodeObject:anObject
   forKey:@"anObjectKey"];
   [archiver encodeInt:125
   forKey:@"aKey"];
   ...

   NSDictionary* archivePropertyList=[archiver dictionary];

   // Now unarchive archivePropertyList

   EOKeyValueUnarchiver* unarchiver=AUTORELEASE([[EOKeyValueUnarchiver alloc]initWith:archivePropertyList]);
   [archive setDelegate:MyUnarchivingDelegate];
   id anObject=[unarchiver decodeObjectForKey:@"anObjectKey"];
   int anInt=[unarchiver decodeIntForKey:@"anKey"];
   [unarchiver finishInitializationOfObjects];
   [unarchiver awakeObjects]
   </abstract>

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
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSValue.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOKeyValueArchiver.h>
#include <EOControl/EODebug.h>
#include <EOControl/EOPrivate.h>


@interface EOKeyValueArchivingContainer : NSObject
{
  id _object;
  id _parent;
  NSDictionary * _propertyList;
}

+ (EOKeyValueArchivingContainer*)keyValueArchivingContainer;
- (void) setPropertyList: (id)propList;
- (id) propertyList;
- (void) setParent: (id)parent;
- (id) parent;
- (void) setObject: (id)object;
- (id) object;

@end


@implementation EOKeyValueArchivingContainer

+ (void)initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized=YES;

      GDL2_PrivateInit();
    }
}

+ (EOKeyValueArchivingContainer *)keyValueArchivingContainer
{
  return [[[self alloc] init] autorelease];
}

- (void) setPropertyList: (id)propList
{
  ASSIGN(_propertyList, propList);
}

- (id) propertyList
{
  return _propertyList;
}

- (void) setParent: (id)parent
{
  _parent = parent;
}

- (id) parent
{
  return _parent;
}

- (void) setObject: (id)object
{
  ASSIGN(_object, object);
}

- (id) object
{
  return _object;
}

- (void) dealloc
{
  DESTROY(_object);
  _parent = nil;
  DESTROY(_propertyList);

  [super dealloc];
}

@end

@implementation EOKeyValueArchiver

+ (void)initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized=YES;

      GDL2_PrivateInit();
    }
}

/** Init method **/
- (id) init
{
  if ((self=[super init]))
    {
      _propertyList=[NSMutableDictionary new];
    };
  return self;
}

- (void) dealloc
{
  DESTROY(_propertyList);
  [super dealloc];
}

/** Returns archived object/tree as propertList **/
- (NSDictionary*) dictionary
{
  EOFLOGObjectFnStartOrCond(@"EOKeyValueArchiver");
  EOFLOGObjectFnStopOrCond(@"EOKeyValueArchiver");
  return _propertyList;
}

/** Archives integer 'intValue' as 'key' **/
- (void) encodeInt: (int)intValue
	    forKey: (NSString*)key
{
  EOFLOGObjectFnStartOrCond(@"EOKeyValueArchiver");

  NSDebugMLLog(@"gsdb", @"key=%@ intValue=%d",key,intValue);
  NSAssert(key,@"No key");

  [_propertyList setObject: [NSNumber numberWithInt: intValue]
                 forKey: key];

  NSDebugMLLog(@"gsdb", @"_propertyList=%@",_propertyList);

  EOFLOGObjectFnStopOrCond(@"EOKeyValueArchiver");
}

/** Archives boolean 'yn' as 'key' **/
- (void) encodeBool: (BOOL)yn
	     forKey: (NSString*)key
{  
  EOFLOGObjectFnStartOrCond(@"EOKeyValueArchiver");

  NSDebugMLLog(@"gsdb", @"key=%@ yn=%s",key,(yn ? "YES" : "NO"));
  NSAssert(key,@"No key");

  [_propertyList setObject: [NSNumber numberWithBool: yn]
                 forKey: key];

  NSDebugMLLog(@"gsdb", @"_propertyList=%@",_propertyList);

  EOFLOGObjectFnStopOrCond(@"EOKeyValueArchiver");
}

/** Archives a dictionary for 'key' **/
- (void) _encodeDictionary: (NSDictionary*)dictionary
		    forKey: (NSString*)key
{
  EOFLOGObjectFnStartOrCond(@"EOKeyValueArchiver");

  NSDebugMLLog(@"gsdb", @"key=%@ dictionary=%@",key,dictionary);
  NSAssert(key,@"No key");

  if ([dictionary count]>0)
    {
      NSEnumerator* keyEnumerator=nil;
      NSString* tmpKey=nil;
      NSMutableDictionary* currentPropertyList=nil;

      // Save current propertyList
      currentPropertyList=AUTORELEASE(_propertyList);
      NSDebugMLLog(@"gsdb", @"currentPropertyList=%@",currentPropertyList);

      // Set new empty propertyList to encode each object
      _propertyList=[NSMutableDictionary new];

      keyEnumerator=[dictionary keyEnumerator];
      while((tmpKey=[keyEnumerator nextObject]))
        {
          id object=[dictionary valueForKey:tmpKey];
          
          [self encodeObject:object
                forKey:tmpKey];          
        };

      // add _propertyList into current propertyList 
      // for the key
      [currentPropertyList setObject:_propertyList
                           forKey:key];

      // put back current propertyList
      ASSIGN(_propertyList,currentPropertyList);      
    }
  else
    {
      [_propertyList setObject:[NSDictionary dictionary]
                     forKey:key];
    };

  EOFLOGObjectFnStopOrCond(@"EOKeyValueArchiver");
}

/** Archives an array objects for 'key' **/
- (void) _encodeObjects: (NSArray*)objects
		 forKey: (NSString*)key
{
  unsigned int count=0;

  EOFLOGObjectFnStartOrCond(@"EOKeyValueArchiver");

  NSDebugMLLog(@"gsdb", @"key=%@ objects=%@",key,objects);
  NSAssert(key,@"No key");

  count=[objects count];
  if (count>0)
    {
      unsigned int i=0;
      NSMutableDictionary* currentPropertyList=nil;
      NSMutableArray* archiveArray=(NSMutableArray*)[NSMutableArray array];

      // Save current propertyList
      currentPropertyList=AUTORELEASE(_propertyList);
      NSDebugMLLog(@"gsdb", @"currentPropertyList=%@",currentPropertyList);

      // Set new empty propertyList to encode each object
      _propertyList=[NSMutableDictionary new];

      for(i=0;i<count;i++)
        {
          id object=[objects objectAtIndex:i];
          id encodedObject=nil;
          
          [self encodeObject:object
                forKey:@"voidKey"];
          
          encodedObject=[_propertyList objectForKey:@"voidKey"];          
          NSDebugMLLog(@"gsdb", @"object=%@ encodedObject=%@",object,encodedObject);
          NSAssert1(encodedObject,@"No encodedObject for %@",object);

          [archiveArray addObject:encodedObject];

          [_propertyList removeObjectForKey:@"voidKey"];
        };

      // add archiveArray into current propertyList 
      // for the key
      [currentPropertyList setObject:archiveArray
                           forKey:key];

      // put back current propertyList
      ASSIGN(_propertyList,currentPropertyList);      
    }
  else
    {
      [_propertyList setObject:[NSArray array]
                     forKey:key];
    };

  EOFLOGObjectFnStopOrCond(@"EOKeyValueArchiver");
}

- (void) _encodeValue: (id)value
	       forKey: (NSString*)key
{
  //Private EO methods. Not currently used
  [self notImplemented: _cmd];	//TODOFN
}


/** Archives the object 'object' reference as 'key'
The receiver gets the reference object by calling 
its delegate method -archiver:referenceToEncodeForObject:
**/
- (void) encodeReferenceToObject: (id)object
			  forKey: (NSString*)key
{
  EOFLOGObjectFnStartOrCond(@"EOKeyValueArchiver");

  NSDebugMLLog(@"gsdb", @"key=%@ object=%@",key,object);
  NSAssert(key,@"No key");

  // object is nil ?
  if (!object)
    {
      //Hum, what to do for nil object ? //TODO
    }
  else
    {
      // First get object reference
      if ([_delegate 
            respondsToSelector:@selector(archiver:referenceToEncodeForObject:)])
      object = [_delegate archiver:self
                          referenceToEncodeForObject:object];
      

      NSDebugMLLog(@"gsdb", @"key=%@ object (reference)=%@",key,object);

      //TODO
      // What should we do when delegate returns no reference ?
      // Here we decide to encode it directly...
     
      [self encodeObject:object
            forKey:key];
    };

  NSDebugMLLog(@"gsdb", @"_propertyList=%@",_propertyList);

  EOFLOGObjectFnStopOrCond(@"EOKeyValueArchiver");
}

/** Archives the object 'object' as 'key'.
'object' should be a NSString, a NSData, NSArray or NSDictionary or conforms to 
EOKeyValueArchiving protocol. Raise an exception otherwise.
**/
- (void) encodeObject: (id)object
	       forKey: (NSString*)key
{
  EOFLOGObjectFnStartOrCond(@"EOKeyValueArchiver");

  NSDebugMLLog(@"gsdb", @"key=%@ object=%@",key,object);
  NSAssert(key,@"No key");

  // object is nil ?
  if (!object)
    {
      //Hum, what to do for nil object ? //TODO
    }
  else if ([object isKindOfClass:GDL2_NSStringClass]
           || [object isKindOfClass:GDL2_NSDataClass]
           || [object isKindOfClass:GDL2_NSNumberClass])
    {
      // Add NSString & NSData directly (or a copy if it is mutable)

      id objectCopy=[object copy];
      [_propertyList setObject:objectCopy
                     forKey:key];
      DESTROY(objectCopy);
    }
  else if ([object isKindOfClass:GDL2_NSDictionaryClass])
    {
      [self _encodeDictionary:object
            forKey:key];
    }
  else if ([object isKindOfClass:GDL2_NSArrayClass])
    {
      [self _encodeObjects:object
            forKey:key];
    }
  else if ([object conformsToProtocol:@protocol(EOKeyValueArchiving)])
    {
      // Object conforms to protocol EOKeyValueArchiving ?
      
      // We will encode it in self empty propertyList and put this 
      // propertyList back and the current propertyList

      // Save current propertyList
      NSMutableDictionary* currentPropertyList=nil;
      currentPropertyList=AUTORELEASE(_propertyList);
      NSDebugMLLog(@"gsdb", @"currentPropertyList=%@",currentPropertyList);

      // Set new empty one as current one
      _propertyList=[NSMutableDictionary new];

      // add object class name to object propertyList
      [_propertyList setObject:NSStringFromClass([object class])
                     forKey:@"class"];

      // Encode object
      [object encodeWithKeyValueArchiver:self];

      NSDebugMLLog(@"gsdb", @"object propertyList=%@",_propertyList);

      // add object propertyList into current propertyList 
      // for the key
      [currentPropertyList setObject:_propertyList
                           forKey:key];

      // put back current propertyList
      ASSIGN(_propertyList,currentPropertyList);      
    }
  else
    {
       [NSException raise:NSInvalidArgumentException
                    format:@"Don't know how to keyValue archive object %@ for key %@",
                    object,key];
                    
    };

  NSDebugMLLog(@"gsdb", @"_propertyList=%@",_propertyList);

  EOFLOGObjectFnStopOrCond(@"EOKeyValueArchiver");
}

/** Returns receiver's delegate **/
- (id) delegate
{
  return _delegate;
}

/** Set receiver's delegate **/
- (void) setDelegate: (id)delegate
{
  EOFLOGObjectFnStartOrCond(@"EOKeyValueArchiver");

  _delegate=delegate;

  EOFLOGObjectFnStopOrCond(@"EOKeyValueArchiver");
}

@end


@implementation NSObject (EOKeyValueArchiverDelegation)

/** Returns an object to be used as reference for 'archiver' 
to archive 'object'.
Should be overriden by EOKeyValueArchiver's delegates 
**/
- (id)archiver: (EOKeyValueArchiver *)archiver 
referenceToEncodeForObject: (id)object
{
  [self subclassResponsibility:_cmd];
  return nil;
}

@end


@implementation EOKeyValueUnarchiver

/** Inits unarchiver with propertyList 'dictionary' **/
- (id) initWithDictionary: (NSDictionary*)dictionary
{
  if ((self = [super init]))
    {
      ASSIGN(_propertyList, dictionary);
      _allUnarchivedObjects = [NSMutableArray array];

      RETAIN(_allUnarchivedObjects);
    }

  return self;
}

/** Finalize unarchiving by calling finishInitializationWithKeyValueUnarchiver:
on all unarchived objects **/
- (void) finishInitializationOfObjects
{
  int i;
  int count = [_allUnarchivedObjects count];

  for (i = 0; i < count; i++)
    {
      EOKeyValueArchivingContainer *container;
      id object;

      container = [_allUnarchivedObjects objectAtIndex: i];
      object = [container object];

      NSDebugMLLog(@"gsdb", @"finishInitializationWithKeyValueUnarchiver index:%d", i);

      [object finishInitializationWithKeyValueUnarchiver: self];
    }
}

- (void) dealloc
{
  DESTROY(_propertyList);
  DESTROY(_allUnarchivedObjects);

  if (_awakenedObjects)
    NSFreeHashTable(_awakenedObjects);

  [super dealloc];
}

/** Finalize unarchiving by calling awakeFromKeyValueUnarchiver: 
on all unarchived objects **/
- (void) awakeObjects
{
  int i;
  int count = [_allUnarchivedObjects count];

  if (!_awakenedObjects)
    _awakenedObjects = NSCreateHashTable(NSNonRetainedObjectHashCallBacks,
					 count);

  for (i = 0; i < count; i++)
    {
      EOKeyValueArchivingContainer *container;
      id object;

      NSDebugMLLog(@"gsdb", @"awakeObject index:%d", i);

      container = [_allUnarchivedObjects objectAtIndex: i];
      object = [container object];

      [self ensureObjectAwake:object];
    }
}

/** ensure 'object' is awake 
(has received -awakeFromKeyValueUnarchiver: message) **/
- (void) ensureObjectAwake: (id)object
{
  if (object)
    {
      if (!NSHashInsertIfAbsent(_awakenedObjects, object))
        {
          NSDebugMLLog(@"gsdb", @"ensureObjectAwake:%@", object);

          [object awakeFromKeyValueUnarchiver: self];
        }
    }
}

/** Returns unarchived integer which was archived as 'key'.
0 if no object is found **/
- (int) decodeIntForKey: (NSString*)key
{
  id object = nil;

  NSDebugMLLog(@"gsdb", @"decodeIntForKey:%@", key);

  object = [_propertyList objectForKey: key];

  return (object ? [object intValue] : 0);
}

/** Returns unarchived boolean which was archived as 'key'.
NO if no object is found **/
- (BOOL) decodeBoolForKey: (NSString*)key
{
  id object=nil;

  NSDebugMLLog(@"gsdb", @"decodeBoolForKey:%@", key);

  object = [_propertyList objectForKey: key];

  return (object ? [[_propertyList objectForKey: key] boolValue] : NO);
}

/** Returns unarchived object for the reference archived as 'key'. 
The receiver gets the object for reference by calling 
its delegate method -unarchiver:objectForReference: **/
- (id) decodeObjectReferenceForKey: (NSString*)key
{
  id objectReference = nil;
  id object;

  NSDebugMLLog(@"gsdb", @"decodeObjectReferenceForKey:%@", key);

  object = [self decodeObjectForKey: key];

  if (object)
    {
      objectReference = [_delegate unarchiver: self
				   objectForReference: object];
    }

  return objectReference;
}

/** Returns unarchived object for key. 
The object should be a NSString, NSData, NSArray or NSDictionary or its 
class instances should implements -initWithKeyValueUnarchiver: **/
- (id) decodeObjectForKey: (NSString*)key
{
  id propListObject;
  id obj = nil;

  NSDebugMLLog(@"gsdb", @"decodeObjectForKey:%@", key);

  propListObject = [_propertyList objectForKey: key];
  NSDebugMLLog(@"gsdb", @"key: %@ propListObject:%@", key, propListObject);

  if (propListObject)
    {
      obj = [self _findTypeForPropertyListDecoding: propListObject];
    }

  NSDebugMLLog(@"gsdb", @"key: %@ obj:%@", key, obj);

  return obj;
}

/** Returns YES if there's a value for key 'key' **/
- (BOOL) isThereValueForKey: (NSString *)key
{
  return ([_propertyList objectForKey: key] != nil);
}

- (id) _findTypeForPropertyListDecoding: (id)obj
{
  id retVal = nil;

  NSDebugMLLog(@"gsdb", @"obj:%@", obj);

  if ([obj isKindOfClass: GDL2_NSDictionaryClass])
    {
      NSString *className = [obj objectForKey: @"class"];

      if (className)
        retVal = [self _objectForPropertyList: obj];
      else
        retVal = [self _dictionaryForPropertyList: obj];

      if (!retVal)
        {
          //TODO
          NSDebugMLLog(@"gsdb", @"ERROR: No retVal for Obj:%@", obj);
        }
    }
  else if ([obj isKindOfClass: GDL2_NSArrayClass])
    retVal = [self _objectsForPropertyList: obj];
  else
    retVal=obj;

  NSDebugMLLog(@"gsdb", @"retVal:%@", retVal);

  return retVal;
}

- (id) _dictionaryForPropertyList: (NSDictionary*)propList
{
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  NSEnumerator *enumerator = [propList keyEnumerator];
  id key;

  while ((key = [enumerator nextObject]))
    {
      id object;
      id retObject;

      NSDebugMLLog(@"gsdb", @"key:%@", key);

      object = [propList objectForKey: key];
      NSDebugMLLog(@"gsdb", @"Object:%@", object);

      retObject = [self _findTypeForPropertyListDecoding: object];
      NSDebugMLLog(@"gsdb", @"retObject:%@", retObject);

      if (!retObject)
        {
          NSDebugMLLog(@"gsdb", @"ERROR: No retObject for Object:%@", object);
          //TODO
        }
      else
        [dict setObject: retObject
              forKey: key];
    }

  return dict;
}

- (id) _objectsForPropertyList: (NSArray*)propList
{
  NSMutableArray *newObjects = [NSMutableArray array];
  id              object = nil;
  NSEnumerator	 *propListEnum;
  id		  propListObject;

  EOFLOGObjectFnStartOrCond(@"EOKeyValueUnarchiver");

  if (propList && (propListEnum = [propList objectEnumerator]))
    {
      while ((propListObject = [propListEnum nextObject]))
	{
	  object = [self _findTypeForPropertyListDecoding: propListObject];

	  if (object)
	    {
	      [newObjects addObject: object];
	    }
	}
    }

  EOFLOGObjectFnStopOrCond(@"EOKeyValueUnarchiver");

  return newObjects;
}

- (id) _objectForPropertyList: (NSDictionary*)propList
{
  EOKeyValueArchivingContainer *container = nil;
  NSString *className = nil;
  Class objectClass = Nil;
  id object = nil;
  NSDictionary *oldPropList = AUTORELEASE(_propertyList);

  _propertyList = RETAIN(propList); //Because dealloc may try to release it

  NSDebugMLLog(@"gsdb", @"propList:%@", propList);

  NS_DURING
    {
      className = [propList objectForKey: @"class"];
      objectClass = NSClassFromString(className);  

      NSAssert1(objectClass, @"ERROR: No class named '%@'", className);

      object = [[[objectClass alloc] initWithKeyValueUnarchiver: self]
		 autorelease];
      container = [EOKeyValueArchivingContainer keyValueArchivingContainer];

      [container setObject: object];
      [container setParent: nil]; //TODO VERIFY
      [container setPropertyList: propList];

      [_allUnarchivedObjects addObject: container];
    }
  NS_HANDLER
    {
      NSDebugMLLog(@"gsdb", @"EOKeyValueUnarchiver",@"EXCEPTION:%@ (%@) [%s %d]",
                   localException,
                   [localException reason],
                   __FILE__,
                   __LINE__);

      //Restaure the original propertyList
      _propertyList = RETAIN(oldPropList);

      AUTORELEASE(propList);
      [localException raise];
    }
  NS_ENDHANDLER;

  _propertyList = RETAIN(oldPropList);

  AUTORELEASE(propList);

  NSDebugMLLog(@"gsdb", @"propList:%@", propList);
  NSDebugMLLog(@"gsdb", @"object:%@", object);

  return object;
}

/** Returns the parent object for the currently unarchiving object. 
**/
- (id) parent
{
  return _parent;
}

/** Returns receiver's delegate **/
- (id) delegate
{
  return _delegate;
}

/** Set the receiver's delegate **/
- (void) setDelegate:(id)delegate
{
  _delegate=delegate;
}

@end


@implementation NSObject (EOKeyValueUnarchiverDelegation)

/** 
 * Returns an object for archived 'reference'.
 * Implemented by EOKeyValueUnarchiver's delegate.
 */
- (id)unarchiver: (EOKeyValueUnarchiver*)archiver 
objectForReference: (id)keyPath
{
  [self subclassResponsibility:_cmd];
  return nil;
}

@end


@implementation NSObject(EOKeyValueArchivingAwakeMethods) 
                    
- (void)finishInitializationWithKeyValueUnarchiver: (EOKeyValueUnarchiver *)unarchiver
{
  //Does nothing ?
  return;
}

- (void)awakeFromKeyValueUnarchiver: (EOKeyValueUnarchiver *)unarchiver
{
  //Does nothing ?
  return;
}

@end 
