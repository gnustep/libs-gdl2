/** 
   EOKeyValueArchiver.m <title>EOKeyValueArchiver Class</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: September 2000

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

#ifndef NeXT_Foundation_LIBRARY
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <gnustep/base/GNUstep.h>
#endif

#include <EOControl/EOKeyValueArchiver.h>
#include <EOControl/EODebug.h>


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
- (void) dealloc;

@end


@implementation EOKeyValueArchivingContainer

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

- (id) init
{
  [self notImplemented: _cmd];	//TODOFN
  return nil;
}

- (void) dealloc
{
  DESTROY(_propertyList);
  [super dealloc];
}

- (id) dictionary
{
  return _propertyList;
}

- (void) encodeInt: (int)intValue
	    forKey: (NSString*)key
{
  [self notImplemented: _cmd];	//TODOFN
}

- (void) encodeBool: (BOOL)yn
	     forKey: (NSString*)key
{
  [self notImplemented: _cmd];	//TODOFN
}

- (void) encodeReferenceToObject: (id)object
			  forKey: (NSString*)key
{
  [self notImplemented: _cmd];	//TODOFN
}

- (void) encodeObject: (id)object
	       forKey: (NSString*)key
{
  [self notImplemented: _cmd];	//TODOFN
}

- (void) _encodeDictionary: (id)dictionary
		    forKey: (NSString*)key
{
  [self notImplemented: _cmd];	//TODOFN
}

- (void) _encodeObjects: (id)objects
		 forKey: (NSString*)key
{
  [self notImplemented: _cmd];	//TODOFN
}

- (void) _encodeValue: (id)value
	       forKey: (NSString*)key
{
  [self notImplemented: _cmd];	//TODOFN
}

- (id) delegate
{
  return _delegate;
}

- (void) setDelegate: (id)delegate
{
  _delegate=delegate;
}

@end


@implementation NSObject (EOKeyValueArchiverDelegation)

- (id)archiver: (EOKeyValueArchiver *)archiver 
referenceToEncodeForObject: (id)object
{
  [self notImplemented: _cmd];	//TODOFN
  return nil;
}

@end


@implementation EOKeyValueUnarchiver

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

- (int) decodeIntForKey: (NSString*)key
{
  id object;

  NSDebugMLLog(@"gsdb", @"decodeIntForKey:%@", key);

  object = [_propertyList objectForKey: key];

  return [object intValue];
}

- (BOOL) decodeBoolForKey: (NSString*)key
{
  id object;

  NSDebugMLLog(@"gsdb", @"decodeBoolForKey:%@", key);

  object = [_propertyList objectForKey: key];

  return [[_propertyList objectForKey: key] boolValue];
}

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

- (BOOL) isThereValueForKey: (NSString *)key
{
  return ([_propertyList objectForKey: key] != nil);
}

- (id) _findTypeForPropertyListDecoding: (id)obj
{
  id retVal = nil;

  NSDebugMLLog(@"gsdb", @"obj:%@", obj);

  if ([obj isKindOfClass: [NSDictionary class]])
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
  else if ([obj isKindOfClass: [NSArray class]])
    retVal = [self _objectsForPropertyList: obj];
  else
    retVal=obj;

  NSDebugMLLog(@"gsdb", @"retVal:%@", retVal);

  return retVal;
  /*
    {
    batchSize = {AutoInitialized = 1; TypeName = Object; }; 
    checkOutLength = {AutoInitialized = 1; TypeName = Object; }; 
    cost = {AutoInitialized = 1; TypeName = Object; }; 
    currentItem = {TypeName = Object; }; 
    dateAcquired = {AutoInitialized = 1; TypeName = Object; }; 
    discInsert = {TypeName = Object; }; 
    errorString = {AutoInitialized = 1; TypeName = Object; }; 
    media = {AutoInitialized = 1; TypeName = Object; }; 
    movieMedia = {TypeName = MovieMedia; }; 
    movieMediaDataSource = {TypeName = Object; }; 
    moviemedias = {
    AutoInitialized = 1; 
    TypeName = MovieMedias; 
    initialValue = {
    class = WODisplayGroup; 
    dataSource = {
    class = EODatabaseDataSource; 
    editingContext = session.defaultEditingContext; 
    fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
    }; 
    formatForLikeQualifier = "%@*"; 
    numberOfObjectsPerBatch = 10; 
    selectsFirstObjectAfterFetch = YES; 
    }; 
    }; 
    objectArray = {TypeName = Object; }; 
    ordering = {AutoInitialized = 1; TypeName = Object; }; 
    orderingsArray = {AutoInitialized = 1; TypeName = Object; }; 
    rentalType = {AutoInitialized = 1; TypeName = Object; }; 
    selectedOrderings = {AutoInitialized = 1; TypeName = Object; }; 
    tapeInsert = {TypeName = Object; }; 
    yes = {TypeName = Object; }; 
    }
    [self _dictionaryForPropertyList:param0];

    //2
    {TypeName = Object; }
    _dictionaryForPropertyList:{TypeName = Object; }



    //4
    Object 
    return Object

    //5 [2]
    return {TypeName = Object; }




    // A1
    Description: {
    AutoInitialized = 1; 
    TypeName = MovieMedias; 
    initialValue = {
    class = WODisplayGroup; 
    dataSource = {
    class = EODatabaseDataSource; 
    editingContext = session.defaultEditingContext; 
    fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
    }; 
    formatForLikeQualifier = "%@*"; 
    numberOfObjectsPerBatch = 10; 
    selectsFirstObjectAfterFetch = YES; 
    }; 
    }
    _dictionaryForPropertyList:

    //A 4
    _objectForPropertyList:
    Description: {
    class = WODisplayGroup; 
    dataSource = {
    class = EODatabaseDataSource; 
    editingContext = session.defaultEditingContext; 
    fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
    }; 
    formatForLikeQualifier = "%@*"; 
    numberOfObjectsPerBatch = 10; 
    selectsFirstObjectAfterFetch = YES; 
    }



    //B1
    Description: {
    class = EODatabaseDataSource; 
    editingContext = session.defaultEditingContext; 
    fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
    }

    _objectForPropertyList:object
    Description: {
    class = EODatabaseDataSource; 
    editingContext = session.defaultEditingContext; 
    fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
    }


    return _objectForPropertyList:obj;  EOFetchSpecification


    _objectForPropertyList:{
    class = WODisplayGroup; 
    dataSource = {
    class = EODatabaseDataSource; 
    editingContext = session.defaultEditingContext; 
    fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
    }; 
    formatForLikeQualifier = "%@*"; 
    numberOfObjectsPerBatch = 10; 
    selectsFirstObjectAfterFetch = YES; 
    }
  */
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

/*
{
    batchSize = {AutoInitialized = 1; TypeName = Object; }; 
    checkOutLength = {AutoInitialized = 1; TypeName = Object; }; 
    cost = {AutoInitialized = 1; TypeName = Object; }; 
    currentItem = {TypeName = Object; }; 
    dateAcquired = {AutoInitialized = 1; TypeName = Object; }; 
    discInsert = {TypeName = Object; }; 
    errorString = {AutoInitialized = 1; TypeName = Object; }; 
    media = {AutoInitialized = 1; TypeName = Object; }; 
    movieMedia = {TypeName = MovieMedia; }; 
    movieMediaDataSource = {TypeName = Object; }; 
    moviemedias = {
        AutoInitialized = 1; 
        TypeName = MovieMedias; 
        initialValue = {
            class = WODisplayGroup; 
            dataSource = {
                class = EODatabaseDataSource; 
                editingContext = session.defaultEditingContext; 
                fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
            }; 
            formatForLikeQualifier = "%@*"; 
            numberOfObjectsPerBatch = 10; 
            selectsFirstObjectAfterFetch = YES; 
        }; 
    }; 
    objectArray = {TypeName = Object; }; 
    ordering = {AutoInitialized = 1; TypeName = Object; }; 
    orderingsArray = {AutoInitialized = 1; TypeName = Object; }; 
    rentalType = {AutoInitialized = 1; TypeName = Object; }; 
    selectedOrderings = {AutoInitialized = 1; TypeName = Object; }; 
    tapeInsert = {TypeName = Object; }; 
    yes = {TypeName = Object; }; 
}

 _findTypeForPropertyListDecoding:{TypeName = Object; }


//3
{TypeName = Object; }
_findTypeForPropertyListDecoding:Object 
(return Object)
return {TypeName = Object; } <==

//6 [1]
{TypeName = Object; }  

_findTypeForPropertyListDecoding:{TypeName = MovieMedia; }



//A2
 object=
                                              Description: {
    AutoInitialized = 1; 
    TypeName = MovieMedias; 
    initialValue = {
        class = WODisplayGroup; 
        dataSource = {
            class = EODatabaseDataSource; 
            editingContext = session.defaultEditingContext; 
            fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
        }; 
        formatForLikeQualifier = "%@*"; 
        numberOfObjectsPerBatch = 10; 
        selectsFirstObjectAfterFetch = YES; 
    }; 
}

_findTypeForPropertyListDecoding:object=
                                                Description: 1
_findTypeForPropertyListDecoding
                                                Description: MovieMedias
_findTypeForPropertyListDecoding:object=
                                                Description: {
    class = WODisplayGroup; 
    dataSource = {
        class = EODatabaseDataSource; 
        editingContext = session.defaultEditingContext; 
        fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
    }; 
    formatForLikeQualifier = "%@*"; 
    numberOfObjectsPerBatch = 10; 
    selectsFirstObjectAfterFetch = YES; 
}
*/

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
/*
  //EOFetchSpecification

  prop{
  class = WODisplayGroup; 
  dataSource = {
  class = EODatabaseDataSource; 
  editingContext = session.defaultEditingContext; 
  fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
  }; 
  formatForLikeQualifier = "%@*"; 
  numberOfObjectsPerBatch = 10; 
  selectsFirstObjectAfterFetch = YES; 
  }]




  object=
  Description: {
  class = WODisplayGroup; 
  dataSource = {
  class = EODatabaseDataSource; 
  editingContext = session.defaultEditingContext; 
  fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
  }; 
  formatForLikeQualifier = "%@*"; 
  numberOfObjectsPerBatch = 10; 
  selectsFirstObjectAfterFetch = YES; 
  }


*/

- (id) parent
{
  return _parent;
}

- (id) delegate
{
  return _delegate;
}

- (void) setDelegate:(id)delegate
{
  _delegate=delegate;
}

@end


@implementation NSObject (EOKeyValueUnarchiverDelegation)

- (id)unarchiver: (EOKeyValueUnarchiver*)archiver 
objectForReference: (id)keyPath
{
  [self notImplemented: _cmd];	//TODOFN
  return nil;
}

@end


@implementation NSObject(EOKeyValueArchivingAwakeMethods) 
                    
- (void)finishInitializationWithKeyValueUnarchiver: (EOKeyValueUnarchiver *)unarchiver
{
  //Does nothing ?
}

- (void)awakeFromKeyValueUnarchiver: (EOKeyValueUnarchiver *)unarchiver;
{
  //Does nothing ?
}

@end 
