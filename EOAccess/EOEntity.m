/**
   EOEntity.m <title>EOEntity Class</title>

   Copyright (C) 2000, 2002, 2003 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: February 2000

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: October 2000

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

#include <ctype.h>

#ifdef GNUSTEP
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSFormatter.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSZone.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EONull.h>
#include <EOControl/EOMutableKnownKeyDictionary.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EOCheapArray.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOModel.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOStoredProcedure.h>
#include <EOAccess/EOExpressionArray.h>

#include "EOPrivate.h"
#include "EOEntityPriv.h"
#include "EOAttributePriv.h"

@interface EOModel (Privat)
- (void)_updateCache;
@end

NSString *EOFetchAllProcedureOperation = @"EOFetchAllProcedureOperation";
NSString *EOFetchWithPrimaryKeyProcedureOperation = @"EOFetchWithPrimaryKeyProcedureOperation";
NSString *EOInsertProcedureOperation = @"EOInsertProcedureOperation";
NSString *EODeleteProcedureOperation = @"EODeleteProcedureOperation";
NSString *EONextPrimaryKeyProcedureOperation = @"EONextPrimaryKeyProcedureOperation";


@implementation EOEntity

+ (void)initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized=YES;

      GDL2_EOAccessPrivateInit();
    };
};

/* Not documented becuase it is not a public method.  */
- (id) initWithPropertyList: (NSDictionary*)propertyList
		      owner: (id)owner
{
  [EOObserverCenter suppressObserverNotification];

  EOFLOGObjectLevelArgs(@"EOEntity", @"propertyList=%@", propertyList);

  NS_DURING
    {
      if ((self = [self init]) != nil)
        {
          NSArray	*array = nil;
          NSString	*tmpString = nil;
          id		tmpObject = nil;

          _flags.updating = YES;
          ASSIGN(_name, [propertyList objectForKey: @"name"]);

          [self setExternalName: [propertyList objectForKey: @"externalName"]];
          [self setExternalQuery:
	    [propertyList objectForKey: @"externalQuery"]];

          tmpString = [propertyList objectForKey: @"restrictingQualifier"];

          EOFLOGObjectLevelArgs(@"EOEntity",@"tmpString=%@",tmpString);

          if (tmpString)
            {
              EOQualifier *restrictingQualifier =
		[EOQualifier qualifierWithQualifierFormat: @"%@", tmpString];

              [self setRestrictingQualifier: restrictingQualifier];
            }

          tmpString = [propertyList objectForKey: @"mappingQualifier"];

          if (tmpString)
            {
              NSEmitTODO();  //TODO
            }

          [self setReadOnly: [[propertyList objectForKey: @"isReadOnly"]
			       boolValue]];
          [self setCachesObjects: [[propertyList objectForKey:
						   @"cachesObjects"]
				    boolValue]];
          tmpObject = [propertyList objectForKey: @"userInfo"];

          EOFLOGObjectLevelArgs(@"EOEntity", @"tmpObject=%@", tmpObject);
          /*NSAssert2((!tmpString
		|| [tmpString isKindOfClass:[NSString class]]),
                    @"tmpString is not a NSString but a %@. tmpString:\n%@",
                    [tmpString class],
                    tmpString);
          */

          if (tmpObject)
            //[self setUserInfo:[tmpString propertyList]];
            [self setUserInfo: tmpObject];
          else
            {
              tmpObject = [propertyList objectForKey: @"userDictionary"];
              /*NSAssert2((!tmpString
		|| [tmpString isKindOfClass:[NSString class]]),
                        @"tmpString is not a NSString but a %@ tmpString:\n%@",
                        [tmpString class],
                        tmpString);*/
              [self setUserInfo: tmpObject];
            }

          tmpObject = [propertyList objectForKey: @"internalInfo"];

          EOFLOGObjectLevelArgs(@"EOEntity", @"tmpObject=%@ [%@]",
				tmpObject, [tmpObject class]);

          [self _setInternalInfo: tmpObject];
          [self setDocComment:[propertyList objectForKey:@"docComment"]];
          [self setClassName: [propertyList objectForKey: @"className"]];
          [self setIsAbstractEntity:
		  [[propertyList objectForKey: @"isAbstractEntity"] boolValue]];
      
          tmpString = [propertyList objectForKey: @"isFetchable"];

          if (tmpString)
            {
              NSEmitTODO();  //TODO
            }
          
          array = [propertyList objectForKey: @"attributes"];

          EOFLOGObjectLevelArgs(@"EOEntity", @"Attributes: %@", array);

          if ([array count] > 0)
            {
              ASSIGN(_attributes, array);
              _flags.attributesIsLazy = YES;
            }

          array = [propertyList objectForKey: @"attributesUsedForLocking"];
          EOFLOGObjectLevelArgs(@"EOEntity", @"attributesUsedForLocking: %@",
				array);
          if ([array count] > 0)
            {          
              ASSIGN(_attributesUsedForLocking, array);
              _flags.attributesUsedForLockingIsLazy = YES;
            }

          array = [[propertyList objectForKey: @"primaryKeyAttributes"] 
                    sortedArrayUsingSelector: @selector(compare:)];

          EOFLOGObjectLevelArgs(@"EOEntity", @"primaryKeyAttributes: %@",
				array);

          if ([array count] > 0)
            {
              ASSIGN(_primaryKeyAttributes, array);
              _flags.primaryKeyAttributesIsLazy = YES;
            }

          /*
	   * Assign them to _classProperties, not _classPropertyNames,
	   * this will be build after
	   */
          array = [propertyList objectForKey: @"classProperties"];

          EOFLOGObjectLevelArgs(@"EOEntity", @"classProperties: %@", array);

          if ([array count] > 0)
            {
              ASSIGN(_classProperties, array);
              _flags.classPropertiesIsLazy = YES;
            }

          array = [propertyList objectForKey: @"relationships"];

          EOFLOGObjectLevelArgs(@"EOEntity", @"relationships: %@", array);

          if ([array count] > 0)
            {
              ASSIGN(_relationships, array);
              _flags.relationshipsIsLazy = YES;
            }

          array = [propertyList objectForKey: @"storedProcedureNames"];

          EOFLOGObjectLevelArgs(@"EOEntity",@"relationships: %@",array);
          if ([array count] > 0)
            {
              NSEmitTODO(); //TODO
            }

          tmpString = [propertyList objectForKey:
				      @"maxNumberOfInstancesToBatchFetch"];

          EOFLOGObjectLevelArgs(@"EOEntity",
	    @"maxNumberOfInstancesToBatchFetch=%@ [%@]",
	    tmpString, [tmpString class]);

          if (tmpString)
              [self setMaxNumberOfInstancesToBatchFetch: [tmpString intValue]];

          tmpString=[propertyList objectForKey:@"batchFaultingMaxSize"];
          if (tmpString)
            {
              NSEmitTODO();  //TODO
	      //[self setBatchFaultingMaxSize: [tmpString intValue]];
	    }

          tmpObject = [propertyList objectForKey:
				      @"fetchSpecificationDictionary"];

          EOFLOGObjectLevelArgs(@"EOEntity",
	    @"fetchSpecificationDictionary=%@ [%@]",
	    tmpObject, [tmpObject class]);

          if (tmpObject)
            {
	      tmpObject = AUTORELEASE([tmpObject mutableCopy]);
              ASSIGN(_fetchSpecificationDictionary, tmpObject);
            }
          else
            {
              _fetchSpecificationDictionary = [NSMutableDictionary new];

              EOFLOGObjectLevelArgs(@"EOEntity",
		@"Entity %@ - _fetchSpecificationDictionary %p [RC=%d]:%@",
		[self name],
		_fetchSpecificationDictionary,
		[_fetchSpecificationDictionary retainCount],
		_fetchSpecificationDictionary);
            }

          // load entity's FetchSpecifications
          {
            NSDictionary *plist = nil;
            NSString* fileName;
            NSString* path;

            fileName = [NSString stringWithFormat: @"%@.fspec", _name];
            path = [[(EOModel *)owner path] stringByAppendingPathComponent: fileName];
	    if ([[NSFileManager defaultManager] fileExistsAtPath: path])
		plist 
		  = [[NSString stringWithContentsOfFile: path] propertyList];
	    
            if (plist) 
              {
                EOKeyValueUnarchiver *unarchiver;
                NSDictionary *variables;
                NSEnumerator *variablesEnum;
                id fetchSpecName;

                unarchiver = AUTORELEASE([[EOKeyValueUnarchiver alloc]
			       initWithDictionary:
			       [NSDictionary dictionaryWithObject: plist
					     forKey: @"fspecs"]]);

                variables = [unarchiver decodeObjectForKey: @"fspecs"];
                //NSLog(@"fspecs variables:%@",variables);
                
                [unarchiver finishInitializationOfObjects];
                [unarchiver awakeObjects];

		variablesEnum = [variables keyEnumerator];
		while ((fetchSpecName = [variablesEnum nextObject]))
		  {
		    id fetchSpec = [variables objectForKey: fetchSpecName];

		    //NSLog(@"fetchSpecName:%@ fetchSpec:%@", fetchSpecName, fetchSpec);

		    [self addFetchSpecification: fetchSpec
			  withName: fetchSpecName];
		  }
	      }
          }

          [self setCreateMutableObjects: NO]; //?? TC say no, mirko yes
          _flags.updating = NO;
        }  
    }
  NS_HANDLER
    {
      [EOObserverCenter enableObserverNotification];

      NSLog(@"exception in EOEntity initWithPropertyList:owner:");
      NSLog(@"exception=%@", localException);

/*      localException=ExceptionByAddingUserInfoObjectFrameInfo(localException,
                                                              @"In EOEntity initWithPropertyList:owner:");*/

      NSLog(@"exception=%@", localException);
      [localException raise];
    }
  NS_ENDHANDLER;

  [EOObserverCenter enableObserverNotification];

  return self;
}

- (void)awakeWithPropertyList: (NSDictionary *)propertyList
{
  //do nothing?
}

- (void)encodeIntoPropertyList: (NSMutableDictionary *)propertyList
{
  int i, count;

  if (_name)
    [propertyList setObject: _name
                  forKey: @"name"];
  if (_className)
    [propertyList setObject: _className
                  forKey: @"className"];
  if (_externalName)
    [propertyList setObject: _externalName
                  forKey: @"externalName"];
  if (_externalQuery)
    [propertyList setObject: _externalQuery
                  forKey: @"externalQuery"];
  if (_userInfo)
    [propertyList setObject: _userInfo
                  forKey: @"userInfo"];
  if (_docComment)
    [propertyList setObject: _docComment
                  forKey: @"docComment"];
  if (_batchCount)
    [propertyList setObject: [NSNumber numberWithInt: _batchCount]
                  forKey: @"maxNumberOfInstancesToBatchFetch"];

  if (_flags.cachesObjects)
    [propertyList setObject: [NSNumber numberWithBool: _flags.cachesObjects]
                  forKey: @"cachesObjects"];

  if ((count = [_attributes count]))
    {
      if (_flags.attributesIsLazy)
        [propertyList setObject: _attributes
                      forKey: @"attributes"];
      else
        {
          NSMutableArray *attributesPList = [NSMutableArray array];

          for (i = 0; i < count; i++)
            {
              NSMutableDictionary *attributePList = [NSMutableDictionary
						      dictionary];
              
              [[_attributes objectAtIndex: i]
                encodeIntoPropertyList: attributePList];
              [attributesPList addObject: attributePList];
            }

          [propertyList setObject: attributesPList
                        forKey: @"attributes"];
        }
    }
  
  if ((count = [_attributesUsedForLocking count]))
    {
      if (_flags.attributesUsedForLockingIsLazy)
        [propertyList setObject: _attributesUsedForLocking
                      forKey: @"attributesUsedForLocking"];
      else
        {
          NSMutableArray *attributesUsedForLockingPList = [NSMutableArray
							    array];

          for (i = 0; i < count; i++)
            {
              NSString *attributePList
                = [(EOAttribute *)[_attributesUsedForLocking objectAtIndex: i]
                                  name];

              [attributesUsedForLockingPList addObject: attributePList];
            }
          
          [propertyList setObject: attributesUsedForLockingPList
                        forKey: @"attributesUsedForLocking"];
        }
    }

  if ((count = [_classProperties count]))
    {
      if (_flags.classPropertiesIsLazy)
        [propertyList setObject: _classProperties
                      forKey: @"classProperties"];
      else
        {
          NSMutableArray *classPropertiesPList = [NSMutableArray array];
          
          for (i = 0; i < count; i++)
            {
              NSString *classPropertyPList
                = [(EOAttribute *)[_classProperties objectAtIndex: i]
                                  name];
              [classPropertiesPList addObject: classPropertyPList];
            }
          
          [propertyList setObject: classPropertiesPList
                        forKey: @"classProperties"];
        }
    }

  if ((count = [_primaryKeyAttributes count]))
    {
      if (_flags.primaryKeyAttributesIsLazy)
        [propertyList setObject: _primaryKeyAttributes
                      forKey: @"primaryKeyAttributes"];
      else
        {
          NSMutableArray *primaryKeyAttributesPList = [NSMutableArray array];

          for (i = 0; i < count; i++)
            {
              NSString *attributePList= [(EOAttribute *)[_primaryKeyAttributes
							  objectAtIndex: i]
                                                        name];

              [primaryKeyAttributesPList addObject: attributePList];
            }

          [propertyList setObject: primaryKeyAttributesPList
                        forKey: @"primaryKeyAttributes"];
        }
    }

  {
    NSArray *relsPlist = [self relationshipsPlist];

    if (relsPlist)
      {
        [propertyList setObject: relsPlist
                        forKey: @"relationships"];
      }
  }
}

- (id) init
{
  //OK
  if ((self = [super init]))
    {
      _attributes = [GCMutableArray new];
      [self setCreateMutableObjects: YES];
    }

  return self;
}

- (void) dealloc
{
  DESTROY(_name);
  DESTROY(_className);
  DESTROY(_externalName);
  DESTROY(_externalQuery);
  DESTROY(_userInfo);
  DESTROY(_docComment);
  DESTROY(_fetchSpecificationDictionary);
  DESTROY(_primaryKeyAttributeNames);
  DESTROY(_classPropertyNames);
  DESTROY(_classDescription);
  DESTROY(_adaptorDictionaryInitializer);
  DESTROY(_snapshotDictionaryInitializer);
  DESTROY(_primaryKeyDictionaryInitializer);
  DESTROY(_propertyDictionaryInitializer);
  DESTROY(_instanceDictionaryInitializer);
  DESTROY(_snapshotToAdaptorRowSubsetMapping);
  DESTROY(_classForInstances);

  [super dealloc];
}

- (void) gcDecrementRefCountOfContainedObjects
{
  int where = 0;
  NSProcessInfo *_processInfo = [NSProcessInfo processInfo];
  NSMutableSet *_debugSet = [_processInfo debugSet];

  [_debugSet addObject: @"gsdb"];

  EOFLOGObjectFnStart();
  EOFLOGObjectFnStart();

  NS_DURING
    {
      where = 1;
      EOFLOGObjectLevel(@"EOEntity", @"attributes gcDecrementRefCount");
      if (!_flags.attributesIsLazy)
        [(id)_attributes gcDecrementRefCount];

      where = 2;
      EOFLOGObjectLevel(@"EOEntity",
			@"propertiesToFault gcDecrementRefCount");
      [(id)_attributesByName gcDecrementRefCount];

      where = 3;
      EOFLOGObjectLevelArgs(@"EOEntity",
			    @"attributesToFetch gcDecrementRefCount class=%@",
			    [_attributesToFetch class]);
      NSAssert3(!_attributesToFetch
		|| [_attributesToFetch isKindOfClass: [NSArray class]],
                @"entity %@ attributesToFetch is not an NSArray but a %@\n%@",
                [self name],
                [_attributesToFetch class],
                _attributesToFetch);

      [(id)_attributesToFetch gcDecrementRefCount];

      NSAssert3(!_attributesToFetch
		|| [_attributesToFetch isKindOfClass: [NSArray class]],
                @"entity %@ attributesToFetch is not an NSArray but a %@\n%@",
                [self name],
                [_attributesToFetch class],
                _attributesToFetch);

      where = 4;
      EOFLOGObjectLevelArgs(@"EOEntity",
			    @"attributesToSave gcDecrementRefCount (class=%@)",
			    [_attributesToSave class]);
      [(id)_attributesToSave gcDecrementRefCount];

      where = 5;
      EOFLOGObjectLevel(@"EOEntity",
			@"propertiesToFault gcDecrementRefCount");
      [(id)_propertiesToFault gcDecrementRefCount];

      where = 6;
      EOFLOGObjectLevel(@"EOEntity",
			@"rrelationships gcDecrementRefCount");
      if (!_flags.relationshipsIsLazy)
        [(id)_relationships gcDecrementRefCount];

      where = 7;
      EOFLOGObjectLevel(@"EOEntity",
			@"relationshipsByName gcDecrementRefCount");
      [(id)_relationshipsByName gcDecrementRefCount];

      where = 8;
      EOFLOGObjectLevel(@"EOEntity",
			@"primaryKeyAttributes gcDecrementRefCount");
      if (!_flags.primaryKeyAttributesIsLazy)
        [(id)_primaryKeyAttributes gcDecrementRefCount];

      where = 9;
      EOFLOGObjectLevel(@"EOEntity",
			@"classProperties gcDecrementRefCount");
      if (!_flags.classPropertiesIsLazy)
        [(id)_classProperties gcDecrementRefCount];

      where = 10;
      EOFLOGObjectLevelArgs(@"EOEntity",
			    @"attributesUsedForLocking (%@) gcDecrementRefCount",
			    [_attributesUsedForLocking class]);
      if (!_flags.attributesUsedForLockingIsLazy)
        [(id)_attributesUsedForLocking gcDecrementRefCount];

      where = 11;
      EOFLOGObjectLevel(@"EOEntity", @"subEntities gcDecrementRefCount");
      [(id)_subEntities gcDecrementRefCount];

      where = 12;
      EOFLOGObjectLevel(@"EOEntity", @"dbSnapshotKeys gcDecrementRefCount");
      [(id)_dbSnapshotKeys gcDecrementRefCount];

      where = 13;
      EOFLOGObjectLevel(@"EOEntity", @"_parent gcDecrementRefCount");
      [_parent gcDecrementRefCount];
    }
  NS_HANDLER
    {
      NSLog(@"====>WHERE=%d %@ (%@)", where, localException,
	    [localException reason]);
      NSDebugMLog(@"attributesToFetch gcDecrementRefCount class=%@",
		  [_attributesToFetch class]);

      [localException raise];
    }
  NS_ENDHANDLER;

  EOFLOGObjectFnStop();

  [_debugSet removeObject: @"gsdb"];
}

- (BOOL) gcIncrementRefCountOfContainedObjects
{
  int where = 0;
  NSProcessInfo *_processInfo = [NSProcessInfo processInfo];
  NSMutableSet *_debugSet = [_processInfo debugSet];

  [_debugSet addObject: @"gsdb"];

  EOFLOGObjectFnStart();
  
  if (![super gcIncrementRefCountOfContainedObjects])
    {
      EOFLOGObjectFnStop();
      [_debugSet removeObject: @"gsdb"];

      return NO;
    }
  NS_DURING
    {
      where = 1;
      EOFLOGObjectLevel(@"EOEntity", @"model gcIncrementRefCount");
      [_model gcIncrementRefCount];

      where = 2;
      EOFLOGObjectLevel(@"EOEntity", @"attributes gcIncrementRefCount");
      if (!_flags.attributesIsLazy)
        [(id)_attributes gcIncrementRefCount];

      where = 3;
      EOFLOGObjectLevel(@"EOEntity",
			@"attributesByName gcIncrementRefCount");
      [(id)_attributesByName gcIncrementRefCount];

      where = 4;
      EOFLOGObjectLevel(@"EOEntity",
			@"attributesToFetch gcIncrementRefCount");
      NSAssert3(!_attributesToFetch
		|| [_attributesToFetch isKindOfClass: [NSArray class]],
                @"entity %@ attributesToFetch is not an NSArray but a %@\n%@",
                [self name],
                [_attributesToFetch class],
                _attributesToFetch);

      [(id)_attributesToFetch gcIncrementRefCount];

      NSAssert3(!_attributesToFetch
		|| [_attributesToFetch isKindOfClass: [NSArray class]],
                @"entity %@ attributesToFetch is not an NSArray but a %@\n%@",
                [self name],
                [_attributesToFetch class],
                _attributesToFetch);

      where = 5;
      EOFLOGObjectLevel(@"EOEntity",
			@"attributesToSave gcIncrementRefCount");
      [(id)_attributesToSave gcIncrementRefCount];

      where = 6;
      EOFLOGObjectLevel(@"EOEntity",
			@"propertiesToFault gcIncrementRefCount");
      [(id)_propertiesToFault gcIncrementRefCount];

      where = 7;
      EOFLOGObjectLevel(@"EOEntity", @"relationships gcIncrementRefCount");
      if (!_flags.relationshipsIsLazy)
        [(id)_relationships gcIncrementRefCount];

      where = 8;
      EOFLOGObjectLevel(@"EOEntity",
			@"relationshipsByName gcIncrementRefCount");
      [(id)_relationshipsByName gcIncrementRefCount];

      where = 9;
      EOFLOGObjectLevel(@"EOEntity",
			@"primaryKeyAttributes gcIncrementRefCount");
      if (!_flags.primaryKeyAttributesIsLazy)
        [(id)_primaryKeyAttributes gcIncrementRefCount];

      where = 10;
      EOFLOGObjectLevel(@"EOEntity",
			@"classProperties gcIncrementRefCount");
      if (!_flags.classPropertiesIsLazy)
        [(id)_classProperties gcIncrementRefCount];

      where = 11;
      EOFLOGObjectLevel(@"EOEntity",
			@"attributesUsedForLocking gcIncrementRefCount");
      if (!_flags.attributesUsedForLockingIsLazy)
        [(id)_attributesUsedForLocking gcIncrementRefCount];

      where = 12;
      EOFLOGObjectLevel(@"EOEntity", @"subEntities gcIncrementRefCount");
      [(id)_subEntities gcIncrementRefCount];

      where = 13;
      EOFLOGObjectLevel(@"EOEntity", @"dbSnapshotKeys gcIncrementRefCount");
      [(id)_dbSnapshotKeys gcIncrementRefCount];

      where = 14;
      EOFLOGObjectLevel(@"EOEntity", @"parent gcIncrementRefCount");
      [_parent gcIncrementRefCount];

      where = 15;
      [_model gcIncrementRefCountOfContainedObjects];

      where = 16;
      EOFLOGObjectLevel(@"EOEntity", @"attributes gcIncrementRefCountOfContainedObjects");
      if (!_flags.attributesIsLazy)
        [(id)_attributes gcIncrementRefCountOfContainedObjects];

      where = 17;
      EOFLOGObjectLevel(@"EOEntity", @"attributesByName gcIncrementRefCountOfContainedObjects");
      [(id)_attributesByName gcIncrementRefCountOfContainedObjects];

      where = 18;
      EOFLOGObjectLevel(@"EOEntity", @"attributesToFetch gcIncrementRefCountOfContainedObjects");
      [(id)_attributesToFetch gcIncrementRefCountOfContainedObjects];

      where = 19;
      EOFLOGObjectLevelArgs(@"EOEntity", @"attributesToSave gcIncrementRefCountOfContainedObjects (class=%@)",
			    [_attributesToSave class]);
      [(id)_attributesToSave gcIncrementRefCountOfContainedObjects];

      where = 20;
      EOFLOGObjectLevel(@"EOEntity", @"propertiesToFault gcIncrementRefCountOfContainedObjects");
      [(id)_propertiesToFault gcIncrementRefCountOfContainedObjects];

      where = 21;
      EOFLOGObjectLevel(@"EOEntity", @"rrelationships gcIncrementRefCountOfContainedObjects");
      if (!_flags.relationshipsIsLazy)
        [(id)_relationships gcIncrementRefCountOfContainedObjects];

      where = 22;
      EOFLOGObjectLevel(@"EOEntity", @"relationshipsByName gcIncrementRefCountOfContainedObjects");
      [(id)_relationshipsByName gcIncrementRefCountOfContainedObjects];

      where = 23;
      EOFLOGObjectLevel(@"EOEntity", @"primaryKeyAttributes gcIncrementRefCountOfContainedObjects");
      if (!_flags.primaryKeyAttributesIsLazy)
        [(id)_primaryKeyAttributes gcIncrementRefCountOfContainedObjects];

      where = 24;
      EOFLOGObjectLevel(@"EOEntity", @"classProperties gcIncrementRefCountOfContainedObjects");
      if (!_flags.classPropertiesIsLazy)
        [(id)_classProperties gcIncrementRefCountOfContainedObjects];

      where = 25;
      EOFLOGObjectLevelArgs(@"EOEntity", @"attributesUsedForLocking (%@) gcIncrementRefCountOfContainedObjects",
			    [_attributesUsedForLocking class]);
      if (!_flags.attributesUsedForLockingIsLazy)
        [(id)_attributesUsedForLocking gcIncrementRefCountOfContainedObjects];

      where = 26;
      EOFLOGObjectLevel(@"EOEntity", @"subEntities gcIncrementRefCountOfContainedObjects");
      [(id)_subEntities gcIncrementRefCountOfContainedObjects];

      where = 27;
      EOFLOGObjectLevel(@"EOEntity", @"dbSnapshotKeys gcIncrementRefCountOfContainedObjects");
      [(id)_dbSnapshotKeys gcIncrementRefCountOfContainedObjects];

      where = 28;
      EOFLOGObjectLevel(@"EOEntity", @"_parent gcIncrementRefCountOfContainedObjects");
      [_parent gcIncrementRefCountOfContainedObjects];

      where = 29;
    }
  NS_HANDLER
    {
      NSLog(@"====>WHERE=%d %@ (%@)", where, localException,
	    [localException reason]);
      NSDebugMLog(@"attributes gcIncrementRefCountOfContainedObjects=%@",
		  [_attributes class]);
      NSDebugMLog(@"_attributes classes %@",
		  [_attributes resultsOfPerformingSelector: @selector(class)]);

      [localException raise];
    }
  NS_ENDHANDLER;

  EOFLOGObjectFnStop();

  [_debugSet removeObject: @"gsdb"];

  return YES;
}

- (NSString *)description
{
  NSMutableDictionary *plist;

  plist = [NSMutableDictionary dictionaryWithCapacity: 4];
  [self encodeIntoPropertyList: plist];

  return [plist description];
}

- (NSString *)debugDescription
{
  NSString *dscr = nil;

  dscr = [NSString stringWithFormat: @"<%s %p - name=%@ className=%@ externalName=%@ externalQuery=%@",
		   object_get_class_name(self),
		   (void*)self,
		   _name,
		   _className,
		   _externalName,
		   _externalQuery];

  dscr = [dscr stringByAppendingFormat:@" userInfo=%@",
	       _userInfo];
  dscr = [dscr stringByAppendingFormat:@" primaryKeyAttributeNames=%@ classPropertyNames=%@>",
	       [self primaryKeyAttributeNames],
	       [self classPropertyNames]];

  NSAssert4(!_attributesToFetch
	    || [_attributesToFetch isKindOfClass:[NSArray class]],
            @"entity %@ attributesToFetch %p is not an NSArray but a %@\n%@",
            [self name],
            _attributesToFetch,
            [_attributesToFetch class],
            _attributesToFetch);

  return dscr;
}

/*----------------------------------------*/

- (NSString *)name
{
  return _name;
}

- (EOModel *)model
{
  return _model;
}

- (NSString *)externalName
{
  EOFLOGObjectLevelArgs(@"EOEntity", @"entity %p (%@): external name=%@",
			self, [self name], _externalName);

  return _externalName;
}

- (NSString *)externalQuery
{
  return _externalQuery;
}

- (EOQualifier *)restrictingQualifier
{
  return _restrictingQualifier;
}

- (BOOL)isReadOnly
{
  return _flags.isReadOnly;
}

- (BOOL)cachesObjects
{
  return _flags.cachesObjects;
}

- (NSString *)className
{
  return _className;
} 

- (NSDictionary *)userInfo
{
  return _userInfo;
}

- (NSArray *)attributes
{
  //OK
  if (_flags.attributesIsLazy)
    {
      int count = 0;

      EOFLOGObjectLevelArgs(@"EOEntity", @"START construct attributes on %p",
			    self);

      count = [_attributes count];
      EOFLOGObjectLevelArgs(@"EOEntity", @"Entity %@: Lazy _attributes=%@",
			    [self name],
			    _attributes);

      if (count > 0)
        {
          int i = 0;
          NSArray *attributePLists = _attributes;
          NSDictionary *relationshipsByName = nil;

          DESTROY(_attributesByName);

          _attributes = [GCMutableArray new];
          _attributesByName = [GCMutableDictionary new];

          NSAssert2((!_attributesByName
		     || [_attributesByName isKindOfClass:
					     [NSDictionary class]]),
                    @"_attributesByName is not a NSDictionary but a %@. _attributesByName [%p]",
                    [_attributesByName class],
                    _attributesByName);

          if (!_flags.relationshipsIsLazy)
            relationshipsByName = [self relationshipsByName];

          _flags.attributesIsLazy = NO;

          [EOObserverCenter suppressObserverNotification];
          _flags.updating = YES;

          NS_DURING
            {
              NSArray *attrNames = nil;

              for (i = 0; i < count; i++)
                {
                  NSDictionary *attrPList = [attributePLists objectAtIndex: i];
                  EOAttribute *attribute = [EOAttribute
					     attributeWithPropertyList:
					       attrPList
					     owner: self];
                  NSString *attributeName = [attribute name];

                  EOFLOGObjectLevelArgs(@"EOEntity", @"XXX 1 ATTRIBUTE: attribute=%@",
					attribute);

                  if ([_attributesByName objectForKey: attributeName])
                    {
                      [NSException raise: NSInvalidArgumentException
                                   format: @"%@ -- %@ 0x%x: \"%@\" already used in the model as attribute",
                                   NSStringFromSelector(_cmd),
                                   NSStringFromClass([self class]),
                                   self,
                                   attributeName];
                    }

                  if ([relationshipsByName objectForKey: attributeName])
                    {
                      [NSException raise: NSInvalidArgumentException
                                   format: @"%@ -- %@ 0x%x: \"%@\" already used in the model",
                                   NSStringFromSelector(_cmd),
                                   NSStringFromClass([self class]),
                                   self,
                                   attributeName];
                    }

                  EOFLOGObjectLevelArgs(@"EOEntity", @"Add attribute: %@",
					attribute);

                  [_attributes addObject: attribute];
                  [_attributesByName setObject: attribute
				     forKey: attributeName];
                }

              EOFLOGObjectLevelArgs(@"EOEntity", @"_attributesByName class=%@",
				    [_attributesByName class]);
              NSAssert2((!_attributesByName
			 || [_attributesByName isKindOfClass:
						 [NSDictionary class]]),
                        @"_attributesByName is not a NSDictionary but a %@. _attributesByName [%p]",
                        [_attributesByName class],
                        _attributesByName);

              EOFLOGObjectLevelArgs(@"EOEntity", @"_attributes [%p]=%@",
				    _attributes, _attributes);
              EOFLOGObjectLevelArgs(@"EOEntity", @"_attributesByName class=%@",
				    [_attributesByName class]);
              EOFLOGObjectLevelArgs(@"EOEntity", @"_attributesByName [%p]",
				    _attributesByName);
              EOFLOGObjectLevelArgs(@"EOEntity", @"_attributesByName class=%@",
				    [_attributesByName class]);
              //TODO[self _setIsEdited];//To Clean Buffers
              EOFLOGObjectLevelArgs(@"EOEntity", @"_attributesByName [%p]",
				    _attributesByName);
              EOFLOGObjectLevelArgs(@"EOEntity", @"_attributesByName class=%@",
				    [_attributesByName class]);

              NSAssert2((!_attributesByName
			 || [_attributesByName isKindOfClass:
						 [NSDictionary class]]),
                        @"_attributesByName is not a NSDictionary but a %@. _attributesByName [%p]",
                        [_attributesByName class],
                        _attributesByName);

              attrNames = [_attributes resultsOfPerformingSelector:
					 @selector(name)];
              NSAssert2((!_attributesByName
			 || [_attributesByName isKindOfClass:
						 [NSDictionary class]]),
                        @"_attributesByName is not a NSDictionary but a %@. _attributesByName [%p]",
                        [_attributesByName class],
                        _attributesByName);

              EOFLOGObjectLevelArgs(@"EOEntity", @"attrNames [%p]=%@",
				    attrNames, attrNames);

              count = [attrNames count];
              EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p Attributes count=%d",
				    self, count);
              NSAssert(count == [attributePLists count],
		       @"Error during attribute creations");
              EOFLOGObjectLevelArgs(@"EOEntity", @"attributePLists=%@",
				    attributePLists);
              EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p attributePLists count=%d",
				    self, [attributePLists count]);

              {
                int pass = 0;

                //We'll first awake non derived/flattened attributes
                for (pass = 0; pass < 2; pass++)
                  {
                    for (i = 0; i < count; i++)
                      {
                        NSString *attrName = [attrNames objectAtIndex: i];
                        NSDictionary *attrPList = [attributePLists
						    objectAtIndex: i];
                        EOAttribute *attribute = nil;

                        EOFLOGObjectLevelArgs(@"EOEntity", @"XXX attrName=%@",
					      attrName);

                        if ((pass == 0 &&
			     ![attrPList objectForKey: @"definition"]) 
                            || (pass == 1
				&& [attrPList objectForKey: @"definition"]))
                          {
                            attribute = [self attributeNamed: attrName];
                            EOFLOGObjectLevelArgs(@"EOEntity", @"XXX 2A ATTRIBUTE: self=%p AWAKE attribute=%@",
						  self, attribute);

                            [attribute awakeWithPropertyList: attrPList];
                            EOFLOGObjectLevelArgs(@"EOEntity", @"XXX 2B ATTRIBUTE: self=%p attribute=%@",
						  self, attribute);
                          }
                      }
                  }
              }
              NSAssert2((!_attributesByName
			 || [_attributesByName isKindOfClass:
						 [NSDictionary class]]),
                        @"_attributesByName is not a NSDictionary but a %@. _attributesByName [%p]",
                        [_attributesByName class],
                        _attributesByName);
            }
          NS_HANDLER
            {
              DESTROY(attributePLists);
	      _flags.updating = NO;
              [EOObserverCenter enableObserverNotification];
              [localException raise];
            }
          NS_ENDHANDLER;

          DESTROY(attributePLists);

          _flags.updating = NO;
          [EOObserverCenter enableObserverNotification];
          [_attributes sortUsingSelector: @selector(eoCompareOnName:)];//Very important to have always the same order.
        }
      else
        _flags.attributesIsLazy = NO;

      EOFLOGObjectLevelArgs(@"EOEntity", @"STOP construct attributes on %p",
			    self);
    }

  return _attributes;
}

- (EOAttribute *)attributeNamed: (NSString *)attributeName
{
  //OK
  EOAttribute *attribute = nil;
  NSDictionary *attributesByName = nil;

  EOFLOGObjectFnStart();

  attributesByName = [self attributesByName];

  EOFLOGObjectLevelArgs(@"EOEntity", @"attributesByName [%p] (%@)",
			attributesByName,
			[attributesByName class]);
  NSAssert2((!attributesByName
	     || [attributesByName isKindOfClass: [NSDictionary class]]),
            @"attributesByName is not a NSDictionary but a %@. attributesByName [%p]",
            [attributesByName class],
            attributesByName);
  //  EOFLOGObjectLevelArgs(@"EOEntity",@"attributesByName=%@",attributesByName);

  attribute = [attributesByName objectForKey: attributeName];

  EOFLOGObjectFnStop();

  return attribute;
}

/** returns attribute named attributeName (no relationship) **/
- (EOAttribute *)anyAttributeNamed: (NSString *)attributeName
{
  EOAttribute *attr;
  NSEnumerator *attrEnum;

  attr = [self attributeNamed:attributeName];

  //VERIFY
  if (!attr)
    {
      IMP enumNO=NULL;
      attrEnum = [[self primaryKeyAttributes] objectEnumerator];

      while ((attr = GDL2NextObjectWithImpPtr(attrEnum,&enumNO)))
        {
	  if ([[attr name] isEqual: attributeName])
	    return attr;
        }
    }

  return attr;
}

- (NSArray *)relationships
{
  //OK
  if (_flags.relationshipsIsLazy)
    {
      int count = 0;

      EOFLOGObjectLevelArgs(@"EOEntity", @"START construct relationships on %p",
			    self);

      count = [_relationships count];
      EOFLOGObjectLevelArgs(@"EOEntity", @"Lazy _relationships=%@",
			    _relationships);

      if (count > 0)
        {
          int i = 0;
          NSArray *relationshipPLists = _relationships;
          NSDictionary *attributesByName = nil;

          DESTROY(_relationshipsByName);

          _relationships = [GCMutableArray new];
          _relationshipsByName = [GCMutableDictionary new];

          if (!_flags.attributesIsLazy)
            {
              attributesByName = [self attributesByName];
              NSAssert2((!attributesByName
			 || [attributesByName isKindOfClass:
						[NSDictionary class]]),
                        @"attributesByName is not a NSDictionary but a %@. attributesByName [%p]",
                        [attributesByName class],
                        attributesByName);
            }

          _flags.relationshipsIsLazy = NO;
          [EOObserverCenter suppressObserverNotification];
          _flags.updating = YES;

          NS_DURING
            {
              NSArray *relNames = nil;

              for (i = 0; i < count; i++)
                {
                  NSDictionary *attrPList = [relationshipPLists
					      objectAtIndex: i];
                  EORelationship *relationship = nil;
                  NSString *relationshipName = nil;

                  EOFLOGObjectLevelArgs(@"EOEntity", @"attrPList: %@",
					attrPList);

                  relationship = [EORelationship
				   relationshipWithPropertyList: attrPList
				   owner: self];

                  relationshipName = [relationship name];

                  EOFLOGObjectLevelArgs(@"EOEntity", @"relationshipName: %@",
					relationshipName);

                  if ([attributesByName objectForKey: relationshipName])
                    {
                      [NSException raise: NSInvalidArgumentException
                                   format: @"%@ -- %@ 0x%x: \"%@\" already used in the model as attribute",
                                   NSStringFromSelector(_cmd),
                                   NSStringFromClass([self class]),
                                   self,
                                   relationshipName];
                    }

                  if ([_relationshipsByName objectForKey: relationshipName])
                    {
                      [NSException raise: NSInvalidArgumentException
                                   format: @"%@ -- %@ 0x%x: \"%@\" already used in the model",
                                   NSStringFromSelector(_cmd),
                                   NSStringFromClass([self class]),
                                   self,
                                   relationshipName];
                    }

                  EOFLOGObjectLevelArgs(@"EOEntity", @"Add rel %p",
					relationship);
                  EOFLOGObjectLevelArgs(@"EOEntity", @"Add rel=%@",
					relationship);

                  [_relationships addObject: relationship];
                  [_relationshipsByName setObject: relationship
                                        forKey: relationshipName];
                }

              EOFLOGObjectLevel(@"EOEntity", @"Rels added");

              [self _setIsEdited];//To Clean Buffers
              relNames = [_relationships
			   resultsOfPerformingSelector: @selector(name)];

              EOFLOGObjectLevelArgs(@"EOEntity", @"relNames=%@", relNames);

              count = [relNames count];
              EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p rel count=%d",
				    self, count);

              NSAssert(count == [relationshipPLists count],
		       @"Error during attribute creations");
              {
                int pass = 0;

                //We'll first awake non flattened relationships
                for (pass = 0; pass < 2; pass++)
                  {
                    for (i = 0; i < count; i++)
                      {
                        NSString *relName = [relNames objectAtIndex: i];
                        NSDictionary *relPList = [relationshipPLists
						   objectAtIndex: i];
                        EORelationship *relationship = [self relationshipNamed:
							       relName];

                        EOFLOGObjectLevelArgs(@"EOEntity", @"relName=%@",
					      relName);

                        if ((pass == 0
			     && ![relPList objectForKey: @"definition"]) 
                            || (pass == 1
				&& [relPList objectForKey: @"definition"]))
                          {
                            EOFLOGObjectLevelArgs(@"EOEntity", @"XXX REL: self=%p AWAKE relationship=%@",
						  self, relationship);

                            [relationship awakeWithPropertyList: relPList];
                          }
                      }
                  }
              }
            }
          NS_HANDLER
            {
              EOFLOGObjectLevelArgs(@"EOEntity", @"localException=%@",
				    localException);

              DESTROY(relationshipPLists);

              _flags.updating = NO;
              [EOObserverCenter enableObserverNotification];
              [localException raise];
            }
          NS_ENDHANDLER;

          DESTROY(relationshipPLists);

          _flags.updating = NO;
          [EOObserverCenter enableObserverNotification];
        }
      else
        _flags.relationshipsIsLazy = NO;

      EOFLOGObjectLevelArgs(@"EOEntity", @"STOP construct relationships on %p",
			    self);
    }

  return _relationships;
}

- (EORelationship *)relationshipNamed: (NSString *)relationshipName
{
  //OK
  return [[self relationshipsByName] objectForKey: relationshipName];
}

- (EORelationship *)anyRelationshipNamed: (NSString *)relationshipNamed
{
  EORelationship *rel;
  NSEnumerator *relEnum = nil;

  rel = [self relationshipNamed: relationshipNamed];

  //VERIFY
  if (!rel)
    {
      EORelationship *tmpRel = nil;
      IMP enumNO=NULL;

      relEnum = [_hiddenRelationships objectEnumerator];

      while (!rel && (tmpRel = GDL2NextObjectWithImpPtr(relEnum,&enumNO)))
        {
	  if ([[tmpRel name] isEqual: relationshipNamed])
	    rel = tmpRel;
        }
    }

  return rel;
}

- (NSArray *)classProperties
{
  //OK
  EOFLOGObjectFnStart();

  if (_flags.classPropertiesIsLazy)
    {
      int count = [_classProperties count];

      EOFLOGObjectLevelArgs(@"EOEntity", @"Lazy _classProperties=%@",
			    _classProperties);

      if (count > 0)
        {
          NSArray *classPropertiesList = _classProperties;
          int i;

          _classProperties = [GCMutableArray new];
          _flags.classPropertiesIsLazy = NO;

          for (i = 0; i < count; i++)
            {
#if 0
              NSString *classPropertyName = [classPropertiesList
					      objectAtIndex: i];
#else
              NSString *classPropertyName = (
       [[classPropertiesList objectAtIndex:i] isKindOfClass:[NSString class]] ?
        [classPropertiesList objectAtIndex:i] :
        [(EOEntity *)[classPropertiesList objectAtIndex: i] name]);
#endif
              id classProperty = [self attributeNamed: classPropertyName];

              if (!classProperty)
                  classProperty = [self relationshipNamed: classPropertyName];

              NSAssert4(classProperty,
                        @"No attribute or relationship named '%@' (property at index %d) to use as classProperty in entity name '%@' : %@",
                        classPropertyName,
                        i+1,
                        [self name],
                        self);

              if ([self isValidClassProperty: classProperty])
                [_classProperties addObject: classProperty];
              else
                {
                  //TODO
                  NSAssert2(NO, @"not valid class prop %@ in %@",
			    classProperty, [self name]);
                }
            }

          DESTROY(classPropertiesList);

          [_classProperties sortUsingSelector: @selector(eoCompareOnName:)]; //Very important to have always the same order.
          [self _setIsEdited]; //To Clean Buffers
        }
      else
        _flags.classPropertiesIsLazy = NO;
    }

  EOFLOGObjectFnStop();

  return _classProperties;
}

- (NSArray *)classPropertyNames
{
  //OK
  EOFLOGObjectFnStart();

  if (!_classPropertyNames)
    {
      NSArray *classProperties = [self classProperties];

      NSAssert2(!classProperties
		|| [classProperties isKindOfClass: [NSArray class]],
                @"classProperties is not an NSArray but a %@\n%@",
                [classProperties class],
                classProperties);

      ASSIGN(_classPropertyNames,
	     [classProperties resultsOfPerformingSelector: @selector(name)]);
    }

  NSAssert4(!_attributesToFetch
	    || [_attributesToFetch isKindOfClass: [NSArray class]],
            @"entity %@ attributesToFetch %p is not an NSArray but a %@\n%@",
            [self name],
            _attributesToFetch,
            [_attributesToFetch class],
            _attributesToFetch);

  EOFLOGObjectFnStop();

  return _classPropertyNames;
}

- (NSArray *)fetchSpecificationNames
{
  return _fetchSpecificationNames;
}

- (EOFetchSpecification *)fetchSpecificationNamed: (NSString *)fetchSpecName
{
  return [_fetchSpecificationDictionary objectForKey: fetchSpecName];
}

- (NSArray *)sharedObjectFetchSpecificationNames
{
  NSEmitTODO(); //TODO
  [self notImplemented: _cmd];
  return nil;
}

- (NSArray*)primaryKeyAttributes
{
  //OK
  if (_flags.primaryKeyAttributesIsLazy)
    {
      int count = [_primaryKeyAttributes count];

      EOFLOGObjectLevelArgs(@"EOEntity", @"Lazy _primaryKeyAttributes=%@",
			    _primaryKeyAttributes);

      if (count > 0)
        {
          int i = 0;
          NSArray *primaryKeyAttributes = _primaryKeyAttributes;

          _primaryKeyAttributes = [GCMutableArray new];
          _flags.primaryKeyAttributesIsLazy = NO;

          for (i = 0; i < count; i++)
            {
              NSString *attributeName = [primaryKeyAttributes objectAtIndex: i];
              EOAttribute *attribute = [self attributeNamed: attributeName];

              NSAssert3(attribute, @"In entity %@: No attribute named %@ "
		@"to use for locking (attributes: %@)", [self name],
		attributeName, [[self attributes]
		  resultsOfPerformingSelector: @selector(name)]);

              if ([self isValidPrimaryKeyAttribute: attribute])
                [_primaryKeyAttributes addObject: attribute];
              else
                {
                  NSAssert2(NO, @"not valid pk attribute %@ in %@",
			    attribute, [self name]);
                }
            }

          DESTROY(primaryKeyAttributes);

          [_primaryKeyAttributes sortUsingSelector: @selector(eoCompareOnName:)]; //Very important to have always the same order.
          [self _setIsEdited]; //To Clean Buffers
        }
      else
        _flags.primaryKeyAttributesIsLazy = NO;
    }

  return _primaryKeyAttributes;
}

- (NSArray *)primaryKeyAttributeNames
{
  //OK
  if (!_primaryKeyAttributeNames)
    {
      NSArray *primaryKeyAttributes = [self primaryKeyAttributes];
      NSArray *primaryKeyAttributeNames = [primaryKeyAttributes
					    resultsOfPerformingSelector:
					      @selector(name)];

      primaryKeyAttributeNames = [primaryKeyAttributeNames sortedArrayUsingSelector: @selector(compare:)]; //Not necessary: they are already sorted
      ASSIGN(_primaryKeyAttributeNames, primaryKeyAttributeNames);
    }

  return _primaryKeyAttributeNames;
}

- (NSArray *)attributesUsedForLocking
{
  //OK
  if (_flags.attributesUsedForLockingIsLazy)
    {
      int count = [_attributesUsedForLocking count];

      EOFLOGObjectLevelArgs(@"EOEntity", @"Lazy _attributesUsedForLocking=%@",
			    _attributesUsedForLocking);

      if (count > 0)
        {
          int i = 0;
          NSArray *attributesUsedForLocking = _attributesUsedForLocking;

          _attributesUsedForLocking = [GCMutableArray new];
          _flags.attributesUsedForLockingIsLazy = NO;

          for (i = 0; i < count; i++)
            {
              NSString *attributeName = [attributesUsedForLocking
					  objectAtIndex: i];
              EOAttribute *attribute = [self attributeNamed: attributeName];

              NSAssert1(attribute,
                        @"No attribute named %@ to use for locking",
                        attribute);

              if ([self isValidAttributeUsedForLocking: attribute])
                [_attributesUsedForLocking addObject: attribute];
              else
                {
		  NSEmitTODO(); //TODO
                  [self notImplemented: _cmd]; //TODO
                }
            }

          EOFLOGObjectLevelArgs(@"EOEntity", @"_attributesUsedForLocking class=%@",
				[_attributesUsedForLocking class]);          

          DESTROY(attributesUsedForLocking);

          [self _setIsEdited]; //To Clean Buffers
        }
      else
        _flags.attributesUsedForLockingIsLazy = NO;
    }

  return _attributesUsedForLocking;
}

- (NSArray *)attributesToFetch
{
  //OK
  NSAssert3(!_attributesToFetch 
	    | [_attributesToFetch isKindOfClass: [NSArray class]],
            @"entity %@ attributesToFetch %p is not an NSArray but a %@",
            [self name],
            _attributesToFetch,
            [_attributesToFetch class]);

  return [self _attributesToFetch];
}

- (EOQualifier *)qualifierForPrimaryKey: (NSDictionary *)row
{
  //OK
  EOQualifier *qualifier = nil;
  NSArray *primaryKeyAttributeNames = [self primaryKeyAttributeNames];
  int count = [primaryKeyAttributeNames count];

  if (count == 1)
    {
      //OK
      NSString *key = [primaryKeyAttributeNames objectAtIndex: 0];
      id value = [row objectForKey: key];

      qualifier = [EOKeyValueQualifier qualifierWithKey: key
				       operatorSelector:
					 EOQualifierOperatorEqual
				       value: value];
    }
  else
    {
      //Seems OK
      NSMutableArray *array = GDL2MutableArrayWithCapacity(count);
      IMP pkanOAI=NULL;
      IMP rowOFK=NULL;
      IMP arrayAO=NULL;
      int i;

      for (i = 0; i < count; i++)
	{
	  NSString *key = GDL2ObjectAtIndexWithImpPtr(primaryKeyAttributeNames,&pkanOAI,i);
          id value = GDL2ObjectForKeyWithImpPtr(row,&rowOFK,key);

	  GDL2AddObjectWithImpPtr(array,&arrayAO,
                                  [EOKeyValueQualifier qualifierWithKey: key
                                                       operatorSelector:
                                                         EOQualifierOperatorEqual
                                                       value: value]);
	}

      qualifier = [EOAndQualifier qualifierWithQualifierArray: array];
    }

  return qualifier;
}

- (BOOL)isQualifierForPrimaryKey: (EOQualifier *)qualifier
{
  int count = [[self primaryKeyAttributeNames] count];

  if (count == 1)
    {
      if ([qualifier isKindOfClass: [EOKeyValueQualifier class]] == YES)
	return YES;
      else
	return NO;
    }
  else
    {
    }

  //TODO
  NSEmitTODO();  //TODO
  [self notImplemented:_cmd];

  return NO;
}

- (NSDictionary *)primaryKeyForRow: (NSDictionary *)row
{
  NSMutableDictionary *dict = nil;
  int i, count;
  NSArray *primaryKeyAttributes = [self primaryKeyAttributes];
  IMP pkaOAI=NULL;
  IMP rowOFK=NULL;
  IMP dictSOFK=NULL;

  count = [primaryKeyAttributes count];
  dict = [NSMutableDictionary dictionaryWithCapacity: count];

  for (i = 0; i < count; i++)
    {
      EOAttribute *attr = GDL2ObjectAtIndexWithImpPtr(primaryKeyAttributes,&pkaOAI,i);
      NSString* attrName = [attr name];
      id value = GDL2ObjectForKeyWithImpPtr(row,&rowOFK,attrName);

      if (!value)
        value = GDL2EONull;

      GDL2SetObjectForKeyWithImpPtr(dict,&dictSOFK,value,attrName);
    }

  return dict;
}

- (BOOL)isValidAttributeUsedForLocking: (EOAttribute *)anAttribute
{
  if (!([anAttribute isKindOfClass: GDL2EOAttributeClass]
	&& [[self attributesByName] objectForKey: [anAttribute name]]))
    return NO;

  if ([anAttribute isDerived])
    return NO;

  return YES;
}

- (BOOL)isValidPrimaryKeyAttribute: (EOAttribute *)anAttribute
{
  if (!([anAttribute isKindOfClass: GDL2EOAttributeClass]
	&& [[self attributesByName] objectForKey: [anAttribute name]]))
    return NO;

  if ([anAttribute isDerived])
    return NO;

  return YES;
}

- (BOOL)isPrimaryKeyValidInObject: (id)object
{
  NSArray *primaryKeyAttributeNames = nil;
  NSString *key = nil;
  id value = nil;
  int i, count;
  BOOL isValid = YES;
  IMP pkanOAI=NULL;
  IMP objectVFK=NULL;

  primaryKeyAttributeNames = [self primaryKeyAttributeNames];
  count = [primaryKeyAttributeNames count];

  for (i = 0; isValid && i < count; i++)
    {
      key = GDL2ObjectAtIndexWithImpPtr(primaryKeyAttributeNames,&pkanOAI,i);

      NS_DURING
	{
          value = GDL2ValueForKeyWithImpPtr(object,&objectVFK,key);
          if (_isNilOrEONull(value))
            isValid = NO;
	}
      NS_HANDLER
	{
	  isValid = NO;
	}
      NS_ENDHANDLER;
    }
  
  return isValid;
}

- (BOOL)isValidClassProperty: (id)aProperty
{
  id thePropertyName;

  if (!([aProperty isKindOfClass: GDL2EOAttributeClass]
	|| [aProperty isKindOfClass: [EORelationship class]]))
    return NO;

  thePropertyName = [(EOAttribute *)aProperty name];

  if ([[self attributesByName] objectForKey: thePropertyName]
      || [[self relationshipsByName] objectForKey: thePropertyName])
    return YES;

  return NO;
}

- (NSArray *)subEntities
{
  return _subEntities;
}

- (EOEntity *)parentEntity
{
  return _parent;
}

- (BOOL)isAbstractEntity
{
  return _flags.isAbstractEntity;
}


- (unsigned int)maxNumberOfInstancesToBatchFetch
{
  return _batchCount;
}

- (EOGlobalID *)globalIDForRow: (NSDictionary *)row
{
  EOGlobalID *gid = [self globalIDForRow: row
			  isFinal: NO];

  NSAssert(gid, @"No gid");
//TODO
/*
pas toutjur: la suite editingc objectForGlobalID:
EODatabaseContext snapshotForGlobalID:
  if no snpashot:
  {
database recordSnapshot:forGlobalID:
self classDescriptionForInstances
createInstanceWithEditingContext:globalID:zone:
  }
*/
  return gid;
}

- (NSDictionary *)primaryKeyForGlobalID: (EOKeyGlobalID *)gid
{
  //OK
  NSMutableDictionary *dictionaryForPrimaryKey = nil;

  EOFLOGObjectFnStart();

  NSDebugMLLog(@"EOEntity", @"gid=%@", gid);

  if ([gid isKindOfClass: [EOKeyGlobalID class]]) //if ([gid isFinal])//?? or class test ??//TODO
    {
      NSArray *primaryKeyAttributeNames = [self primaryKeyAttributeNames];
      int count = [primaryKeyAttributeNames count];

      NSDebugMLLog(@"EOEntity", @"primaryKeyAttributeNames=%@",
		   primaryKeyAttributeNames);

      if (count > 0)
        {
          int i;
          id *gidkeyValues = [gid keyValues];

          if (gidkeyValues)
            {
              IMP pkanOAI=NULL;
              IMP dfpkSOFK=NULL;
              dictionaryForPrimaryKey = [self _dictionaryForPrimaryKey];

              NSAssert1(dictionaryForPrimaryKey,
			@"No dictionaryForPrimaryKey in entity %@",
                        [self name]);
              NSDebugMLLog(@"EOEntity", @"dictionaryForPrimaryKey=%@",
			   dictionaryForPrimaryKey);

              for (i = 0; i < count; i++)
                {
                  id key = GDL2ObjectAtIndexWithImpPtr(primaryKeyAttributeNames,&pkanOAI,i);

                  GDL2SetObjectForKeyWithImpPtr(dictionaryForPrimaryKey,&dfpkSOFK,
                                                gidkeyValues[i],key);
                }
            }
        }
    }
  else
    {
      NSDebugLog(@"EOEntity (%@): primaryKey is *nil* for globalID = %@",
		 _name, gid);
    }

  NSDebugMLLog(@"EOEntity", @"dictionaryForPrimaryKey=%@",
	       dictionaryForPrimaryKey);

  EOFLOGObjectFnStop();

  return dictionaryForPrimaryKey;
}
@end


@implementation EOEntity (EOEntityEditing)

- (void)setName: (NSString *)name
{
  if (name && [name isEqual: _name]) return;
  
  [[self validateName: name] raise];

  [self willChange];
  ASSIGNCOPY(_name, name);
  [_model _updateCache];
}

- (void)setExternalName: (NSString *)name
{
  //OK
  EOFLOGObjectLevelArgs(@"EOEntity", @"entity %p (%@): external name=%@",
			self, [self name], name);

  [self willChange];
  ASSIGNCOPY(_externalName,name);
  [self _setIsEdited];
}

- (void)setExternalQuery: (NSString *)query
{
  //OK
  [self willChange];
  ASSIGNCOPY(_externalQuery, query);
  [self _setIsEdited];
}

- (void)setRestrictingQualifier: (EOQualifier *)qualifier
{
  [self willChange];
  ASSIGN(_restrictingQualifier, qualifier);
}

- (void)setReadOnly: (BOOL)flag
{
  //OK
  [self willChange];
  _flags.isReadOnly = flag;
}

- (void)setCachesObjects: (BOOL)flag
{
  //OK
  [self willChange];
  _flags.cachesObjects = flag;
}

- (void)addAttribute: (EOAttribute *)attribute
{
  NSString *attributeName = [attribute name];

  NSAssert2([[self attributesByName] objectForKey: attributeName] == nil,
	    @"'%@': attribute '%@' already used in the entity",
	    [self name],
	    attributeName);

  NSAssert2([[self relationshipsByName] objectForKey: attributeName] == nil,
	    @"'%@': attribute '%@' already used in entity as relationship",
	    [self name],
	    attributeName);

  NSAssert4([attribute parent] == nil,
	    @"'%@': attribute '%@' already owned by '%@' '%@'",
	    [self name],
	    attributeName,
	    NSStringFromClass([[attribute parent] class]),
	    [(EOEntity *)[attribute parent] name]);
  
  [self willChange]; 
  if ([self createsMutableObjects])
    [(GCMutableArray *)_attributes addObject: attribute];
  else
    _attributes = RETAIN([AUTORELEASE(_attributes)
		     arrayByAddingObject: attribute]);

  if (_attributesByName == nil)
    {
      _attributesByName = [GCMutableDictionary new];
    }
  [_attributesByName setObject: attribute forKey: attributeName];

  [self _setIsEdited]; //To clean caches
  [attribute setParent: self];
}

- (void) removeAttribute: (EOAttribute *)attribute
{
  if (attribute)
    {
      [self willChange];
      [attribute setParent: nil];
      NSEmitTODO();  //TODO

      //TODO
      if ([self createsMutableObjects])
	[(GCMutableArray *)_attributes removeObject: attribute];
      else
        {
          _attributes
	    = [[GCMutableArray alloc] initWithArray:AUTORELEASE(_attributes)
				      copyItems:NO];
	  [(GCMutableArray *)_attributes removeObject: attribute];
	  _attributes 
	    = [[GCArray alloc] initWithArray:AUTORELEASE(_attributes)
			       copyItems:NO];
        }
      [_attributesByName removeObjectForKey: [attribute name]];
      [self _setIsEdited];//To clean caches
    }
}

- (void)addRelationship: (EORelationship *)relationship
{
  NSString *relationshipName = [relationship name];

  if ([[self attributesByName] objectForKey: relationshipName])
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: \"%@\" already used in the model as attribute",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self,
                 relationshipName];

  if ([[self relationshipsByName] objectForKey: relationshipName])
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: \"%@\" already used in the model",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self,
                 relationshipName];

  [self willChange];
  if ([self createsMutableObjects])
    [(GCMutableArray *)_relationships addObject: relationship];
  else
    _relationships = RETAIN([AUTORELEASE(_relationships)
					arrayByAddingObject: relationship]);
    
  if (_relationshipsByName == nil)
    {
      _relationshipsByName = [GCMutableDictionary new];
    }
  [_relationshipsByName setObject: relationship forKey: relationshipName];
  
  [relationship setEntity: self];
  [self _setIsEdited];//To clean caches
}

- (void)removeRelationship: (EORelationship *)relationship
{
  NSEmitTODO();  //TODO

  //TODO
  if (relationship)
    {
      [self willChange]; 
      [relationship setEntity:nil];

      if(_relationshipsByName != nil)
	[_relationshipsByName removeObjectForKey:[relationship name]];
      if ([self createsMutableObjects])
	[(GCMutableArray *)_relationships removeObject: relationship];
      else
        {
          _relationships
	    = [[GCMutableArray alloc] initWithArray:AUTORELEASE(_relationships)
				      copyItems:NO];
	  [(GCMutableArray *)_relationships removeObject: relationship];
	  _relationships
	    = [[GCArray alloc] initWithArray:AUTORELEASE(_relationships)
			       copyItems:NO];
        }
      [self _setIsEdited];//To clean caches
    }
}

- (void)addFetchSpecification: (EOFetchSpecification *)fetchSpec
		     withName: (NSString *)name
{
  if (_fetchSpecificationDictionary == nil)
    {
      _fetchSpecificationDictionary = [NSMutableDictionary new];
    }

  [self willChange];
  [_fetchSpecificationDictionary setObject: fetchSpec forKey: name];
  ASSIGN(_fetchSpecificationNames, [[_fetchSpecificationDictionary allKeys]
				     sortedArrayUsingSelector:
				       @selector(compare:)]);
}

- (void)removeFetchSpecificationNamed: (NSString *)name
{
  [self willChange];
  [_fetchSpecificationDictionary removeObjectForKey:name];
  ASSIGN(_fetchSpecificationNames, [[_fetchSpecificationDictionary allKeys]
				     sortedArrayUsingSelector:
				       @selector(compare:)]);
}

- (void)setSharedObjectFetchSpecificationsByName: (NSArray *)names
{
  NSEmitTODO();  //TODO
  [self notImplemented:_cmd];
}
- (void)addSharedObjectFetchSpecificationByName: (NSString *)name
{
  NSEmitTODO();  //TODO
  [self notImplemented:_cmd];
}
- (void)removeSharedObjectFetchSpecificationByName: (NSString *)name
{
  NSEmitTODO();  //TODO
  [self notImplemented:_cmd];
}

- (void)setClassName:(NSString *)name
{
  //OK
  [self willChange];

  if (!name)
    {
      NSLog(@"Entity %@ has no class name. Use EOGenericRecord", [self name]);
      name = @"EOGenericRecord";
    }
  ASSIGNCOPY(_className, name);

  [self _setIsEdited];
}

- (void)setUserInfo: (NSDictionary *)dictionary
{
  //OK
  [self willChange];
  ASSIGN(_userInfo, dictionary);
  [self _setIsEdited];
}

- (BOOL)setClassProperties: (NSArray *)properties
{
  int i, count = [properties count];

  for (i = 0; i < count; i++)
    if (![self isValidClassProperty: [properties objectAtIndex:i]])
      return NO;

  [self willChange];
  DESTROY(_classProperties);
  if ([properties isKindOfClass:[GCArray class]]
      || [properties isKindOfClass: [GCMutableArray class]])
    _classProperties = [[GCMutableArray alloc] initWithArray: properties];
  else
    _classProperties = [[GCMutableArray alloc] initWithArray: properties]; //TODO

  [self _setIsEdited]; //To clean cache

  return YES;
}

- (BOOL)setPrimaryKeyAttributes: (NSArray *)keys
{
  int i, count = [keys count];

  for (i = 0; i < count; i++)
    if (![self isValidPrimaryKeyAttribute: [keys objectAtIndex:i]])
      return NO;

  [self willChange];
  DESTROY(_primaryKeyAttributes);

  if ([keys isKindOfClass:[GCArray class]]
      || [keys isKindOfClass: [GCMutableArray class]])
    _primaryKeyAttributes = [[GCMutableArray alloc] initWithArray: keys];
  else
    _primaryKeyAttributes = [[GCMutableArray alloc] initWithArray: keys]; // TODO
  
  [self _setIsEdited];//To clean cache

  return YES;
}

- (BOOL) setAttributesUsedForLocking: (NSArray *)attributes
{
  int i, count = [attributes count];

  for (i = 0; i < count; i++)
    if (![self isValidAttributeUsedForLocking: [attributes objectAtIndex: i]])
      return NO;

  [self willChange];
  DESTROY(_attributesUsedForLocking);
  
  if ([attributes isKindOfClass: [GCArray class]]   // TODO
      || [attributes isKindOfClass: [GCMutableArray class]])
    _attributesUsedForLocking = [[GCMutableArray alloc]
				  initWithArray: attributes];
  else
    _attributesUsedForLocking = [[GCMutableArray alloc]
				  initWithArray: attributes];
  
  [self _setIsEdited]; //To clean cache

  return YES;
}

- (NSException *)validateName: (NSString *)name
{
  const char *p, *s = [name cString];
  int exc = 0;
  NSArray *storedProcedures;

  if (!name || ![name length]) exc++;
  if (!exc)
    {
      p = s;
      while (*p)
        {
	  if (!isalnum(*p) &&
	     *p != '@' && *p != '#' && *p != '_' && *p != '$')
            {
	      exc++;
	      break;
            }
	  p++;
        }
      if (!exc && *s == '$') exc++;
      
      if (exc)
        return [NSException exceptionWithName: NSInvalidArgumentException
			  reason: [NSString stringWithFormat:@"%@ -- %@ 0x%x: argument \"%@\" contains invalid char '%c'",
					    NSStringFromSelector(_cmd),
					    NSStringFromClass([self class]),
					    self,
					    name,
					    *p]
			  userInfo: nil];

      if ([_model entityNamed: name]) exc++;
      else if ((storedProcedures = [[self model] storedProcedures]))
        {
	  NSEnumerator *stEnum = [storedProcedures objectEnumerator];
	  EOStoredProcedure *st;
	  
	  while ((st = [stEnum nextObject]))
            {
	      NSEnumerator *attrEnum;
	      EOAttribute  *attr;

	      attrEnum = [[st arguments] objectEnumerator];
	      while ((attr = [attrEnum nextObject]))
                {
		  if ([name isEqualToString: [attr name]])
                    {
		      exc++;
		      break;
                    }
                }

	      if (exc) break;
            }
        }
    }
    
  if (exc)
    {
      return [NSException exceptionWithName: NSInvalidArgumentException
                  	 reason: [NSString stringWithFormat: @"%@ -- %@ 0x%x: \"%@\" already used in the model",
			 	 NSStringFromSelector(_cmd),
				 NSStringFromClass([self class]),
				 self,
				 name]
			userInfo: nil];
    }
  
  return nil;
}

- (void)addSubEntity: (EOEntity *)child
{
  [self willChange];
  [_subEntities addObject: child];
  [child setParentEntity: self];
}

- (void)removeSubEntity: (EOEntity *)child
{
  [self willChange];
  [child setParentEntity: nil];
  [_subEntities removeObject: child];
}

- (void)setIsAbstractEntity: (BOOL)flag
{
  //OK
  [self willChange];
  _flags.isAbstractEntity = flag;
}

- (void)setMaxNumberOfInstancesToBatchFetch: (unsigned int)size
{
  [self willChange];
  _batchCount = size;
}

@end


@implementation EOEntity (EOModelReferentialIntegrity)

- (BOOL)referencesProperty: (id)property
{
  NSEnumerator *enumerator;
  EORelationship *rel;
  EOAttribute *attr;
  IMP enumNO=NULL;

  enumerator = [[self attributes] objectEnumerator];
  enumNO=NULL;
  while ((attr = GDL2NextObjectWithImpPtr(enumerator,&enumNO)))
    {
      if ([attr isFlattened] && [[attr realAttribute] isEqual: property])
	return YES;
    }

  enumerator = [[self relationships] objectEnumerator];
  enumNO=NULL;
  while ((rel =  GDL2NextObjectWithImpPtr(enumerator,&enumNO)))
    {
      if ([rel referencesProperty: property])
	return YES;
    }

  return NO;
}

- (NSArray *)externalModelsReferenced
{
  NSEmitTODO();  //TODO
  return nil; // TODO
}

@end


@implementation EOEntity (EOModelBeautifier)

- (void)beautifyName
{
  //VERIFY
  NSString *name = [self name];

  [self setName: name];
  
  [[self attributes] makeObjectsPerformSelector: @selector(beautifyName)];
  [[self relationships] makeObjectsPerformSelector: @selector(beautifyName)];
  [[self flattenedAttributes] makeObjectsPerformSelector: @selector(beautifyName)];

//Turbocat:
/*
// Make the entity name and all of its components conform
//     to the Next naming style
//     NAME -> name, FIRST_NAME -> firstName +
     NSArray		*listItems;
     NSString	*newString=[NSString string];
     int			anz,i;
     
   EOFLOGObjectFnStartOrCond2(@"ModelingClasses",@"EOEntity");
 
     // Makes the receiver's name conform to a standard convention. Names that conform to this style are all lower-case except for the initial letter of each embedded word other than the first, which is upper case. Thus, "NAME" becomes "name", and "FIRST_NAME" becomes "firstName".
 
     if ((_name) && ([_name length]>0)) {
         listItems=[_name componentsSeparatedByString:@"_"];
         newString=[newString stringByAppendingString:[[listItems objectAtIndex:0] lowercaseString]];
         anz=[listItems count];
         for (i=1; i < anz; i++) {
             newString=[newString stringByAppendingString:[[listItems objectAtIndex:i] capitalizedString]];
         }
 
 //#warning ergaenzen um alle components (attributes, ...)
 
         // Exception abfangen
         NS_DURING
             [self setName:newString];
         NS_HANDLER
             NSLog(@"%@ in Class: EOEntity , Method: beautifyName >> error : %@",[localException name],[localException reason]);
         NS_ENDHANDLER
     }
 
   EOFLOGObjectFnStopOrCond2(@"ModelingClasses",@"EOEntity");
*/
}

@end

@implementation EOEntity (GDL2Extenstions)
- (NSString *)docComment
{
  return _docComment;
}

- (void)setDocComment: (NSString *)docComment
{
  //OK
  [self willChange];
  ASSIGNCOPY(_docComment, docComment);
  [self _setIsEdited];
}
@end

@implementation EOEntity (EOStoredProcedures)

- (EOStoredProcedure *)storedProcedureForOperation: (NSString *)operation
{
  return [_storedProcedures objectForKey: operation];
}

- (void)setStoredProcedure: (EOStoredProcedure *)storedProcedure
              forOperation: (NSString *)operation
{
  [self willChange];
  [_storedProcedures setObject: storedProcedure
                     forKey: operation];
}

@end

@implementation EOEntity (EOPrimaryKeyGeneration)

- (NSString *)primaryKeyRootName
{
  if (_parent)
    return [_parent externalName];//mirko: [_parent primaryKeyRootName];

  return _externalName;
}

@end

@implementation EOEntity (EOEntityClassDescription)

- (EOClassDescription *)classDescriptionForInstances
{
  EOFLOGObjectFnStart();

//  EOFLOGObjectLevelArgs(@"EOEntity", @"in classDescriptionForInstances");
  EOFLOGObjectLevelArgs(@"EOEntity", @"_classDescription=%@",
			_classDescription);

  if (!_classDescription)
    {
      _classDescription 
	= [[EOEntityClassDescription alloc] initWithEntity: self];

//NO ? NotifyCenter addObserver:EOEntityClassDescription selector:_eoNowMultiThreaded: name:NSWillBecomeMultiThreadedNotification object:nil
    }

  EOFLOGObjectFnStop();

  return _classDescription;
}

@end

/** Useful  private methods made public in GDL2 **/
@implementation EOEntity (EOEntityGDL2Additions)

/** Returns attribute (if any) for path **/
- (EOAttribute*) attributeForPath: (NSString*)path
{
  //OK
  EOAttribute *attribute = nil;
  NSArray *pathElements = nil;
  NSString *part = nil;
  EOEntity *entity = self;
  int i, count = 0;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEntity", @"path=%@", path);

  pathElements = [path componentsSeparatedByString: @"."];
  EOFLOGObjectLevelArgs(@"EOEntity", @"pathElements=%@", pathElements);

  count = [pathElements count];

  for (i = 0; i < count - 1; i++)
    {      
      EORelationship *rel = nil;

      part = [pathElements objectAtIndex: i];
      EOFLOGObjectLevelArgs(@"EOEntity", @"i=%d part=%@", i, part);

      rel = [entity anyRelationshipNamed: part];

      NSAssert2(rel,
		@"no relationship named %@ in entity %@",
		part,
		[entity name]);
      EOFLOGObjectLevelArgs(@"EOEntity", @"i=%d part=%@ rel=%@",
			    i, part, rel);

      entity = [rel destinationEntity];
      EOFLOGObjectLevelArgs(@"EOEntity", @"entity name=%@", [entity name]);
    }

  part = [pathElements lastObject];
  EOFLOGObjectLevelArgs(@"EOEntity", @"part=%@", part);

  attribute = [entity anyAttributeNamed: part];
  EOFLOGObjectLevelArgs(@"EOEntity", @"resulting attribute=%@", attribute);

  EOFLOGObjectFnStop();

  return attribute;
}

/** Returns relationship (if any) for path **/
- (EORelationship*) relationshipForPath: (NSString*)path
{
  //OK ?
  EORelationship *relationship = nil;
  EOEntity *entity = self;
  NSArray *pathElements = nil;
  int i, count;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEntity", @"path=%@", path);

  pathElements = [path componentsSeparatedByString: @"."];
  count = [pathElements count];

  for (i = 0; i < count; i++)
    {
      NSString *part = [pathElements objectAtIndex: i];

      relationship = [entity anyRelationshipNamed: part];

      EOFLOGObjectLevelArgs(@"EOEntity", @"i=%d part=%@ rel=%@",
			    i, part, relationship);

      if (relationship)
        {
          entity = [relationship destinationEntity];
          EOFLOGObjectLevelArgs(@"EOEntity", @"entity name=%@", [entity name]);
        }
      else if (i < (count - 1)) // Not the last part
        {
          NSAssert2(relationship,
                    @"no relationship named %@ in entity %@",
                    part,
                    [entity name]);
        }
    }

  EOFLOGObjectFnStop();

  EOFLOGObjectLevelArgs(@"EOEntity", @"relationship=%@", relationship);

  return relationship;
}

@end

@implementation EOEntity (EOEntityPrivate)

- (BOOL)isPrototypeEntity
{
  [self notImplemented:_cmd];
  return NO; // TODO
}

- (void) setCreateMutableObjects: (BOOL)flag
{
  if (_flags.createsMutableObjects == flag)
    {
      return;
    }
  _flags.createsMutableObjects = flag;

//TODO  NSEmitTODO();

  if (_flags.createsMutableObjects)
    {
      _attributes
	= [[GCMutableArray alloc] initWithArray:AUTORELEASE(_attributes)
				  copyItems:NO];
      _relationships
	= [[GCMutableArray alloc] initWithArray:AUTORELEASE(_relationships)
				  copyItems:NO];
    }
  else
    {
      _attributes
	= [[GCArray alloc] initWithArray:AUTORELEASE(_attributes)
			   copyItems:NO];
      _relationships
	= [[GCArray alloc] initWithArray:AUTORELEASE(_relationships)
			   copyItems:NO];
    }

  NSAssert4(!_attributesToFetch
	    || [_attributesToFetch isKindOfClass: [NSArray class]],
            @"entity %@ attributesToFetch %p is not an NSArray but a %@\n%@",
            [self name],
            _attributesToFetch,
            [_attributesToFetch class],
            _attributesToFetch);
}

- (BOOL) createsMutableObjects
{
  return _flags.createsMutableObjects;
}

- (void)_setModel: (EOModel *)model
{
  EOFLOGObjectLevelArgs(@"EOEntity", @"setModel=%p", model);

  NSAssert4(!_attributesToFetch
	    || [_attributesToFetch isKindOfClass:[NSArray class]],
            @"entity %@ attributesToFetch %p is not an NSArray but a %@\n%@",
            [self name],
            _attributesToFetch,
            [_attributesToFetch class],
            _attributesToFetch);

  NSAssert3((_model == nil || _model == model),
	    @"Attempt to set entity: %@ owned by model: %@ to model: @%.",
	    [self name], [_model name], [model name]);

  _model = model;
}

/* TODO this method should probably be private.
   it doesn't tell the parent we are a subEntity and since
   -addSubEntity: calls it doing so would cause a recursive loop */
- (void)setParentEntity: (EOEntity *)parent
{
  [self willChange]; // TODO: verify
  ASSIGN(_parent, parent);
}

- (NSDictionary *)snapshotForRow: (NSDictionary *)aRow
{
  NSArray *array = [self attributesUsedForLocking];
  int i, n = [array count];
  NSMutableDictionary *dict = GDL2MutableDictionaryWithCapacity(n);
  IMP arrayOAI=NULL;
  IMP dictSOFK=NULL;
  IMP aRowOFK=NULL;
    
  for (i = 0; i < n; i++)
    {
      id key = [(EOAttribute *)GDL2ObjectAtIndexWithImpPtr(array,&arrayOAI,i) 
                               name];

      GDL2SetObjectForKeyWithImpPtr(dict,&dictSOFK,
                                    GDL2ObjectForKeyWithImpPtr(aRow,&aRowOFK,key),
                                    key);
    }

  return dict;
}

- (Class)_classForInstances
{
  EOFLOGObjectFnStart();

  if (!_classForInstances)
    {
      NSString *className = nil;
      Class objectClass = Nil;

      className = [self className];
      EOFLOGObjectLevelArgs(@"EOEntity", @"className=%@", className);

      objectClass = NSClassFromString(className);

      if (!objectClass)
        {
          NSLog(@"Error: No class named %@", className);
        }
      else
        {
          EOFLOGObjectLevelArgs(@"EOEntity", @"objectClass=%@", objectClass);
          ASSIGN(_classForInstances, objectClass);
        }
    }

  EOFLOGObjectFnStop();

  return _classForInstances;
}

- (void)_setInternalInfo: (NSDictionary *)dictionary
{
  //OK
  [self willChange];
  ASSIGN(_internalInfo, dictionary);
  [self _setIsEdited];
}

- (id) globalIDForRow: (NSDictionary*)row
              isFinal: (BOOL)isFinal
{
  EOKeyGlobalID *globalID = nil;
  NSArray *primaryKeyAttributeNames = nil;
  int count = 0;

  NSAssert([row count] > 0, @"Empty Row.");

  primaryKeyAttributeNames = [self primaryKeyAttributeNames];
  count = [primaryKeyAttributeNames count];  
  {
    id keyArray[count];
    int i;
    IMP rowOFK=NULL;
    IMP pkanOAI=NULL;

    memset(keyArray, 0, sizeof(id) * count);

    for (i = 0; i < count; i++)
      {
        keyArray[i] = GDL2ObjectForKeyWithImpPtr(row,&rowOFK,
                                                 GDL2ObjectAtIndexWithImpPtr(primaryKeyAttributeNames,
                                                                             &pkanOAI,i));

        globalID = [EOKeyGlobalID globalIDWithEntityName: [self name]
                                  keys: keyArray
                                  keyCount: count
                                  zone: [self zone]];
      }
  };

  //NSEmitTODO();  //TODO
  //TODO isFinal  ??

  return globalID;
}

-(Class)classForObjectWithGlobalID: (EOKeyGlobalID*)globalID
{
  //near OK
  Class classForInstances = _classForInstances;
  EOFLOGObjectFnStart();

  //TODO:use globalID ??
  if (!classForInstances)
    {
      classForInstances = [self _classForInstances];
    }

  EOFLOGObjectFnStop();

  return _classForInstances;
}

//DESTROY v later because it may be still in use
#define AUTORELEASE_SETNIL(v) { AUTORELEASE(v); v=nil; }
- (void)_setIsEdited
{
  if(_flags.updating)
    return;

  EOFLOGObjectLevelArgs(@"EOEntity", @"START entity name=%@", [self name]);

  NSAssert4(!_attributesToFetch
	    || [_attributesToFetch isKindOfClass: [NSArray class]],
            @"entity %@ attributesToFetch %p is not an NSArray but a %@\n%@",
            [self name],
            _attributesToFetch,
            [_attributesToFetch class],
            _attributesToFetch);

  //Destroy cached ivar
  EOFLOGObjectLevelArgs(@"EOEntity", @"_classPropertyNames: void:%p [%p] %s",
			(void*)nil, (void*)_classPropertyNames,
			(_classPropertyNames ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_classPropertyNames);

  EOFLOGObjectLevelArgs(@"EOEntity", @"_primaryKeyAttributeNames: %p %s",
			(void*)_primaryKeyAttributeNames,
			(_primaryKeyAttributeNames ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_primaryKeyAttributeNames);

  EOFLOGObjectLevelArgs(@"EOEntity", @"_classPropertyAttributeNames: %p %s",
			_classPropertyAttributeNames,
			(_classPropertyAttributeNames ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_classPropertyAttributeNames);

  EOFLOGObjectLevelArgs(@"EOEntity", @"_classPropertyToOneRelationshipNames: %p %s",
			_classPropertyToOneRelationshipNames,
			(_classPropertyToOneRelationshipNames ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_classPropertyToOneRelationshipNames);

  EOFLOGObjectLevelArgs(@"EOEntity", @"_classPropertyToManyRelationshipNames: %p %s",
			_classPropertyToManyRelationshipNames,
			(_classPropertyToManyRelationshipNames ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_classPropertyToManyRelationshipNames);

  EOFLOGObjectLevelArgs(@"EOEntity", @"_attributesToFetch: %p %s",
			_attributesToFetch,
			(_attributesToFetch ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_attributesToFetch);

  EOFLOGObjectLevelArgs(@"EOEntity", @"_dbSnapshotKeys: %p %s",
			_dbSnapshotKeys, (_dbSnapshotKeys ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_dbSnapshotKeys);

  EOFLOGObjectLevelArgs(@"EOEntity", @"_attributesToSave: %p %s",
			_attributesToSave, (_attributesToSave ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_attributesToSave);

  EOFLOGObjectLevelArgs(@"EOEntity", @"_propertiesToFault: %p %s",
			_propertiesToFault, (_propertiesToFault ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_propertiesToFault);

  EOFLOGObjectLevelArgs(@"EOEntity", @"_adaptorDictionaryInitializer: %p %s",
			_adaptorDictionaryInitializer,
			(_adaptorDictionaryInitializer ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_adaptorDictionaryInitializer);

  EOFLOGObjectLevelArgs(@"EOEntity", @"_snapshotDictionaryInitializer: %p %s",
			_snapshotDictionaryInitializer,
			(_snapshotDictionaryInitializer ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_snapshotDictionaryInitializer);

  EOFLOGObjectLevelArgs(@"EOEntity",@"_primaryKeyDictionaryInitializer: %p %s",
			_primaryKeyDictionaryInitializer,
			(_primaryKeyDictionaryInitializer ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_primaryKeyDictionaryInitializer);

  EOFLOGObjectLevelArgs(@"EOEntity",@"_propertyDictionaryInitializer: %p %s",
			_propertyDictionaryInitializer,
			(_propertyDictionaryInitializer ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_propertyDictionaryInitializer);

  EOFLOGObjectLevelArgs(@"EOEntity",@"_instanceDictionaryInitializer: %p %s",
			_instanceDictionaryInitializer,
			(_instanceDictionaryInitializer ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_instanceDictionaryInitializer);

  //TODO call _flushCache on each attr
  NSAssert4(!_attributesToFetch
	    || [_attributesToFetch isKindOfClass: [NSArray class]],
            @"entity %@ attributesToFetch %p is not an NSArray but a %@\n%@",
            [self name],
            _attributesToFetch,
            [_attributesToFetch class],
            _attributesToFetch);

  EOFLOGObjectLevelArgs(@"EOEntity", @"STOP%s", "");
}

/** Returns attributes by name (only attributes, not relationships) **/
- (NSDictionary*)attributesByName
{
  EOFLOGObjectFnStart();

  if (_attributesByName)
    {
      EOFLOGObjectLevelArgs(@"EOEntity", @"_attributesByName [%p] (%@)",
			    _attributesByName,
			    [_attributesByName class]);
      NSAssert2((!_attributesByName
		 || [_attributesByName isKindOfClass: [NSDictionary class]]),
                @"_attributesByName is not a NSDictionary but a %@. _attributesByName [%p]",
                [_attributesByName class],
                _attributesByName);
    }
  else
    {
      EOFLOGObjectLevel(@"EOEntity", @"Will Rebuild attributes");

      [self attributes]; //To rebuild

      EOFLOGObjectLevelArgs(@"EOEntity", @"_attributesByName [%p] (%@)",
			    _attributesByName,
			    [_attributesByName class]);
      NSAssert2((!_attributesByName
		 || [_attributesByName isKindOfClass:[NSDictionary class]]),
                @"_attributesByName is not a NSDictionary but a %@. _attributesByName [%p]",
                [_attributesByName class],
                _attributesByName);
    }

  EOFLOGObjectFnStop();

  return _attributesByName;
}

- (NSDictionary*)relationshipsByName
{
  if (!_relationshipsByName)
    {
      [self relationships]; //To rebuild
    }
  return _relationshipsByName;
}

- (NSArray*) _allFetchSpecifications
{
  //OK
  NSDictionary *fetchSpecificationDictionary =
    [self _fetchSpecificationDictionary];
  NSArray *fetchSpecValues = [fetchSpecificationDictionary allValues];

  return fetchSpecValues;
}

- (NSDictionary*) _fetchSpecificationDictionary
{
  //OK
  return _fetchSpecificationDictionary;
}

- (void) _loadEntity
{
  //TODO
  [self notImplemented: _cmd];
}

- (id) parentRelationship
{
  //TODO
  return [self notImplemented: _cmd];
}

- (int) _numberOfRelationships
{
  //OK
  return [[self relationships] count];
}

- (BOOL) _hasReadOnlyAttributes
{
  //OK
  BOOL hasReadOnlyAttributes = NO;
  NSArray *attributes = [self attributes];
  int i, count=[attributes count];

  for (i = 0; !hasReadOnlyAttributes && i < count; i++)
    hasReadOnlyAttributes = [[attributes objectAtIndex: i] isReadOnly];

  return hasReadOnlyAttributes;
}

- (NSArray*) writableDBSnapshotKeys
{
  //OK
  NSArray *writableDBSnapshotKeys=nil;

  if (![self isReadOnly])
    {
      NSArray *attributesToFetch = [self _attributesToFetch];
      int i, count = [attributesToFetch count];
      IMP atfOAI=NULL;
      IMP sAO=NULL;
      NSMutableArray* tmpArray=GDL2MutableArrayWithCapacity(count);

      NSAssert3(!attributesToFetch
		|| [attributesToFetch isKindOfClass: [NSArray class]],
                @"entity %@ attributesToFetch is not an NSArray but a %@\n%@",
                [self name],
                [attributesToFetch class],
                attributesToFetch);

      for (i = 0; i < count; i++)
        {
          EOAttribute *attribute = GDL2ObjectAtIndexWithImpPtr(attributesToFetch,&atfOAI,i);

          if (![attribute isReadOnly])
            GDL2AddObjectWithImpPtr(tmpArray,&sAO,[attribute name]);
        }
      writableDBSnapshotKeys=tmpArray;
    }
  else
    writableDBSnapshotKeys=GDL2Array();

  return writableDBSnapshotKeys;
}

- (NSArray*) rootAttributesUsedForLocking
{
  //OK ?
  NSArray *rootAttributesUsedForLocking = nil;
  NSArray *attributesUsedForLocking = [self attributesUsedForLocking];
  int count = [attributesUsedForLocking count];

  if (count>0)
    {
      int i=0;
      NSMutableArray *tmpArray = GDL2MutableArrayWithCapacity(count);
      IMP auflOAI=NULL;
      IMP tAO=NULL;

      for (i = 0; i < count; i++)
        {
          EOAttribute *attribute = GDL2ObjectAtIndexWithImpPtr(attributesUsedForLocking,
                                                               &auflOAI,i);
          if (![attribute isDerived])
            GDL2AddObjectWithImpPtr(tmpArray,&tAO,attribute);
        }
      rootAttributesUsedForLocking=tmpArray;
    }
  else
    rootAttributesUsedForLocking=GDL2Array();

  return rootAttributesUsedForLocking;
}

- (BOOL) isSubEntityOf: (id)param0
{
  //TODO
  [self notImplemented: _cmd];
  return NO;
}

- (id) initObject: (id)param0
   editingContext: (id)param1
         globalID: (id)param2
{
  //TODO
  return [self notImplemented: _cmd];
}

- (id) allocBiggestObjectWithZone: (NSZone*)zone
{
  //TODO
  return [self notImplemented: _cmd];
}

- (Class) _biggestClass
{
  //OK
  Class biggestClass = Nil;

  biggestClass = [self classForObjectWithGlobalID: nil];

  return biggestClass;
}

- (NSArray*) relationshipsPlist
{
  //OK
  NSMutableArray *relsPlist;

  if (_flags.relationshipsIsLazy)
    {
      relsPlist = _relationships;
    }
  else
    {
      NSArray *relationships;
      int relCount;

      relsPlist = [NSMutableArray array];
      relationships = [self relationships];
      relCount = [relationships count];

      if (relCount > 0)
        {
          int i;

          for (i = 0; i < relCount; i++)
            {
              NSMutableDictionary *relPlist = [NSMutableDictionary dictionary];
              EORelationship *rel = [relationships objectAtIndex: i];

              [rel encodeIntoPropertyList: relPlist];
              [relsPlist addObject: relPlist];
            }
        }
    }

  return relsPlist;
}

- (id) rootParent
{
  id prevParent = self;
  id parent = self;

  while (parent)
  {
    prevParent = parent;
    parent = [prevParent parentEntity];
  }

  return prevParent;
}

- (void) _setParent: (id)param0
{
  //TODO
  [self notImplemented: _cmd];
}

- (NSArray*) _hiddenRelationships
{
  //OK
  if (!_hiddenRelationships)
    _hiddenRelationships = [NSMutableArray new];

  return _hiddenRelationships;
}

- (NSArray*) _propertyNames
{
  //OK
  NSMutableArray *propertyNames = nil;
  NSArray *attributes = [self attributes];
  NSArray *attributeNames = [attributes resultsOfPerformingSelector:
					  @selector(name)];
  NSArray *relationships = [self relationships];
  NSArray *relationshipNames = [relationships resultsOfPerformingSelector:
						@selector(name)];

  propertyNames = [NSMutableArray arrayWithArray: attributeNames];
  [propertyNames addObjectsFromArray: relationshipNames];

  return propertyNames;
}

- (id) _flattenAttribute: (id)param0
        relationshipPath: (id)param1
       currentAttributes: (id)param2
{
  //TODO
  return [self notImplemented: _cmd];
}

- (NSString*) snapshotKeyForAttributeName: (NSString*)attributeName
{
  NSString *attName = [self _flattenedAttNameToSnapshotKeyMapping];

  if (attName)
    {
      NSEmitTODO(); //TODO
      [self notImplemented: _cmd];
    }
  else
      attName = attributeName; //TODO-VERIFY

  return attName;
}

- (id) _flattenedAttNameToSnapshotKeyMapping
{
  //  NSArray *attributesToSave = [self _attributesToSave];

  //NSEmitTODO(); //TODO

  return nil; //[self notImplemented:_cmd]; //TODO
}

- (EOMKKDSubsetMapping*) _snapshotToAdaptorRowSubsetMapping
{
  if (!_snapshotToAdaptorRowSubsetMapping)
    {
      EOMKKDInitializer *snapshotDictionaryInitializer =
	[self _snapshotDictionaryInitializer];
      EOMKKDInitializer *adaptorDictionaryInitializer =
	[self _adaptorDictionaryInitializer];
      EOMKKDSubsetMapping *subsetMapping =
	[snapshotDictionaryInitializer 
	  subsetMappingForSourceDictionaryInitializer: adaptorDictionaryInitializer];

      ASSIGN(_snapshotToAdaptorRowSubsetMapping,subsetMapping);
    }

  return  _snapshotToAdaptorRowSubsetMapping;
}

- (EOMutableKnownKeyDictionary*) _dictionaryForPrimaryKey
{
  //OK
  EOMKKDInitializer *primaryKeyDictionaryInitializer =
    [self _primaryKeyDictionaryInitializer];
  EOMutableKnownKeyDictionary *dictionaryForPrimaryKey =
    [EOMutableKnownKeyDictionary dictionaryWithInitializer:
				   primaryKeyDictionaryInitializer];

  return dictionaryForPrimaryKey;
}

- (EOMutableKnownKeyDictionary*) _dictionaryForProperties
{
  //OK
  EOMKKDInitializer *propertyDictionaryInitializer = nil;
  EOMutableKnownKeyDictionary *dictionaryForProperties = nil;

  EOFLOGObjectFnStart();

  propertyDictionaryInitializer = [self _propertyDictionaryInitializer];

  EOFLOGObjectLevelArgs(@"EOEntity", @"propertyDictionaryInitializer=%@",
			propertyDictionaryInitializer);

  dictionaryForProperties = [EOMutableKnownKeyDictionary
			      dictionaryWithInitializer:
				propertyDictionaryInitializer];

  EOFLOGObjectLevelArgs(@"EOEntity", @"dictionaryForProperties=%@",
			dictionaryForProperties);

  EOFLOGObjectFnStop();

  return dictionaryForProperties;
}

/** returns a new autoreleased mutable dictionary to store properties 
returns nil if there's no key in the instanceDictionaryInitializer
**/
- (EOMutableKnownKeyDictionary*) _dictionaryForInstanceProperties
{
  //OK
  EOMKKDInitializer *instanceDictionaryInitializer = nil;
  EOMutableKnownKeyDictionary *dictionaryForProperties = nil;

  EOFLOGObjectFnStart();

  instanceDictionaryInitializer = [self _instanceDictionaryInitializer];

  EOFLOGObjectLevelArgs(@"EOEntity", @"instanceDictionaryInitializer=%@",
			instanceDictionaryInitializer);

  // No need to build the dictionary if there's no key.
  // The only drawback I see is if someone use extraData feature of MKK dictionary
  if ([instanceDictionaryInitializer count]>0)
    {      
      dictionaryForProperties = [EOMutableKnownKeyDictionary
                                  dictionaryWithInitializer:
                                    instanceDictionaryInitializer];
    }
  EOFLOGObjectLevelArgs(@"EOEntity", @"dictionaryForProperties=%@",
			dictionaryForProperties);

  EOFLOGObjectFnStop();

  return dictionaryForProperties;
}

- (NSArray*) _relationshipsToFaultForRow: (NSDictionary*)row
{
  NSMutableArray *rels = [NSMutableArray array];
  NSArray *classProperties = [self classProperties];
  int i, count = [classProperties count];

  for (i = 0; i < count; i++)
    {
      EORelationship *classProperty = [classProperties objectAtIndex: i];

      if ([classProperty isKindOfClass: [EORelationship class]])
        {
          EORelationship *relsubs = [classProperty
				      _substitutionRelationshipForRow: row];

          [rels addObject: relsubs];
        }
    }

  return rels;
}

- (NSArray*) _classPropertyAttributes
{
  //OK
  //IMPROVE We can improve this by caching the result....

  NSArray *classPropertyAttributes = nil;
  //Get classProperties (EOAttributes + EORelationships)
  NSArray *classProperties = [self classProperties];
  int count = [classProperties count];

  if (count>0)
    {
      int i=0;
      NSMutableArray *tmpArray = GDL2MutableArrayWithCapacity(count);
      IMP cpOAI=NULL;
      IMP tAO=NULL;

      for (i = 0; i < count; i++)
        {
          id object = GDL2ObjectAtIndexWithImpPtr(classProperties,&cpOAI,i);
          
          if ([object isKindOfClass: GDL2EOAttributeClass])
            GDL2AddObjectWithImpPtr(tmpArray,&tAO,object);
        }
      classPropertyAttributes = tmpArray;
    }
  else
    classPropertyAttributes=GDL2Array();

  return classPropertyAttributes;
}

- (NSArray*) _attributesToSave
{
  //Near OK
  EOFLOGObjectLevelArgs(@"EOEntity",
			@"START Entity _attributesToSave entityname=%@",
			[self name]);

  if (!_attributesToSave)
    {
      NSArray *attributesToFetch = [self _attributesToFetch];
      int i, count = [attributesToFetch count];
      NSMutableArray *attributesToSave = [GCMutableArray arrayWithCapacity:count];

      NSAssert3(!attributesToFetch
		|| [attributesToFetch isKindOfClass: [NSArray class]],
                @"entity %@ attributesToFetch is not an NSArray but a %@\n%@",
                [self name],
                [_attributesToFetch class],
                _attributesToFetch);

      for (i = 0; i < count; i++)
        {
          EOAttribute *attribute = [attributesToFetch objectAtIndex: i];
          BOOL isFlattened = [attribute isFlattened]; 

          if (!isFlattened)
            [attributesToSave addObject: attribute];
        }
      ASSIGN(_attributesToSave, attributesToSave);
    }

  EOFLOGObjectLevelArgs(@"EOEntity", @"STOP Entity _attributesToSave entityname=%@ attrs:%@",
			[self name], _attributesToSave);

  return _attributesToSave;
}

//sorted by name attributes
- (NSArray*) _attributesToFetch
{
  //Seems OK
  EOFLOGObjectLevelArgs(@"EOEntity",
			@"START Entity _attributesToFetch entityname=%@",
			[self name]);
  EOFLOGObjectLevelArgs(@"EOEntity", @"AttributesToFetch:%p",
			_attributesToFetch);
  EOFLOGObjectLevelArgs(@"EOEntity", @"AttributesToFetch:%@",
			_attributesToFetch);

  NSAssert2(!_attributesToFetch
	    || [_attributesToFetch isKindOfClass: [NSArray class]],
            @"entity %@ attributesToFetch is not an NSArray but a %@",
            [self name],
            [_attributesToFetch class]);

  if (!_attributesToFetch)
    {
      NSMutableDictionary *attributesDict = [NSMutableDictionary dictionary];
      NS_DURING
        {
          int iArray = 0;
          NSArray *arrays[] = { [self attributesUsedForLocking],
                                [self primaryKeyAttributes],
                                [self classProperties],
                                [self relationships] };

          _attributesToFetch = RETAIN([GCMutableArray array]);
          
          EOFLOGObjectLevelArgs(@"EOEntity", @"Entity %@ - _attributesToFetch %p [RC=%d]:%@",
                                [self name],
                                _attributesToFetch,
                                [_attributesToFetch retainCount],
                                _attributesToFetch);
          
          for (iArray = 0; iArray < 4; iArray++)
            {
              int i, count = 0;
              
              EOFLOGObjectLevelArgs(@"EOEntity", @"Entity %@ - arrays[iArray]:%@",
                                    [self name], arrays[iArray]);

              count = [arrays[iArray] count];
              
              for (i = 0; i < count; i++)
                {
                  id property = [arrays[iArray] objectAtIndex: i];
                  NSString *propertyName = [(EOAttribute*)property name];
                  
                  //VERIFY
                  EOFLOGObjectLevelArgs(@"EOEntity",
                                        @"propertyName=%@ - property=%@",
                                        propertyName, property);
                  
                  if ([property isKindOfClass: GDL2EOAttributeClass])
                    {
		      EOAttribute *attribute = property;

                      if ([attribute isFlattened])
                        {
                          attribute = [[attribute _definitionArray]
					objectAtIndex: 0];
                          propertyName = [attribute name];
                        }
                    }
                  
                  if ([property isKindOfClass: [EORelationship class]])
                    {
                      [self _addAttributesToFetchForRelationshipPath:
                              [(EORelationship*)property relationshipPath]
                        atts: attributesDict];
                    }
                  else if ([property isKindOfClass: GDL2EOAttributeClass])
                    {
                      [attributesDict setObject: property
                                      forKey: propertyName];
                    }
                  else
                    {
                      NSEmitTODO();  //TODO
                    }
                }
            }
        }
      NS_HANDLER
        {
          NSDebugMLog(@"Exception: %@",localException);
          [localException raise];
        }
      NS_ENDHANDLER;
      NS_DURING
        {
          NSDebugMLog(@"Attributes to fetch classes %@",
                      [_attributesToFetch resultsOfPerformingSelector:
                                            @selector(class)]);
          
          [_attributesToFetch addObjectsFromArray: [attributesDict allValues]];
          
          NSDebugMLog(@"Attributes to fetch classes %@",
                      [_attributesToFetch resultsOfPerformingSelector:
                                            @selector(class)]);
          
          [_attributesToFetch sortUsingSelector: @selector(eoCompareOnName:)]; //Very important to have always the same order.
        }
      NS_HANDLER
        {
          NSDebugMLog(@"Exception: %@",localException);
          [localException raise];
        }
      NS_ENDHANDLER;
    }

  NSAssert3(!_attributesToFetch
	    || [_attributesToFetch isKindOfClass: [NSArray class]],
            @"Entity %@: _attributesToFetch is not an NSArray but a %@\n%@",
            [self name],
            [_attributesToFetch class],
            _attributesToFetch);

  EOFLOGObjectLevelArgs(@"EOEntity", @"Stop Entity %@ - _attributesToFetch %p [RC=%d]:%@",
			[self name],
			_attributesToFetch,
			[_attributesToFetch retainCount],
			_attributesToFetch);

  return _attributesToFetch;
}

- (EOMKKDInitializer*) _adaptorDictionaryInitializer
{
  //OK
  EOFLOGObjectLevelArgs(@"EOEntity", @"Start _adaptorDictionaryInitializer=%@",
			_adaptorDictionaryInitializer);

  if (!_adaptorDictionaryInitializer)
    {
      NSArray *attributesToFetch = [self _attributesToFetch];
      NSArray *attributeToFetchNames = [attributesToFetch
					 resultsOfPerformingSelector:
					   @selector(name)];

      EOFLOGObjectLevelArgs(@"EOEntity", @"attributeToFetchNames=%@",
			    attributeToFetchNames);

      NSAssert3(!attributesToFetch
		|| [attributesToFetch isKindOfClass: [NSArray class]],
                @"entity %@ attributesToFetch is not an NSArray but a %@\n%@",
                [self name],
                [attributesToFetch class],
                attributesToFetch);
      NSAssert1([attributesToFetch count] > 0,
		@"No Attributes to fetch in entity %@", [self name]);
      NSAssert1([attributeToFetchNames count] > 0,
		@"No Attribute names to fetch in entity %@", [self name]);

      EOFLOGObjectLevelArgs(@"EOEntity", @"entity named %@: attributeToFetchNames=%@",
			    [self name],
			    attributeToFetchNames);

      ASSIGN(_adaptorDictionaryInitializer,
	     [EOMutableKnownKeyDictionary initializerFromKeyArray:
					    attributeToFetchNames]);

      EOFLOGObjectLevelArgs(@"EOEntity", @"entity named %@ _adaptorDictionaryInitializer=%@",
			    [self name],
			    _adaptorDictionaryInitializer);
    }

  EOFLOGObjectLevelArgs(@"EOEntity", @"Stop _adaptorDictionaryInitializer=%p",
			_adaptorDictionaryInitializer);
  EOFLOGObjectLevelArgs(@"EOEntity", @"Stop _adaptorDictionaryInitializer=%@",
			_adaptorDictionaryInitializer);

  return _adaptorDictionaryInitializer;
}

- (EOMKKDInitializer*) _snapshotDictionaryInitializer
{
  if (!_snapshotDictionaryInitializer)
    {
      NSArray *dbSnapshotKeys = [self dbSnapshotKeys];

      ASSIGN(_snapshotDictionaryInitializer,
	     [EOMutableKnownKeyDictionary initializerFromKeyArray:
					    dbSnapshotKeys]);
    }

  return _snapshotDictionaryInitializer;
}

- (EOMKKDInitializer*) _primaryKeyDictionaryInitializer
{
  //OK
  if (!_primaryKeyDictionaryInitializer)
    {
      NSArray *primaryKeyAttributeNames = [self primaryKeyAttributeNames];

      NSAssert1([primaryKeyAttributeNames count] > 0,
		@"No primaryKeyAttributeNames in entity %@", [self name]);

      EOFLOGObjectLevelArgs(@"EOEntity", @"entity named %@: primaryKeyAttributeNames=%@",
			    [self name],
			    primaryKeyAttributeNames);

      _primaryKeyDictionaryInitializer = [EOMKKDInitializer
					   newWithKeyArray:
					     primaryKeyAttributeNames];

      EOFLOGObjectLevelArgs(@"EOEntity", @"entity named %@: _primaryKeyDictionaryInitializer=%@",
			    [self name],
			    _primaryKeyDictionaryInitializer);
    }

  return _primaryKeyDictionaryInitializer;
}

- (EOMKKDInitializer*) _propertyDictionaryInitializer
{
  //OK
  // If not already built, built it
  if (!_propertyDictionaryInitializer)
    {
      // Get class properties (EOAttributes + EORelationships)
      NSArray *classProperties = [self classProperties];
      NSArray *classPropertyNames =
	[classProperties resultsOfPerformingSelector: @selector(name)];

      EOFLOGObjectLevelArgs(@"EOEntity", @"entity %@ classPropertyNames=%@",
			    [self name], classPropertyNames);

      NSAssert1([classProperties count] > 0,
		@"No classProperties in entity %@", [self name]);
      NSAssert1([classPropertyNames count] > 0,
		@"No classPropertyNames in entity %@", [self name]);

      //Build the multiple known key initializer
      _propertyDictionaryInitializer = [EOMKKDInitializer
					 newWithKeyArray: classPropertyNames];
    }

  return _propertyDictionaryInitializer;
}

- (EOMKKDInitializer*) _instanceDictionaryInitializer
{
  //OK
  // If not already built, built it
  if (!_instanceDictionaryInitializer)
    {
      // Get class properties (EOAttributes + EORelationships)
      NSArray *classProperties = [self classProperties];
      NSArray* excludedPropertyNames=nil;
      NSArray *classPropertyNames = nil;
      Class classForInstances = [self _classForInstances];

      classPropertyNames = [classProperties resultsOfPerformingSelector: @selector(name)];

      EOFLOGObjectLevelArgs(@"EOEntity", @"entity %@ classPropertyNames=%@",
                            [self name], classPropertyNames);

      excludedPropertyNames = [classForInstances 
                                _instanceDictionaryInitializerExcludedPropertyNames];

      EOFLOGObjectLevelArgs(@"EOEntity", @"entity %@ excludedPropertyNames=%@",
                            [self name], excludedPropertyNames);

      if ([excludedPropertyNames count]>0)
        {
          NSMutableArray* mutableClassPropertyNames=[classPropertyNames mutableCopy];
          [mutableClassPropertyNames removeObjectsInArray:excludedPropertyNames];
          classPropertyNames=AUTORELEASE(mutableClassPropertyNames);
        }
      
      EOFLOGObjectLevelArgs(@"EOEntity", @"entity %@ classPropertyNames=%@",
                            [self name], classPropertyNames);
      
      NSAssert1([classProperties count] > 0,
                @"No classProperties in entity %@", [self name]);
      NSAssert1([classPropertyNames count] > 0,
                @"No classPropertyNames in entity %@", [self name]);
      
      //Build the multiple known key initializer
      _instanceDictionaryInitializer = [EOMKKDInitializer
                                         newWithKeyArray: classPropertyNames];

      EOFLOGObjectLevelArgs(@"EOEntity", @"_instanceDictionaryInitializer=%@",
                            _instanceDictionaryInitializer);
    }

  return _instanceDictionaryInitializer;
}

@end

@implementation EOEntity (EOEntityRelationshipPrivate)

- (EORelationship*) _inverseRelationshipPathForPath: (NSString*)path
{
  //TODO
  return [self notImplemented: _cmd];
}

- (NSDictionary*) _keyMapForIdenticalKeyRelationshipPath: (NSString*)path
{
  NSDictionary *keyMap = nil;
  EORelationship *rel;
  NSMutableArray *sourceAttributeNames = [NSMutableArray array];
  NSMutableArray *destinationAttributeNames = [NSMutableArray array];
  NSArray *joins;
  int count = 0;

  //use path,not only one element ?
  rel = [self relationshipNamed: path];
  joins = [rel joins];
  count = [joins count];

  if (count>0)
    {
      int i=0;
      IMP joinsOAI=NULL;
      IMP sanAO=NULL;
      IMP danAO=NULL;

      for (i = 0; i < count; i++)
        {
          EOJoin *join = GDL2ObjectAtIndexWithImpPtr(joins,&joinsOAI,i);
          EOAttribute *sourceAttribute = [join sourceAttribute];
          EOAttribute *destinationAttribute =
            [self _mapAttribute:sourceAttribute 
                  toDestinationAttributeInLastComponentOfRelationshipPath: path];
          
          GDL2AddObjectWithImpPtr(sourceAttributeNames,&sanAO,
                                  [sourceAttribute name]);

          GDL2AddObjectWithImpPtr(destinationAttributeNames,&danAO,
                                  [destinationAttribute name]);
        }
    };

  keyMap = [NSDictionary dictionaryWithObjectsAndKeys:
			   sourceAttributeNames, @"sourceKeys",
			 destinationAttributeNames, @"destinationKeys",
			 nil, nil];
  //return something like {destinationKeys = (code); sourceKeys = (languageCode); }

  return keyMap;
}

- (EOAttribute*) _mapAttribute: (EOAttribute*)attribute
toDestinationAttributeInLastComponentOfRelationshipPath: (NSString*)path
{
  NSArray *components = nil;
  EORelationship *rel = nil;
  NSArray *sourceAttributes = nil;
  NSArray *destinationAttributes = nil;
  EOEntity *destinationEntity = nil;

  NSAssert(attribute, @"No attribute");
  NSAssert(path, @"No path");
  NSAssert([path length] > 0, @"Empty path");

  components = [path componentsSeparatedByString: @"."];
  NSAssert([components count] > 0, @"Empty components array");

  rel = [self relationshipNamed: [components lastObject]];
  sourceAttributes = [rel sourceAttributes];
  destinationAttributes = [rel destinationAttributes];
  destinationEntity = [rel destinationEntity];

  NSEmitTODO();  //TODO

  return [self notImplemented: _cmd];
}

- (BOOL) _relationshipPathIsToMany: (NSString*)relPath
{
  //Seems OK
  BOOL isToMany = NO;
  NSArray *parts = [relPath componentsSeparatedByString: @"."];
  EOEntity *entity = self;
  int i, count = [parts count];

  for (i = 0 ; !isToMany && i < count; i++) //VERIFY Stop when finding the 1st isToMany ?
    {
      EORelationship *rel = [entity relationshipNamed:
				      [parts objectAtIndex: i]];

      isToMany = [rel isToMany];

      if (!isToMany)
        entity = [rel destinationEntity];
    }

  return isToMany;
}

- (BOOL) _relationshipPathHasIdenticalKeys: (id)param0
{
  [self notImplemented: _cmd];
  return NO;
}

- (NSDictionary *)_keyMapForRelationshipPath: (NSString *)path
{
  //Ayers: Review
  //NearOK
  NSMutableArray *sourceKeys = [NSMutableArray array];
  NSMutableArray *destinationKeys = [NSMutableArray array];
  //NSArray *attributesToFetch = [self _attributesToFetch]; //Use It !!
  EORelationship *relationship = [self anyRelationshipNamed: path]; //?? iterate on path ? //TODO

  NSEmitTODO();  //TODO

  if (relationship)
    {
      NSArray *joins = [relationship joins];
      int count = [joins count];

      if (count>0)
        {
          int i=0;
          IMP joinsOAI=NULL;
          IMP skAO=NULL;
          IMP dkAO=NULL;
          
          for(i = 0; i < count; i++)
            {
              EOJoin *join = GDL2ObjectAtIndexWithImpPtr(joins,&joinsOAI,i);
              EOAttribute *sourceAttribute = [join sourceAttribute];
              EOAttribute *destinationAttribute = [join destinationAttribute];
              
              GDL2AddObjectWithImpPtr(sourceKeys,&skAO,[sourceAttribute name]);
              GDL2AddObjectWithImpPtr(destinationKeys,&dkAO,[destinationAttribute name]);
            }
        };
    }

  return [NSDictionary dictionaryWithObjectsAndKeys:
                         sourceKeys, @"sourceKeys",
                       destinationKeys, @"destinationKeys",
                       nil];
//{destinationKeys = (code); sourceKeys = (countryCode); }
}

@end

@implementation EOEntity (EOEntitySQLExpression)

- (NSString*) valueForSQLExpression: (EOSQLExpression*)sqlExpression
{
  return [self notImplemented: _cmd]; //TODO
}

+ (NSString*) valueForSQLExpression: (EOSQLExpression*)sqlExpression
{
  return [self notImplemented: _cmd]; //TODO
}

@end

@implementation EOEntity (MethodSet11)

- (NSException *)validateObjectForDelete: (id)object
{
//OK ??
  NSArray *relationships = nil;
  NSEnumerator *relEnum = nil;
  EORelationship *relationship = nil;
  NSMutableArray *expArray = nil;

  relationships = [self relationships];
  relEnum = [relationships objectEnumerator];

  while ((relationship = [relEnum nextObject]))
    {
//classproperties

//rien pour nullify
      if ([relationship deleteRule] == EODeleteRuleDeny)
        {
          if (!expArray)
            expArray = [NSMutableArray arrayWithCapacity:5];

          [expArray addObject:
                      [NSException validationExceptionWithFormat:
                                     @"delete operation for relationship key %@ refused",
                                   [relationship name]]];
        }
    }

  if (expArray)
    return [NSException aggregateExceptionWithExceptions:expArray];
  else
    return nil;
}

/** Retain an array of name of all EOAttributes **/
- (NSArray*) classPropertyAttributeNames
{
  //Should be OK
  if (!_classPropertyAttributeNames)
    {
      int i=0;
      NSArray *classProperties = [self classProperties];
      int count = [classProperties count];

      _classPropertyAttributeNames = [NSMutableArray new]; //or GC ?
      
      for (i = 0; i < count; i++)
        {
          EOAttribute *property = [classProperties objectAtIndex: i];
          
          if ([property isKindOfClass: GDL2EOAttributeClass])
            [(NSMutableArray*)_classPropertyAttributeNames
                              addObject: [property name]];
        };

      EOFLOGObjectLevelArgs(@"EOEntity", @"_classPropertyAttributeNames=%@",
			    _classPropertyAttributeNames);
    }

  return _classPropertyAttributeNames;
}

- (NSArray*) classPropertyToManyRelationshipNames
{
  //Should be OK
  if (!_classPropertyToManyRelationshipNames)
    {
      NSArray *classProperties = [self classProperties];
      int i, count = [classProperties count];
      Class relClass = [EORelationship class];

      _classPropertyToManyRelationshipNames = [NSMutableArray new]; //or GC ?

      for (i = 0; i < count; i++)
        {
          EORelationship *property = [classProperties objectAtIndex: i];

          if ([property isKindOfClass: relClass]
	      && [property isToMany])
            [(NSMutableArray*)_classPropertyToManyRelationshipNames
			      addObject: [property name]];
        }
    }

  return _classPropertyToManyRelationshipNames;
}

- (NSArray*) classPropertyToOneRelationshipNames
{
  //Should be OK
  if (!_classPropertyToOneRelationshipNames)
    {
      NSArray *classProperties = [self classProperties];
      int i, count = [classProperties count];
      Class relClass = [EORelationship class];

      _classPropertyToOneRelationshipNames = [NSMutableArray new]; //or GC ?

      for (i = 0; i <count; i++)
        {
          EORelationship *property = [classProperties objectAtIndex: i];

          if ([property isKindOfClass: relClass]
	      && ![property isToMany])
            [(NSMutableArray*)_classPropertyToOneRelationshipNames
			      addObject: [property name]];
        }
    }

  return _classPropertyToOneRelationshipNames;
}

- (id) qualifierForDBSnapshot:(id)param0
{
  return [self notImplemented: _cmd]; //TODO
}

- (void) _addAttributesToFetchForRelationshipPath: (NSString*)relPath
                                             atts: (NSMutableDictionary*)attributes
{
  NSArray *parts = nil;
  EORelationship *rel = nil;

  NSAssert([relPath length] > 0, @"Empty relationship path");

  //Verify when multi part path and not _relationshipPathIsToMany:path
  parts = [relPath componentsSeparatedByString: @"."];
  rel = [self relationshipNamed: [parts objectAtIndex: 0]];

  if (!rel)
    {
      NSEmitTODO();  //TODO
      //TODO
    }
  else
    {
      NSArray *joins = [rel joins];
      int count = [joins count];

      if (count>0)
        {
          int i=0;
          IMP joinsOAI=NULL;
          IMP attributesSOFK=NULL;

          for (i = 0; i < count; i++)
            {
              EOJoin *join = GDL2ObjectAtIndexWithImpPtr(joins,&joinsOAI,i);
              EOAttribute *attribute = [join sourceAttribute];
              
              GDL2SetObjectForKeyWithImpPtr(attributes,&attributesSOFK,
                                            attribute,[attribute name]);
            }
        };
    }
}

- (NSArray*) dbSnapshotKeys
{
  //OK
  EOFLOGObjectFnStart();

  if (!_dbSnapshotKeys)
    {
      NSArray *attributesToFetch = [self _attributesToFetch];

      EOFLOGObjectLevelArgs(@"EOEntity", @"attributesToFetch=%@",
			    attributesToFetch);
      NSAssert3(!attributesToFetch
		|| [attributesToFetch isKindOfClass: [NSArray class]],
                @"entity %@ attributesToFetch is not an NSArray but a %@\n%@",
                [self name],
                [attributesToFetch class],
                attributesToFetch);

      ASSIGN(_dbSnapshotKeys,
             [GCArray arrayWithArray: [attributesToFetch
					resultsOfPerformingSelector:
					  @selector(name)]]);
    }

  EOFLOGObjectFnStop();

  return _dbSnapshotKeys;
}

- (NSArray*) flattenedAttributes
{
  //OK
  NSArray *flattenedAttributes = nil;
  NSArray *attributesToFetch = [self _attributesToFetch];
  int count = [attributesToFetch count];

  NSAssert3(!attributesToFetch
	    || [attributesToFetch isKindOfClass: [NSArray class]],
            @"entity %@ attributesToFetch is not an NSArray but a %@\n%@",
            [self name],
            [attributesToFetch class],
            attributesToFetch);

  if (count>0)
    {
      int i=0;
      IMP atfOAI=NULL;
      IMP tAO=NULL;
      NSMutableArray* tmpArray=GDL2MutableArrayWithCapacity(count);

      for (i = 0; i < count; i++)
        {
          EOAttribute *attribute = GDL2ObjectAtIndexWithImpPtr(attributesToFetch,&atfOAI,i);

          if ([attribute isFlattened])
            GDL2AddObjectWithImpPtr(tmpArray,&tAO,attribute);
        };
      flattenedAttributes=tmpArray;
    }
  else
    flattenedAttributes=GDL2Array();

  return flattenedAttributes;
}

@end

@implementation EOEntity (EOEntityPrivateXX)

- (EOExpressionArray*) _parseDescription: (NSString*)description
                                isFormat: (BOOL)isFormat
                               arguments: (char*)param2
{
// definition = "(((text(code) || ' ') || upper(abbreviation)) || ' ')";
  EOExpressionArray *expressionArray = nil;
  const char *s = NULL;
  const char *start = NULL;
  id objectToken = nil;
  id pool = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEntity", @"expression=%@", description);

  expressionArray = AUTORELEASE([EOExpressionArray new]);
  s = [description cString];

  if (s)
    {
      IMP eaAO=NULL;
      pool = [NSAutoreleasePool new];
      NS_DURING
        {
          /* Divide the expression string in alternating substrings that obey the
             following simple grammar: 
             
             I = [a-zA-Z0-9@_#]([a-zA-Z0-9@_.#$])+
             O = \'.*\' | \".*\" | [^a-zA-Z0-9@_#]+
             S -> I S | O S | nothing
          */
          while (s && *s) 
            {
              /* Determines an I token. */
              if (isalnum(*s) || *s == '@' || *s == '_' || *s == '#') 
                {
                  EOExpressionArray *expr = nil;

                  start = s;

                  for (++s; *s; s++)
                    if (!isalnum(*s) && *s != '@' && *s != '_'
			&& *s != '.' && *s != '#' && *s != '$')
                      break;
              
                  objectToken = GDL2StringWithCStringAndLength(start,
                                                               (unsigned)(s - start));
              
                  EOFLOGObjectLevelArgs(@"EOEntity", @"objectToken: '%@'",
					objectToken);

                  expr = [self _parsePropertyName: objectToken];

                  EOFLOGObjectLevelArgs(@"EOEntity", @"expr: '%@'",
					expr);

                  if (expr)
                    objectToken = expr;

                  EOFLOGObjectLevelArgs(@"EOEntity", @"addObject I Token: '%@'",
					objectToken);

                  GDL2AddObjectWithImpPtr(expressionArray,&eaAO,objectToken);
                }
          
              /* Determines an O token. */
              start = s;
              for (; *s && !isalnum(*s) && *s != '@' && *s != '_' && *s != '#';
		  s++)
                {
                  if (*s == '\'' || *s == '"') 
                    {
                      char quote = *s;
                  
                      for (++s; *s; s++)
                        if (*s == quote)
                          break;
                        else if (*s == '\\')
                          s++; /* Skip the escaped characters */

                      if (!*s)
                        [NSException raise: NSInvalidArgumentException
                                     format: @"%@ -- %@ 0x%x: unterminated character string",
                                     NSStringFromSelector(_cmd),
                                     NSStringFromClass([self class]),
                                     self];
                    }
                }

              if (s != start)
                {
                  objectToken = GDL2StringWithCStringAndLength(start,
                                                               (unsigned)(s - start));

                  EOFLOGObjectLevelArgs(@"EOEntity", @"addObject O Token: '%@'",
					objectToken);

                  GDL2AddObjectWithImpPtr(expressionArray,&eaAO,objectToken);
                }
            }
        }
      NS_HANDLER
        {
          RETAIN(localException);
          NSLog(@"exception in EOEntity _parseDescription:isFormat:arguments:");
          NSLog(@"exception=%@", localException);

          [pool release];//Release the pool !
          AUTORELEASE(localException);
          [localException raise];
        }
      NS_ENDHANDLER;
      [pool release];
    }

  // return nil if expressionArray is empty
  if ([expressionArray count] == 0)
    expressionArray = nil;
  // if expressionArray contains only one element and this element is a expressionArray, use it (otherwise, isFlatten will not be accurate)
  else if ([expressionArray count] == 1)
    {
      id expr = [expressionArray lastObject];

      if ([expr isKindOfClass: [EOExpressionArray class]])
        expressionArray = expr;
    }

  EOFLOGObjectLevelArgs(@"EOEntity",
			@"expressionArray=%@\nexpressionArray count=%d isFlattened=%s\n",
			expressionArray,
			[expressionArray count],
			([expressionArray isFlattened] ? "YES" : "NO"));

  return expressionArray;
}

- (EOExpressionArray*) _parseRelationshipPath: (NSString*)path
{
  EOEntity *entity = self;
  EOExpressionArray *expressionArray = nil;
  NSArray *components = nil;
  int i, count = 0;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEntity",@"self=%p (name=%@) path=%@",
               self,[self name],path);

  NSAssert1([path length] > 0, @"Path is empty (%p)", path);

  expressionArray = [EOExpressionArray expressionArrayWithPrefix: nil
				       infix: @"."
				       suffix: nil];

  EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p expressionArray=%@",
			self, expressionArray);

  components = [path componentsSeparatedByString: @"."];
  count = [components count];

  for (i = 0; i < count; i++)
    {
      NSString *part = [components objectAtIndex: i];
      EORelationship *relationship;

      NSAssert1([part length] > 0, @"part is empty (path=%@)", path);
      relationship = [entity anyRelationshipNamed: part];

      EOFLOGObjectLevelArgs(@"EOEntity", @"part=%@ relationship=%@",
			    part, relationship);

      if (relationship)
        {
          NSAssert2([relationship isKindOfClass: [EORelationship class]],
                    @"relationship is not a EORelationship but a %@. relationship:\n%@",
                    [relationship class],
                    relationship);

          if ([relationship isFlattened])
            {
              EOExpressionArray *definitionArray=[relationship _definitionArray];

              NSDebugMLog(@"entityName=%@ path=%@",[self name],path);
              NSDebugMLog(@"relationship=%@",relationship);
              NSDebugMLog(@"relationship definitionArray=%@",definitionArray);

              // For flattened relationships, we add relationship definition array
              [expressionArray addObjectsFromArray:definitionArray];

              // Use last relationship  to find destinationEntity,...
              relationship=[expressionArray lastObject];
            }
          else
            {
              [expressionArray addObject: relationship];
            }

          entity = [relationship destinationEntity];
        }
      else
        {
          NSDebugMLog(@"self %p name=%@: relationship \"%@\" used in \"%@\" doesn't exist in entity \"%@\"",
		      self,
                      [self name],
                      part,
                      path,
                      [entity name]);

          //EOF don't throw exception. But we do !
          [NSException raise: NSInvalidArgumentException
                       format: @"%@ -- %@ 0x%x: entity name=%@: relationship \"%@\" used in \"%@\" doesn't exist in entity \"%@\"",
                       NSStringFromSelector(_cmd),
                       NSStringFromClass([self class]),
                       self,
                       [self name],
                       part,
                       path,
                       [entity name]];
        }
    }
  EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p expressionArray=%@",
			self, expressionArray);

  // return nil if expressionArray is empty
  if ([expressionArray count] == 0)
    expressionArray = nil;
  // if expressionArray contains only one element and this element is a expressionArray, use it (otherwise, isFlatten will not be accurate)
  else if ([expressionArray count] == 1)
    {
      id expr = [expressionArray lastObject];

      if ([expr isKindOfClass: [EOExpressionArray class]])
        expressionArray = expr;
    }

  EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p expressionArray=%@",
			self, expressionArray);

  EOFLOGObjectFnStop();

  return expressionArray;
}

- (id) _parsePropertyName: (NSString*)propertyName
{
  EOEntity *entity = self;
  EOExpressionArray *expressionArray = nil;
  NSArray *components = nil;
  int i, count = 0;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p self name=%@ propertyName=%@",
			self, [self name], propertyName);

  expressionArray = [EOExpressionArray expressionArrayWithPrefix: nil
				       infix: @"."
				       suffix: nil];

  EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p expressionArray=%@",
			self, expressionArray);

  components = [propertyName componentsSeparatedByString: @"."];
  count = [components count];

  for (i = 0; i < count; i++)
    {
      NSString *part = [components objectAtIndex: i];
      EORelationship *relationship = [entity anyRelationshipNamed: part];

      EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p entity name=%@ part=%@ relationship=%@ relationship name=%@",
			    self, [entity name], part, relationship,
			    [relationship name]);

      if (relationship)
        {
          NSAssert2([relationship isKindOfClass: [EORelationship class]],
                    @"relationship is not a EORelationship but a %@. relationship:\n%@",
                    [relationship class],
                    relationship);

          if ([relationship isFlattened])
            {
              NSEmitTODO();  //TODO
              [self notImplemented: _cmd];//TODO
            }
          else
            {
              EOFLOGObjectLevelArgs(@"EOEntity",@"self=%p expressionArray addObject=%@ (name=%@)",
				    self, relationship, [relationship name]);

              [expressionArray addObject: relationship];
            }

          entity = [relationship destinationEntity];
        }
      else
        {
          EOAttribute *attribute = [entity anyAttributeNamed: part];

          EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p entity name=%@ part=%@ attribute=%@ attribute name=%@",
				self, [entity name], part, attribute,
				[attribute name]);

          if (attribute)
            [expressionArray addObject: attribute];
          else if (i < (count - 1))
            {
              //EOF don't throw exception ? But we do !
              [NSException raise: NSInvalidArgumentException
                           format: @"%@ -- %@ 0x%x: attribute \"%@\" used in \"%@\" doesn't exist in entity %@",
                           NSStringFromSelector(_cmd),
                           NSStringFromClass([self class]),
                           self,
                           propertyName,
                           part,
                           entity];
            }
        }
    }

  EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p expressionArray=%@",
			self, expressionArray);
  // return nil if expression is empty

  if ([expressionArray count] == 0)
    expressionArray = nil;
  else if ([expressionArray count] == 1)
    expressionArray = [expressionArray objectAtIndex: 0];

  EOFLOGObjectLevelArgs(@"EOEntity", @"self=%p expressionArray=\"%@\"",
			self, expressionArray);

  EOFLOGObjectFnStop();

  return expressionArray;
}

@end

@implementation EOEntity (Deprecated)
+ (EOEntity *)entity
{
  return AUTORELEASE([[self alloc] init]);
}

+ (EOEntity *)entityWithPropertyList: (NSDictionary *)propertyList
			       owner: (id)owner
{
  return AUTORELEASE([[self alloc] initWithPropertyList: propertyList
				   owner: owner]);
}

@end

@implementation EOEntityClassDescription

- (id)initWithEntity: (EOEntity *)entity
{
  if ((self = [super init]))
    {
      ASSIGN(_entity, entity);
    }

  return self;
}

- (void) dealloc
{
  //OK
  EOFLOGObjectLevelArgs(@"EOEntity", @"Deallocate EOEntityClassDescription %p",
			self);

  fflush(stdout);
  fflush(stderr);

  DESTROY(_entity);

  [super dealloc];
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"<%s %p - Entity: %@>",
                   object_get_class_name(self),
                   self,
                   [self entityName]];
}

- (EOEntity *)entity
{
  return _entity;
}

- (EOFetchSpecification *)fetchSpecificationNamed: (NSString *)name
{
  NSEmitTODO();  //TODO
  [self notImplemented: _cmd];
  return nil;
}

- (NSString *)entityName
{
  return [_entity name];
}

- (NSArray *)attributeKeys
{
  //OK
  return [_entity classPropertyAttributeNames];
}

- (void)awakeObject: (id)object
fromFetchInEditingContext: (EOEditingContext *)context
{
  //OK
  EOFLOGObjectFnStart();
  [super awakeObject: object
	 fromFetchInEditingContext: context];
  //nothing to do
  EOFLOGObjectFnStop();
}

/**
 * Overrides [EOClassDescription-awakeObject:fromInsertionInEditingContext:]
 * to initialize the class property relationships.  The toMany relationships
 * properties are initialized with a mutable array, while toOne relationships
 * which propagate the primary key of the object get instantiated with a
 * freshly initialzed instance.  Whether a relationship is manditory or not
 * is irrelevant at this point.
 */
- (void)awakeObject: (id)object
fromInsertionInEditingContext: (EOEditingContext *)context
{
  NSArray *relationships;
  NSArray *classProperties;
  EORelationship *relationship;
  int i, count;
  IMP relOAI=NULL;
  IMP objectSVFK=NULL;
  IMP objectTSVFK=NULL;
  IMP objectVFK=NULL;

  EOFLOGObjectFnStart();

  [super awakeObject: object
         fromInsertionInEditingContext: context];

  relationships = [_entity relationships];
  classProperties = [_entity classProperties];
  count = [relationships count];

  for (i = 0; i < count; i++)
    {
      relationship = GDL2ObjectAtIndexWithImpPtr(relationships,&relOAI,i);

      if ([classProperties containsObject: relationship])
	{
	  if ([relationship isToMany])
	    {
	      NSString *name = [relationship name];
	      id relationshipValue = 
                GDL2StoredValueForKeyWithImpPtr(object,&objectSVFK,name);

	      /* We put a value only if there's not already one */
	      if (relationshipValue == nil)
		{
		  /* [Ref: Assigns empty arrays to to-many 
		     relationship properties of newly inserted 
		     enterprise objects] */
		  GDL2TakeStoredValueForKeyWithImpPtr(object,&objectTSVFK,
                                                      [EOCheapCopyMutableArray array],
                                                      name);
		}
	    }
	  else
	    {
	      if ([relationship propagatesPrimaryKey])
		{
		  NSString *name = [relationship name];
		  id relationshipValue 
                    = GDL2ValueForKeyWithImpPtr(object,&objectVFK,name);

		  if (relationshipValue == nil)
		    {
		      EOEntity *destinationEntity 
			= [relationship destinationEntity];
		      EOClassDescription *classDescription
			= [destinationEntity classDescriptionForInstances];

		      relationshipValue 
			= [classDescription createInstanceWithEditingContext:
					      context
					    globalID: nil
					    zone: NULL];

		      [object addObject: relationshipValue
			      toBothSidesOfRelationshipWithKey: name];

		      [context insertObject: relationshipValue];
		    }
		}
	    }
	}
    }
  EOFLOGObjectFnStop();
}

- (EOClassDescription *)classDescriptionForDestinationKey: (NSString *)detailKey
{
  EOClassDescription *cd = nil;
  EOEntity *destEntity = nil;
  EORelationship *rel = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EOEntity", @"detailKey=%@", detailKey);
  EOFLOGObjectLevelArgs(@"EOEntity", @"_entity name=%@", [_entity name]);

  rel = [_entity relationshipNamed: detailKey];
  EOFLOGObjectLevelArgs(@"EOEntity", @"rel=%@", rel);

  destEntity = [rel destinationEntity];
  EOFLOGObjectLevelArgs(@"EOEntity", @"destEntity name=%@", [destEntity name]);

  cd = [destEntity classDescriptionForInstances];
  EOFLOGObjectLevelArgs(@"EOEntity", @"cd=%@", cd);

  EOFLOGObjectFnStop();

  return cd;
}

- (id)createInstanceWithEditingContext: (EOEditingContext *)editingContext
                              globalID: (EOGlobalID *)globalID
                                  zone: (NSZone *)zone
{
  id obj = nil;
  Class objectClass;

  EOFLOGObjectFnStart();

  NSAssert1(_entity, @"No _entity in %@", self);

  objectClass = [_entity classForObjectWithGlobalID: (EOKeyGlobalID*)globalID];
  EOFLOGObjectLevelArgs(@"EOEntity", @"objectClass=%p", objectClass);

  NSAssert2(objectClass, @"No objectClass for globalID=%@. EntityName=%@",
	    globalID, [_entity name]);

  if (objectClass)
    {
      EOFLOGObjectLevelArgs(@"EOEntity", @"objectClass=%@", objectClass);

      obj = AUTORELEASE([[objectClass allocWithZone:zone]
			  initWithEditingContext: editingContext
			  classDescription: self
			  globalID: globalID]);
    }

  EOFLOGObjectFnStop();

  return obj;
}

- (NSFormatter *)defaultFormatterForKey: (NSString *)key
{
  [self notImplemented: _cmd];
  return nil;
}

- (NSFormatter *)defaultFormatterForKeyPath: (NSString *)keyPath
{
  [self notImplemented: _cmd];
  return nil; //TODO
}

- (EODeleteRule)deleteRuleForRelationshipKey: (NSString *)relationshipKey
{
  EORelationship *rel = nil;
  EODeleteRule deleteRule = 0;

  EOFLOGObjectFnStart();

  rel = [_entity relationshipNamed: relationshipKey];
  EOFLOGObjectLevelArgs(@"EOEntity", @"relationship %p=%@", rel, rel);

  deleteRule = [rel deleteRule];
  EOFLOGObjectLevelArgs(@"EOEntity", @"deleteRule=%d", (int)deleteRule);

  EOFLOGObjectFnStop();

  return deleteRule;
}

- (NSString *)inverseForRelationshipKey: (NSString *)relationshipKey
{
  //Ayers: Review
  //Near OK
  NSString *inverseName = nil;
  EORelationship *relationship = [_entity relationshipNamed: relationshipKey];
  //EOEntity *parentEntity = [_entity parentEntity];
  //TODO what if parentEntity
  EORelationship *inverseRelationship = [relationship inverseRelationship];

  if (inverseRelationship)
    {
      EOEntity *inverseEntity = [inverseRelationship entity];
      NSArray *classPropertieNames = [inverseEntity classPropertyNames];

      inverseName = [inverseRelationship name];

      if (![classPropertieNames containsObject: inverseName])
	inverseName = nil;
    }

  return inverseName;
}

- (BOOL)ownsDestinationObjectsForRelationshipKey: (NSString*)relationshipKey
{
  //OK
  return [[_entity relationshipNamed: relationshipKey] ownsDestination];
}

- (NSArray *)toManyRelationshipKeys
{
  //OK
  return [_entity classPropertyToManyRelationshipNames];
}

- (NSArray *)toOneRelationshipKeys
{
  //OK
  return [_entity classPropertyToOneRelationshipNames];
}

- (EORelationship *)relationshipNamed: (NSString *)relationshipName
{
  //OK
  return [_entity relationshipNamed:relationshipName];
}

- (EORelationship *)anyRelationshipNamed: (NSString *)relationshipName
{
  return [_entity anyRelationshipNamed:relationshipName];  
}

- (NSException *) validateObjectForDelete: (id)object
{
  return [_entity validateObjectForDelete:object];
}

- (NSException *)validateObjectForSave: (id)object
{
  return nil; //Does Nothing ? works is done in record
}

- (NSException *)validateValue: (id *)valueP
                        forKey: (NSString *)key
{
  NSException *exception = nil;
  EOAttribute *attr;
  EORelationship *relationship;

  NSAssert(valueP, @"No value pointer");

  attr = [_entity attributeNamed: key];

  if (attr)
    {
      exception = [attr validateValue: valueP];
    }
  else
    {
      relationship = [_entity relationshipNamed: key];

      if (relationship)
        {
          exception = [relationship validateValue: valueP];
        }
      else
        {
          NSEmitTODO();  //TODO
        }
    }

  return exception;
}

@end

@implementation EOEntityClassDescription (GDL2Extenstions)
/** returns a new autoreleased mutable dictionary to store properties 
returns nil if there's no key in the instanceDictionaryInitializer
**/
- (EOMutableKnownKeyDictionary*) dictionaryForInstanceProperties
{
  EOMutableKnownKeyDictionary* dict = nil;

  EOFLOGObjectFnStart();

  NSAssert(_entity,@"No entity");

  dict = [_entity _dictionaryForInstanceProperties];

  EOFLOGObjectFnStop();

  return dict;
}
@end

@implementation EOEntityClassDescription (Deprecated)
+ (EOEntityClassDescription*)entityClassDescriptionWithEntity: (EOEntity *)entity
{
  return AUTORELEASE([[self alloc] initWithEntity: entity]);
}
@end

@implementation NSString (EODatabaseNameConversion)

+ (NSString *)nameForExternalName: (NSString *)externalName
                  separatorString: (NSString *)separatorString
                      initialCaps: (BOOL)initialCaps
{
  NSEmitTODO(); //TODO
  [self notImplemented: _cmd];
  return nil;
}

+ (NSString *)externalNameForInternalName: (NSString *)internalName
                          separatorString: (NSString *)separatorString
                               useAllCaps: (BOOL)allCaps
{
  NSEmitTODO(); //TODO
  [self notImplemented: _cmd];
  return nil;
}

@end


@implementation NSObject (EOEntity)
/** should returns a set of property names to exclude from entity 
instanceDictionaryInitializer **/
+ (NSArray *)_instanceDictionaryInitializerExcludedPropertyNames
{
  // default implementation returns nil
  return nil;
}
@end
