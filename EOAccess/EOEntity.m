/**
   EOEntity.m <title>EOEntity Class</title>

   Copyright (C) 2000, 2002, 2003, 2004, 2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com>
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
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/NSObject+GNUstepBase.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#endif
#include <GNUstepBase/Unicode.h>

#include <EOControl/EOKeyValueCoding.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOKeyGlobalID.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EONull.h>
#include <EOControl/EOMutableKnownKeyDictionary.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EOCheapArray.h>
#include <EOControl/EODebug.h>
#include <EOControl/EOFetchSpecification.h>

#include <EOAccess/EOModel.h>
#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOStoredProcedure.h>
#include <EOAccess/EOExpressionArray.h>
#include <EOAccess/EOSQLExpression.h>

#include "EOPrivate.h"
#include "EOEntityPriv.h"
#include "EOAttributePriv.h"
#include "../EOControl/EOPrivate.h"

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
- (id)initWithPropertyList: (NSDictionary*)propertyList
		     owner: (id)owner
{
  [EOObserverCenter suppressObserverNotification];

  EOFLOGObjectLevelArgs(@"EOEntity", @"propertyList=%@", propertyList);

  NS_DURING
    {
      if ((self = [self init]) != nil)
        {
          NSArray	*array = nil;
          NSDictionary * aDict = nil;
          NSString	*tmpString = nil;
          id		tmpObject = nil;

          _flags.updating = YES;
	  
	  /* set this before validation. */
	  if ([owner isKindOfClass:[EOModel class]])
	    [self _setModel:owner];
	  // else _setParent:??

	  tmpString = [propertyList objectForKey:@"name"];
	  /*
 	     we dont want it to call _updateCache. So we validate and
	     set the name directly, as we haven't been added to the model yet,
	     and this would causes problems.
	   */
	  [[self validateName:tmpString] raise];
	  ASSIGN(_name, tmpString);

          [self setExternalName: [propertyList objectForKey: @"externalName"]];
	  tmpObject = [propertyList objectForKey: @"externalQuery"];
          [self setExternalQuery: tmpObject];

          tmpString = [propertyList objectForKey: @"restrictingQualifier"];

          EOFLOGObjectLevelArgs(@"EOEntity",@"tmpString=%@",tmpString);

          if (tmpString)
            {
              EOQualifier *restrictingQualifier
		= [EOQualifier qualifierWithQualifierFormat: tmpString
			       arguments:nil];

              [self setRestrictingQualifier: restrictingQualifier];
            }

          tmpString = [propertyList objectForKey: @"mappingQualifier"];

          if (tmpString)
            {
              NSEmitTODO();  //TODO
            }

	  tmpObject = [propertyList objectForKey: @"isReadOnly"];
          [self setReadOnly: [tmpObject boolValue]];
	  tmpObject = [propertyList objectForKey: @"cachesObjects"];
          [self setCachesObjects: [tmpObject boolValue]];

          tmpObject = [propertyList objectForKey: @"userInfo"];
          EOFLOGObjectLevelArgs(@"EOEntity", @"tmpObject=%@", tmpObject);
          if (tmpObject)
	    {
	      [self setUserInfo: tmpObject];
	    }
          else
            {
              tmpObject = [propertyList objectForKey: @"userDictionary"];
              [self setUserInfo: tmpObject];
            }

          tmpObject = [propertyList objectForKey: @"internalInfo"];

          EOFLOGObjectLevelArgs(@"EOEntity", @"tmpObject=%@ [%@]",
				tmpObject, [tmpObject class]);

          [self _setInternalInfo: tmpObject];
          [self setDocComment:[propertyList objectForKey:@"docComment"]];
          [self setClassName: [propertyList objectForKey: @"className"]];
	  tmpObject = [propertyList objectForKey: @"isAbstractEntity"];
          [self setIsAbstractEntity: [tmpObject  boolValue]];
      
          tmpString = [propertyList objectForKey: @"isFetchable"];

          if (tmpString)
            {
              NSEmitTODO();  //TODO
            }
          
          array = [propertyList objectForKey: @"attributes"];

          EOFLOGObjectLevelArgs(@"EOEntity", @"Attributes: %@", array);

          if ([array count] > 0)
            {
              ASSIGN(_attributes, (NSMutableArray*)array);
              _flags.attributesIsLazy = YES;
            }

          array = [propertyList objectForKey: @"attributesUsedForLocking"];
          EOFLOGObjectLevelArgs(@"EOEntity", @"attributesUsedForLocking: %@",
				array);
          if ([array count] > 0)
            {          
              ASSIGN(_attributesUsedForLocking, (NSMutableArray*)array);
              _flags.attributesUsedForLockingIsLazy = YES;
            }

          array = [propertyList objectForKey: @"primaryKeyAttributes"];
          array = [array sortedArrayUsingSelector: @selector(compare:)];

          EOFLOGObjectLevelArgs(@"EOEntity", @"primaryKeyAttributes: %@",
				array);

          if ([array count] > 0)
            {
              ASSIGN(_primaryKeyAttributes, (NSMutableArray*)array);
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
              ASSIGN(_classProperties, (NSMutableArray*)array);
              _flags.classPropertiesIsLazy = YES;
            }

          array = [propertyList objectForKey: @"relationships"];

          EOFLOGObjectLevelArgs(@"EOEntity", @"relationships: %@", array);

          if ([array count] > 0)
            {
              ASSIGN(_relationships, (NSMutableArray*)array);
              _flags.relationshipsIsLazy = YES;
            }

          if ((aDict = [propertyList objectForKey: @"storedProcedureNames"]) != nil)
          {
            NSEnumerator * keyEnumerator = [aDict keyEnumerator];
            NSString     * curentKey;
            ASSIGN(_storedProcedures, [NSMutableDictionary dictionary]);
            
            while ((curentKey = [keyEnumerator nextObject])) {
              EOStoredProcedure * storedproc;
              if ((storedproc = [_model storedProcedureNamed:[aDict objectForKey:curentKey]]))
              {
                [_storedProcedures setObject:storedproc
                                      forKey:curentKey];
              }
            }
                        
          }
          
          tmpString = [propertyList objectForKey: @"maxNumberOfInstancesToBatchFetch"];

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

          tmpObject 
	    = [propertyList objectForKey: @"fetchSpecificationDictionary"];

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
            path = [(EOModel *)owner path];
            path = [path stringByAppendingPathComponent: fileName];
	    if ([[NSFileManager defaultManager] fileExistsAtPath: path])
		plist 
		  = [[NSString stringWithContentsOfFile: path] propertyList];
	    
            if (plist) 
              {
                EOKeyValueUnarchiver *unarchiver;
                NSDictionary *variables;
                NSEnumerator *variablesEnum;
                id fetchSpecName;

                unarchiver 
		  = AUTORELEASE([[EOKeyValueUnarchiver alloc]
				  initWithDictionary:
				    [NSDictionary dictionaryWithObject: plist
						  forKey: @"fspecs"]]);

                variables = [unarchiver decodeObjectForKey: @"fspecs"];
                
                [unarchiver finishInitializationOfObjects];
                [unarchiver awakeObjects];

		variablesEnum = [variables keyEnumerator];
		while ((fetchSpecName = [variablesEnum nextObject]))
		  {
		    id fetchSpec = [variables objectForKey: fetchSpecName];

		    [self addFetchSpecification: fetchSpec
			  withName: fetchSpecName];
		  }
	      }
          }

          _flags.updating = NO;
        }  
    }
  NS_HANDLER
    {
      [EOObserverCenter enableObserverNotification];

      NSLog(@"exception in EOEntity initWithPropertyList:owner:");
      NSLog(@"exception=%@", localException);

      NSLog(@"exception=%@", localException);
      [localException raise];
    }
  NS_ENDHANDLER;

  [EOObserverCenter enableObserverNotification];

  return self;
}

- (void)awakeWithPropertyList: (NSDictionary *)propertyList
{
  NSString *tmp;
  
  if ((tmp = [propertyList objectForKey:@"parent"]))
    {
      EOEntity *parent = [_model entityNamed:tmp];
      /* TODO tests for parents spanning models. */
      if (!parent)
        parent = [[_model modelGroup] entityNamed:tmp];
      [parent addSubEntity:self];	
    }
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
    [propertyList setObject: [NSString stringWithFormat:@"%d",  _batchCount]
                  forKey: @"maxNumberOfInstancesToBatchFetch"];

  if (_flags.cachesObjects)
    [propertyList setObject: @"Y"
                  forKey: @"cachesObjects"];

  if (_flags.isAbstractEntity)
    [propertyList setObject: @"Y"
                  forKey: @"isAbstractEntity"];

  if (_parent)
    [propertyList setObject: [_parent name]
	    	  forKey: @"parent"];

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
  // stored procedures
  //
  // storedProcedureNames = {EOInsertProcedure = fooproc; }; 

  if ((_storedProcedures != nil) && ([_storedProcedures count]))
  {
    NSString      *currentKey     = nil;
    NSEnumerator  *keyEnumerator = [[[_storedProcedures allKeys] 
                                     sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
    NSMutableDictionary * newDict = [NSMutableDictionary dictionary];
    
    while ((currentKey = [keyEnumerator nextObject])) {
      [newDict setObject:[[_storedProcedures objectForKey:currentKey] name]
                  forKey:currentKey];
    }
    
    [propertyList setObject: newDict
                     forKey: @"storedProcedureNames"];
    
  }
  
}

- (id) init
{
  if ((self = [super init]))
    {
      _attributes = [NSMutableArray new];
      _subEntities = [NSMutableArray new];
      _relationships = [NSMutableArray new];
    }

  return self;
}

static void performSelectorOnArrayWithEachObjectOfClass(NSArray *arr, SEL selector, id arg, Class class)
{
  int i, c;
  
  arr = [arr copy];
  for (i = 0, c = [arr count]; i < c; i++)
    {
      id obj = [arr objectAtIndex:i];

      if ([obj isKindOfClass:class])
        {
	  [obj performSelector:selector withObject:arg];
        }
    }
  RELEASE(arr);
}

- (void) dealloc
{
  /* these classes may contain NSDictionaries as well as entities, attributes and relationships 
     in the case of delayed instantiation */
  performSelectorOnArrayWithEachObjectOfClass(_subEntities, @selector(_setParentEntity:),
  					      nil, [EOEntity class]);
  performSelectorOnArrayWithEachObjectOfClass(_attributes, @selector(setParent:),
  					      nil, GDL2_EOAttributeClass);
  performSelectorOnArrayWithEachObjectOfClass(_relationships, @selector(setEntity:),
  					      nil, GDL2_EORelationshipClass);

  if (_classDescription) [[EOClassDescription class] invalidateClassDescriptionCache];

  DESTROY(_adaptorDictionaryInitializer);
  DESTROY(_instanceDictionaryInitializer);
  DESTROY(_primaryKeyDictionaryInitializer);
  DESTROY(_propertyDictionaryInitializer);
  DESTROY(_snapshotDictionaryInitializer);
  
  DESTROY(_attributes);
  DESTROY(_attributesByName);
  DESTROY(_attributesToFetch);
  DESTROY(_attributesToSave);
  DESTROY(_flattenedAttNameToSnapshotKeyMapping);
  DESTROY(_attributesUsedForLocking);
  DESTROY(_classDescription);
  DESTROY(_classForInstances);
  DESTROY(_className);
  DESTROY(_classProperties);
  DESTROY(_classPropertyAttributeNames);
  DESTROY(_classPropertyNames);
  DESTROY(_classPropertyToManyRelationshipNames);
  DESTROY(_classPropertyToOneRelationshipNames);
  DESTROY(_dbSnapshotKeys);
  DESTROY(_docComment);
  DESTROY(_externalName);
  DESTROY(_externalQuery);
  DESTROY(_fetchSpecificationDictionary);
  DESTROY(_fetchSpecificationNames);
  DESTROY(_hiddenRelationships);
  DESTROY(_internalInfo);
  DESTROY(_name);
  DESTROY(_primaryKeyAttributes);
  DESTROY(_primaryKeyAttributeNames);
  DESTROY(_propertiesToFault); // never initialized?
  DESTROY(_restrictingQualifier);
  DESTROY(_relationships);
  DESTROY(_relationshipsByName);
  DESTROY(_storedProcedures); // never initialized?
  DESTROY(_snapshotToAdaptorRowSubsetMapping);
  DESTROY(_subEntities);
  DESTROY(_singleTableSubEntityDictionary);
  DESTROY(_singleTableSubEntityKey);
  DESTROY(_singleTableRestrictingQualifier);
  DESTROY(_userInfo);

  [super dealloc];
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
		   object_getClassName(self),
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
  if (_flags.attributesIsLazy)
    {
      int count = 0;

      EOFLOGObjectLevelArgs(@"EOEntity",
			    @"START construct attributes on %p", self);

      count = [_attributes count];
      EOFLOGObjectLevelArgs(@"EOEntity", @"Entity %@: Lazy _attributes=%@",
			    [self name],
			    _attributes);

      if (count > 0)
        {
          int i = 0;
          NSArray *attributePLists = AUTORELEASE(RETAIN(_attributes));

          DESTROY(_attributes);
          DESTROY(_attributesByName);

          _attributes = [NSMutableArray new];
          _attributesByName = [NSMutableDictionary new];

	  /* if we've already loaded relationships rebuild the name cache */
          if (!_flags.relationshipsIsLazy && _relationshipsByName == nil)
            [self relationshipsByName];

          _flags.attributesIsLazy = NO;

          [EOObserverCenter suppressObserverNotification];
          _flags.updating = YES;

          NS_DURING
            {
              NSArray *attrNames = nil;

              for (i = 0; i < count; i++)
                {
                  id attrPList = [attributePLists objectAtIndex: i];
                  EOAttribute *attribute = nil;
                  NSString *attributeName = nil;

		  // this should validate name against its owner via setName: 
		  attribute = [EOAttribute attributeWithPropertyList: attrPList
				   owner: self];
		  attributeName = [attribute name];

		  // don't call -addAttribute: because it wipes our name cache
                  [_attributes addObject: attribute];
                  [_attributesByName setObject: attribute
				     forKey: attributeName];
                }

              attrNames = [_attributes resultsOfPerformingSelector:
					 @selector(name)];
              count = [attrNames count];
              NSAssert(count == [attributePLists count],
		       @"Error during attribute creations");
	      {
                int pass = 0;

                //We'll first awake non derived/flattened attributes
                for (pass = 0; pass < 2; pass++)
                  {
                    for (i = 0; i < count; i++)
                      {
                        NSString *attrName = [attrNames objectAtIndex: i];
                        NSDictionary *attrPList = nil;
                        EOAttribute *attribute = nil;
			id definition = nil;

                        EOFLOGObjectLevelArgs(@"EOEntity", @"XXX attrName=%@",
					      attrName);
			
			attrPList = [attributePLists objectAtIndex: i];
			definition = [attrPList objectForKey: @"definition"];
                        if ((pass == 0 && definition == nil)
			    || (pass == 1 && definition != nil))
                          {
                            attribute = [self attributeNamed: attrName];
                            EOFLOGObjectLevelArgs(@"EOEntity",
						  @"XXX 2A ATTRIBUTE: self=%p AWAKE attribute=%@",
						  self, attribute);

                            [attribute awakeWithPropertyList: attrPList];
                            EOFLOGObjectLevelArgs(@"EOEntity",
						  @"XXX 2B ATTRIBUTE: self=%p attribute=%@",
						  self, attribute);
                          }
                      }
                  }
              }
            }
          NS_HANDLER
            {
	      _flags.updating = NO;
              [EOObserverCenter enableObserverNotification];
              [localException raise];
            }
          NS_ENDHANDLER;

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



  return attribute;
}

/** returns attribute named attributeName (no relationship) **/
- (EOAttribute *)anyAttributeNamed: (NSString *)attributeName
{
  EOAttribute *attr;
  NSEnumerator *attrEnum;

  attr = [self attributeNamed:attributeName];

  //VERIFY
  /* I suppose this is intended to find the 'hidden' attributes mentioned in
   * the documentation of this method, but if these are in -primaryKeyAttributes
   * they don't appear to be well hidden, and _primaryKeyAttributes is filled
   * by calling -attributeNamed: and doesn't appear to be modified outside
   * -primaryKeyAttributes:, so this check appears to be redundant to the one
   * above.
   */
  if (!attr)
    {
      IMP enumNO=NULL;
      attrEnum = [[self primaryKeyAttributes] objectEnumerator];

      while ((attr = GDL2_NextObjectWithImpPtr(attrEnum,&enumNO)))
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

          DESTROY(_relationshipsByName);

          _relationships = [NSMutableArray new];
          _relationshipsByName = [NSMutableDictionary new];

          if (!_flags.attributesIsLazy && _attributesByName == nil)
            [self attributesByName];

          _flags.relationshipsIsLazy = NO;
          [EOObserverCenter suppressObserverNotification];
          _flags.updating = YES;

          NS_DURING
            {
              NSArray *relNames = nil;

              for (i = 0; i < count; i++)
                {
                  id attrPList = [relationshipPLists
					      objectAtIndex: i];
                  EORelationship *relationship = nil;
                  NSString *relationshipName = nil;

		  /* this should cause validation to occur. */
                  relationship= [EORelationship
				     relationshipWithPropertyList: attrPList
				     owner: self];

                  relationshipName = [relationship name];

                  [_relationships addObject: relationship];
                  [_relationshipsByName setObject: relationship
                                        forKey: relationshipName];
                }

              EOFLOGObjectLevel(@"EOEntity", @"Rels added");

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
                        NSDictionary *relPList = [relationshipPLists
						   objectAtIndex: i];
			if ([relPList isKindOfClass: GDL2_EORelationshipClass])
			  continue;
			
			  {
                            NSString *relName = [relNames objectAtIndex: i];
                            EORelationship *relationship;
			  
			    relationship = [self relationshipNamed: relName];

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

- (EORelationship *)anyRelationshipNamed: (NSString *)relationshipName
{
  EORelationship *rel;
  NSEnumerator *relEnum = nil;

  rel = [self relationshipNamed: relationshipName];

  //VERIFY
  if (!rel)
    {
      EORelationship *tmpRel = nil;
      IMP enumNO=NULL;

      relEnum = [_hiddenRelationships objectEnumerator];

      while (!rel && (tmpRel = GDL2_NextObjectWithImpPtr(relEnum,&enumNO)))
        {
	  if ([[tmpRel name] isEqual: relationshipName])
	    rel = tmpRel;
        }
    }

  return rel;
}

- (NSArray *)classProperties
{
  if (_flags.classPropertiesIsLazy)
  {
    int count = [_classProperties count];
    
    if (count > 0)
    {
      NSArray *classPropertiesList = _classProperties;
      int i;
      
      _classProperties = [NSMutableArray new];
      _flags.classPropertiesIsLazy = NO;
      
      for (i = 0; i < count; i++)
      {
#if 0
        NSString *classPropertyName = [classPropertiesList
                                       objectAtIndex: i];
#else
        id classPropertyName = (
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
  
  
  
  return _classProperties;
}

- (NSArray *)classPropertyNames
{
  //OK


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

          _primaryKeyAttributes = [NSMutableArray new];
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
  if (_flags.attributesUsedForLockingIsLazy)
  {
    int count = [_attributesUsedForLocking count];
        
    if (count > 0)
    {
      int i = 0;
      NSArray *attributesUsedForLocking = _attributesUsedForLocking;
      
      _attributesUsedForLocking = [NSMutableArray new];
      _flags.attributesUsedForLockingIsLazy = NO;
      
      for (i = 0; i < count; i++)
      {
        NSString *attributeName = [attributesUsedForLocking
                                   objectAtIndex: i];
        EOAttribute *attribute = [self attributeNamed: attributeName];
        
        if (attribute)
        {
          [_attributesUsedForLocking addObject: attribute];
        }
      }
      
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
	    || [_attributesToFetch isKindOfClass: [NSArray class]],
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
      NSMutableArray *array 
	= AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: count]);
      IMP pkanOAI=NULL;
      IMP rowOFK=NULL;
      IMP arrayAO=NULL;
      int i;

      for (i = 0; i < count; i++)
	{
	  NSString *key = GDL2_ObjectAtIndexWithImpPtr(primaryKeyAttributeNames,&pkanOAI,i);
          id value = GDL2_ObjectForKeyWithImpPtr(row,&rowOFK,key);

	  GDL2_AddObjectWithImpPtr(array,&arrayAO,
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
      EOAttribute *attr = GDL2_ObjectAtIndexWithImpPtr(primaryKeyAttributes,&pkaOAI,i);
      NSString* attrName = [attr name];
      id value = GDL2_ObjectForKeyWithImpPtr(row,&rowOFK,attrName);

      if (!value)
        value = GDL2_EONull;

      GDL2_SetObjectForKeyWithImpPtr(dict,&dictSOFK,value,attrName);
    }

  return dict;
}

- (BOOL)isValidAttributeUsedForLocking: (EOAttribute *)attribute
{
  if (!([attribute isKindOfClass: GDL2_EOAttributeClass]
	&& ([self attributeNamed: [attribute name]] == attribute)))
    return NO;

  if ([attribute isDerived])
    return NO;

  return YES;
}

- (BOOL)isValidPrimaryKeyAttribute: (EOAttribute *)attribute
{
  if (!([attribute isKindOfClass: GDL2_EOAttributeClass]
	&& ([self attributeNamed: [attribute name]] == attribute)))
    return NO;

  if ([attribute isDerived])
    return NO;

  return YES;
}

- (BOOL)isPrimaryKeyValidInObject: (id)object
{
  NSArray *primaryKeyAttributeNames = nil;
  NSString *key = nil;
  id value = nil;
  NSUInteger i, count;
  IMP pkanOAI=NULL;
  IMP objectVFK=NULL;
  
  primaryKeyAttributeNames = [self primaryKeyAttributeNames];
  count = [primaryKeyAttributeNames count];
  
  for (i = 0; i < count; i++)
  {
    key = GDL2_ObjectAtIndexWithImpPtr(primaryKeyAttributeNames,&pkanOAI,i);
    
      value = GDL2_ValueForKeyWithImpPtr(object,&objectVFK,key);
      
      
      // a 0 is NOT a valid PK value! -- dw
      if ((_isNilOrEONull(value)) || (([value isKindOfClass:[NSNumber class]]) && 
                                      ([value intValue] == 0))) {
        return NO;
      }
  }
  
  return YES;
}

- (BOOL)isValidClassProperty: (id)property
{
  id thePropertyName;

  if (!([property isKindOfClass: GDL2_EOAttributeClass]
	|| [property isKindOfClass: GDL2_EORelationshipClass]))
    return NO;

  thePropertyName = [(EOAttribute *)property name];

  if ([[self attributesByName] objectForKey: thePropertyName] == property
      || [[self relationshipsByName] objectForKey: thePropertyName] == property)
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
  EOGlobalID *gid = [self _globalIDForRow: row
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

- (NSDictionary *)primaryKeyForGlobalID: (EOGlobalID *)gid
{
  //OK
  NSMutableDictionary *dictionaryForPrimaryKey = nil;

  if ([gid isKindOfClass: [EOKeyGlobalID class]]) //if ([gid isFinal])//?? or class test ??//TODO
    {
      NSArray *primaryKeyAttributeNames = [self primaryKeyAttributeNames];
      int count = [primaryKeyAttributeNames count];

      if (count > 0)
        {
          int i;
          id *gidkeyValues = [(EOKeyGlobalID*)gid keyValues];

          if (gidkeyValues)
            {
              IMP pkanOAI=NULL;
              IMP dfpkSOFK=NULL;
              dictionaryForPrimaryKey = [self _dictionaryForPrimaryKey];

              NSAssert1(dictionaryForPrimaryKey,
			@"No dictionaryForPrimaryKey in entity %@",
                        [self name]);

              for (i = 0; i < count; i++)
                {
                  id key = GDL2_ObjectAtIndexWithImpPtr(primaryKeyAttributeNames,&pkanOAI,i);

                  GDL2_SetObjectForKeyWithImpPtr(dictionaryForPrimaryKey,&dfpkSOFK,
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

  return dictionaryForPrimaryKey;
}
@end


@implementation EOEntity (EOEntityEditing)

- (void)setName: (NSString *)name
{
  NSInteger fCount = -1;
  NSInteger i;
  EOModel   * oldModel = nil;
  
  if (name && [name isEqual: _name]) return;
  
  [[self validateName: name] raise];

  [self willChange];
  
  RETAIN(self);
  ASSIGN(oldModel,_model);
    
  // We have to make sure all references are loaded before we change the name
  // if somebody finds a better solution, please tell me -- dw
  [_model referencesToProperty:self];
  
  [_model removeEntity:self];
  
  // update the fetch specifications
  
  if (_fetchSpecificationNames) 
  {
    fCount = [_fetchSpecificationNames count];
  }

  for (i = 0; i < fCount; i++)
  {
    EOFetchSpecification * fetchSpec = [self fetchSpecificationNamed:[_fetchSpecificationNames objectAtIndex:i]];
    [fetchSpec setEntityName:name];
  }
  
  ASSIGNCOPY(_name, name);
  
  [oldModel addEntity:self];
  RELEASE(oldModel);
  RELEASE(self);
  [self _setIsEdited];

  // this destroys everything. -- dw
  //[_model _updateCache];
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
  [_attributes addObject: attribute];
  [self _setIsEdited]; //To clean caches
  [attribute setParent: self];
  [self _clearAttributesCaches];
}

/**
 * Removes the attribute from the -attributes array, and the
 * -classProperties, and -primaryKeyAttributes arrays if they contain it.
 * does not remove any references to the attribute from other properties.
 * the caller should insure that no such references exist by calling
 * -referencesProperty: or [EOModel -referencesToProperty:].
 */
- (void) removeAttribute: (EOAttribute *)attribute
{
  if (attribute)
    {
      [self willChange];
      // make sure everything is initialized 
      [self attributes];
      [self classProperties];
      [self attributesUsedForLocking];
      [self primaryKeyAttributes];

      [_attributesByName removeObjectForKey:[attribute name]];
      [_classProperties removeObject: attribute];
      [_attributesUsedForLocking removeObject: attribute];
      [_primaryKeyAttributes removeObject:attribute];

      [attribute setParent: nil];
      [_attributes removeObject: attribute];

      [self _setIsEdited];//To clean caches
      [self _clearAttributesCaches];
    }
}

- (void)addRelationship: (EORelationship *)relationship
{
  NSString *relationshipName = [relationship name];

  if ([[self attributesByName] objectForKey: relationshipName])
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%p: \"%@\" already used in the model as attribute",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self,
                 relationshipName];

  if ([[self relationshipsByName] objectForKey: relationshipName])
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%p: \"%@\" already used in the model",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self,
                 relationshipName];

  [self willChange];
  [_relationships addObject: relationship];
    
  if (_relationshipsByName == nil)
    {
      _relationshipsByName = [NSMutableDictionary new];
    }
  [_relationshipsByName setObject: relationship forKey: relationshipName];
  
  [relationship setEntity: self];
  [self _setIsEdited];//To clean caches
}

/** 
 * Removes the relationship from the -relationships array and
 * the -classProperties array if it contains the relationship.
 * The caller should insure that no references to the
 * relationship exist by calling -referencesProperty: or
 * [EOModel -referencesToProperty].
 */
- (void)removeRelationship: (EORelationship *)relationship
{
  if (relationship)
  {
    [self willChange];
    [self relationships];
    [self classProperties];
    
    [_relationshipsByName removeObjectForKey:[relationship name]];
    
    [_classProperties removeObject: relationship];
    [_relationships removeObject: relationship];
    
    /* We call this after adjusting the arrays so that setEntity: has
     the opportunity to check the relationships before calling
     removeRelationshipt which would lead to an infinite loop.  */
    [relationship setEntity:nil];
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
    
  _classProperties = [[NSMutableArray alloc] initWithArray: properties]; //TODO

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
  _primaryKeyAttributes = [[NSMutableArray alloc] initWithArray: keys]; // TODO
  
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
  
  _attributesUsedForLocking = [[NSMutableArray alloc]
				  initWithArray: attributes];
  
  [self _setIsEdited]; //To clean cache

  return YES;
}

- (NSException *)validateName: (NSString *)name
{
  const char *p, *s = [name cString];
  int exc = 0;
  NSArray *storedProcedures;
  
  if ([_name isEqual:name]) return nil;
  
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
			  reason: [NSString stringWithFormat:@"%@ -- %@ 0x%p: argument \"%@\" contains invalid char '%c'",
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
                  	 reason: [NSString stringWithFormat: @"%@ -- %@ 0x%p: \"%@\" already used in the model",
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
  [[child parentEntity] removeSubEntity:child];
  [child _setParentEntity: self];
}

- (void)removeSubEntity: (EOEntity *)child
{
  [self willChange];
  if ([child parentEntity] == self)
    [child _setParentEntity: nil];
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
  while ((attr = GDL2_NextObjectWithImpPtr(enumerator,&enumNO)))
    {
      if ([attr isFlattened] && [[attr realAttribute] isEqual: property])
	return YES;
    }

  enumerator = [[self relationships] objectEnumerator];
  enumNO=NULL;
  while ((rel =  GDL2_NextObjectWithImpPtr(enumerator,&enumNO)))
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
  
  if (!_storedProcedures)
  {
    ASSIGN(_storedProcedures, [NSMutableDictionary dictionary]);
  }
  
  if (storedProcedure != nil) {
    [_storedProcedures setObject:storedProcedure
                          forKey:operation];
  } else {
    [_storedProcedures removeObjectForKey:operation];
  }
}

@end

@implementation EOEntity (EOPrimaryKeyGeneration)

- (NSString *)primaryKeyRootName
{
  if (_parent)
    return [_parent primaryKeyRootName];

  return _externalName;
}

@end

@implementation EOEntity (EOEntityClassDescription)

- (EOClassDescription *)classDescriptionForInstances
{


//  EOFLOGObjectLevelArgs(@"EOEntity", @"in classDescriptionForInstances");
  EOFLOGObjectLevelArgs(@"EOEntity", @"_classDescription=%@",
			_classDescription);

  if (!_classDescription)
    {
      _classDescription 
	= [[EOEntityClassDescription alloc] initWithEntity: self];

//NO ? NotifyCenter addObserver:EOEntityClassDescription selector:_eoNowMultiThreaded: name:NSWillBecomeMultiThreadedNotification object:nil
    }



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



  EOFLOGObjectLevelArgs(@"EOEntity", @"relationship=%@", relationship);

  return relationship;
}

@end

@implementation EOEntity (EOEntityPrivate)

/* private method for finding out if there is an attribute with a name
   without triggering lazy loading */
- (BOOL) _hasAttributeNamed:(NSString *)name
{
   return [[_attributes valueForKey:@"name"] containsObject:name];
}

- (BOOL)isPrototypeEntity
{
  [self notImplemented:_cmd];
  return NO; // TODO
}

/* throws an exception if _model is not nil, and the model argument is not
 * identical to the _model ivar. As a special case EOModel -removeEntity: 
 * is allowed to call this with a nil model, but removeEntity: is responsible
 * for any bookeeping.
 *
 * in other words, this method should not be used to change an entity's model. 
 */
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

  NSAssert3((_model == nil || _model == model || model == nil),
	    @"Attempt to set entity: %@ owned by model: %@ to model: @%.",
	    [self name], [_model name], [model name]);

  _model = model;
}

/* only for private usage of -addSubEntity: and -removeSubEntity: */
- (void)_setParentEntity: (EOEntity *)parent
{
  [self willChange]; // TODO: verify
  _parent = parent;
}

- (NSDictionary *)snapshotForRow: (NSDictionary *)aRow
{
  NSArray *array = [self attributesUsedForLocking];
  int i, n = [array count];
  NSMutableDictionary *dict 
    = AUTORELEASE([GDL2_alloc(NSMutableDictionary) initWithCapacity: n]);
  IMP arrayOAI=NULL;
  IMP dictSOFK=NULL;
  IMP aRowOFK=NULL;
    
  for (i = 0; i < n; i++)
    {
      id key = [(EOAttribute *)GDL2_ObjectAtIndexWithImpPtr(array,&arrayOAI,i) 
                               name];

      GDL2_SetObjectForKeyWithImpPtr(dict,&dictSOFK,
                                    GDL2_ObjectForKeyWithImpPtr(aRow,&aRowOFK,key),
                                    key);
    }

  return dict;
}

- (Class)_classForInstances
{


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



  return _classForInstances;
}

- (void)_setInternalInfo: (NSDictionary *)dictionary
{
  //OK
  [self willChange];
  ASSIGN(_internalInfo, dictionary);
  [self _setIsEdited];
}

- (EOGlobalID*) _globalIDForRow: (NSDictionary*)row
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
      keyArray[i] = GDL2_ObjectForKeyWithImpPtr(row,&rowOFK,
                                                GDL2_ObjectAtIndexWithImpPtr(primaryKeyAttributeNames,
                                                                             &pkanOAI,i));
      
    }
    globalID = [EOKeyGlobalID globalIDWithEntityName: [self name]
                                                keys: keyArray
                                            keyCount: count
                                                zone: [self zone]];
  }
  
  //NSEmitTODO();  //TODO
  //TODO isFinal  ??
  
  return globalID;
}

-(Class)classForObjectWithGlobalID: (EOKeyGlobalID*)globalID
{
  //near OK
  Class classForInstances = _classForInstances;


  //TODO:use globalID ??
  if (!classForInstances)
    {
      classForInstances = [self _classForInstances];
    }



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

  EOFLOGObjectLevelArgs(@"EOEntity",@"_relationshipsByName: %p %s",
                        _relationshipsByName,
                        (_relationshipsByName ? "Not NIL" : "NIL"));
  AUTORELEASE_SETNIL(_relationshipsByName);
  AUTORELEASE_SETNIL(_attributesByName);

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
  if (_flags.attributesIsLazy)
    [self attributes];

  if (!_attributesByName)
    {
      unsigned int i, c;

      _attributesByName = [[NSMutableDictionary alloc] init]; 
      for (i = 0, c = [_attributes count]; i < c; i++)
	{
	  [_attributesByName setObject:[_attributes objectAtIndex:i]
				forKey:[[_attributes objectAtIndex:i] name]];
	} 
    }

  return _attributesByName;
}

- (NSDictionary*)relationshipsByName
{
  if (_flags.relationshipsIsLazy)
    [self relationships];
  if (!_relationshipsByName)
    {
      unsigned int i, c;
      
      _relationshipsByName = [[NSMutableDictionary alloc] init]; 

      for (i = 0, c = [_relationships count]; i < c; i++)
	{
	  [_relationshipsByName setObject:[_relationships objectAtIndex:i]
				forKey:[[_relationships objectAtIndex:i] name]];
	} 
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
  if ((!_fetchSpecificationDictionary) && (_model))
  {
    ASSIGN(_fetchSpecificationDictionary, 
           [_model _loadFetchSpecificationDictionaryForEntityNamed:_name]);
  }
  return _fetchSpecificationDictionary;
}

- (void) _loadEntity
{
  [self attributes];
  [self relationships];
  [self _fetchSpecificationDictionary];
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
      NSMutableArray* tmpArray
	= AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: count]);

      NSAssert3(!attributesToFetch
		|| [attributesToFetch isKindOfClass: [NSArray class]],
                @"entity %@ attributesToFetch is not an NSArray but a %@\n%@",
                [self name],
                [attributesToFetch class],
                attributesToFetch);

      for (i = 0; i < count; i++)
        {
          EOAttribute *attribute = GDL2_ObjectAtIndexWithImpPtr(attributesToFetch,&atfOAI,i);

          if (![attribute isReadOnly])
            GDL2_AddObjectWithImpPtr(tmpArray,&sAO,[attribute name]);
        }
      writableDBSnapshotKeys=tmpArray;
    }
  else
    writableDBSnapshotKeys=GDL2_NSArray;

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
      NSMutableArray *tmpArray 
	= AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: count]);
      IMP auflOAI=NULL;
      IMP tAO=NULL;

      for (i = 0; i < count; i++)
        {
          EOAttribute *attribute = GDL2_ObjectAtIndexWithImpPtr(attributesUsedForLocking,
                                                               &auflOAI,i);
          if (![attribute isDerived])
            GDL2_AddObjectWithImpPtr(tmpArray,&tAO,attribute);
        }
      rootAttributesUsedForLocking=tmpArray;
    }
  else
    rootAttributesUsedForLocking=GDL2_NSArray;

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

- (NSMutableArray*) _hiddenRelationships
{
  if (!_hiddenRelationships)
    _hiddenRelationships = [NSMutableArray new];

  return _hiddenRelationships;
}

- (NSArray*) _propertyNames
{
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

- (EOAttribute*) _flattenAttribute: (EOAttribute*)attribute
		  relationshipPath: (NSString*)relationshipPath
		 currentAttributes: (NSDictionary*)currentAttributes
{
  EOAttribute* flattenAttribute=nil;

  //Find first available attribute name like NeededByEOF%d
  NSMutableString* aName = [NSMutableString stringWithCapacity:14];//NeededByEOF+some space
  int i = 0;
  do
    {
      [aName appendFormat:@"NeededByEOF%d",i];
      if ([currentAttributes objectForKey:aName]==nil)
	break;
      else
	{
	  [aName setString:@""];
	  i++;
	}
    } while(1);

  //Now create temporary attribute
  flattenAttribute = AUTORELEASE([EOAttribute new]);
  [flattenAttribute setName:aName];
  [flattenAttribute setEntity:self];
  [flattenAttribute _setDefinitionWithoutFlushingCaches:
		      [[relationshipPath stringByAppendingString:@"."]
			stringByAppendingString:[attribute name]]];
  [flattenAttribute setEntity:nil];
  [flattenAttribute _setValuesFromTargetAttribute];
  [flattenAttribute setEntity:self];
  return flattenAttribute;
}

- (NSString*) snapshotKeyForAttributeName: (NSString*)attributeName
{
  NSDictionary* map = [self _flattenedAttNameToSnapshotKeyMapping];
  NSString* key = [map objectForKey:attributeName];
  if (key==nil)
    key=attributeName;
  return key;
}

- (NSDictionary*) _flattenedAttNameToSnapshotKeyMapping
{
  if (_flattenedAttNameToSnapshotKeyMapping==nil)
    [self _attributesToSave];//Build the map
  return _flattenedAttNameToSnapshotKeyMapping;
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

  propertyDictionaryInitializer = [self _propertyDictionaryInitializer];

  dictionaryForProperties
    = [EOMutableKnownKeyDictionary dictionaryWithInitializer:
				propertyDictionaryInitializer];

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

  instanceDictionaryInitializer = [self _instanceDictionaryInitializer];

  // No need to build the dictionary if there's no key.
  // The only drawback I see is if someone use extraData feature of MKK dictionary
  if ([instanceDictionaryInitializer count]>0)
    {      
      dictionaryForProperties = [EOMutableKnownKeyDictionary
                                  dictionaryWithInitializer:
                                    instanceDictionaryInitializer];
    }

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

      if ([classProperty isKindOfClass: GDL2_EORelationshipClass])
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
      NSMutableArray *tmpArray 
	= AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: count]);
      IMP cpOAI=NULL;
      IMP tAO=NULL;

      for (i = 0; i < count; i++)
        {
          id object = GDL2_ObjectAtIndexWithImpPtr(classProperties,&cpOAI,i);
          
          if ([object isKindOfClass: GDL2_EOAttributeClass])
            GDL2_AddObjectWithImpPtr(tmpArray,&tAO,object);
        }
      classPropertyAttributes = tmpArray;
    }
  else
    classPropertyAttributes=GDL2_NSArray;

  return classPropertyAttributes;
}

- (NSArray*) _attributesToSave
{
  EOFLOGObjectLevelArgs(@"EOEntity",
			@"START Entity _attributesToSave entityname=%@",
			[self name]);

  if (!_attributesToSave)
    {
      EOAttribute* attribute=nil;
      NSArray *attributesToFetch = [self _attributesToFetch];
      int attributesToFetchCount = [attributesToFetch count];
      int i=0;
      NSMutableString* aName = [NSMutableString stringWithCapacity:128];
      NSMutableDictionary* attrToSaveByName = [NSMutableDictionary dictionaryWithCapacity:attributesToFetchCount];
      NSMutableDictionary* flattenAttrByPath = nil;
      NSMutableSet* processedPathes = nil;

      NSAssert3(!attributesToFetch
		|| [attributesToFetch isKindOfClass: [NSArray class]],
                @"entity %@ attributesToFetch is not an NSArray but a %@\n%@",
                [self name],
                [_attributesToFetch class],
                _attributesToFetch);

      for(i=attributesToFetchCount-1;i>=0;i--)
	{
	  attribute = [attributesToFetch objectAtIndex:i];
	  [attrToSaveByName setObject:attribute
			    forKey:[attribute name]];
	  if ([attribute isFlattened])
	    {
	      if(flattenAttrByPath == nil)
		flattenAttrByPath = [NSMutableDictionary dictionary];
	      [aName setString:@""];
	      [aName appendString:[attribute relationshipPath]];
	      [aName appendString:@"."];
              [aName appendString:[[attribute targetAttribute]name]];
	      [flattenAttrByPath setObject:attribute
				 forKey:[NSString stringWithString:aName]];
            };
	}

      //Also build _flattenedAttNameToSnapshotKeyMapping !
      if (_flattenedAttNameToSnapshotKeyMapping)
	[_flattenedAttNameToSnapshotKeyMapping removeAllObjects];
      else
	_flattenedAttNameToSnapshotKeyMapping=[NSMutableDictionary new];

      //We may modify the dictionary so enumerate on -allValues
      NSEnumerator* objectEnumerator=[[attrToSaveByName allValues]objectEnumerator];
      while((attribute=[objectEnumerator nextObject]))
	{
	  if ([attribute isFlattened])
	    {
	      NSString* relationshipPath = [attribute relationshipPath];
	      if (![processedPathes containsObject:relationshipPath])
		{
		  if (processedPathes == nil)
		    processedPathes = [NSMutableSet set];

		  [processedPathes addObject:relationshipPath];

		  EOEntity* destinationEntity = [[self relationshipForPath:relationshipPath] destinationEntity];
		  NSArray* dstPKAttrs = [destinationEntity primaryKeyAttributes];
		  int dstPKAttrsCount = [dstPKAttrs count];

		  if(dstPKAttrs == nil)
		    {
		      [NSException raise: @"NSIllegalStateException"
				   format: @"%@: entity '%@' has no primary key",
				   NSStringFromSelector(_cmd),
				   [destinationEntity name]];
		    }

		  
		  for(i=dstPKAttrsCount-1;i>=0;i--)
		    {
		      EOAttribute* dstPKAttr = [dstPKAttrs objectAtIndex:i];
		      [aName setString:@""];
		      [aName appendString:relationshipPath];
		      [aName appendString:@"."];
		      [aName appendString:[dstPKAttr name]];
		      if ([flattenAttrByPath objectForKey:aName]==nil)
			{
			  EOAttribute* flattenAttr = [self _flattenAttribute: dstPKAttr
							   relationshipPath: relationshipPath
							   currentAttributes: attrToSaveByName];
			  [attrToSaveByName setObject:flattenAttr
					    forKey:[flattenAttr name]];

			  [flattenAttrByPath setObject:flattenAttr
					     forKey:[NSString stringWithString:aName]];

			  NSDictionary* map = [attribute _sourceToDestinationKeyMap];
			  NSArray* destinationKeys = [map objectForKey:@"destinationKeys"];
			  if (destinationKeys != nil)
			    {
			      NSUInteger index=[destinationKeys indexOfObject:[dstPKAttr name]];
			      if (index!=NSNotFound)
				{
				  NSString* sourceKey = [[map objectForKey:@"sourceKeys"] objectAtIndex:index];
				  [_flattenedAttNameToSnapshotKeyMapping setObject:sourceKey
									 forKey:[flattenAttr name]];
				}
			    }
			}
		    }		  
		}
	    }
	};
      ASSIGN(_attributesToSave,([[attrToSaveByName allValues] sortedArrayUsingSelector:@selector(eoCompareOnName:)]));
    }
  return _attributesToSave;
}

-(NSArray*) _extraSingleTableAttributesToFetch:(NSArray*)alreadyFetchedAttributes
{
  NSMutableArray* extraAttributes  = [NSMutableArray array];
  NSArray* subEntities = [self subEntities];
  int subEntitiesCount = [subEntities count];
  if (subEntitiesCount>0)
    {
      NSMutableSet* seenAttributeNames = 
	[NSMutableSet setWithArray:[alreadyFetchedAttributes 
				     resultsOfPerformingSelector:@selector(name)]];
      int i=0;
      for(i=0;i<subEntitiesCount;i++)
	{
	  EOEntity* subEntity = [subEntities objectAtIndex:i];
	  NSArray* subEntityAttributesToFetch = [subEntity attributesToFetch];
	  int subEntityAttributesToFetchCount = [subEntityAttributesToFetch count];
	  if (subEntityAttributesToFetchCount>0)
	    {
	      int j=0;
	      for(j=0;j<subEntityAttributesToFetchCount;j++)
		{
		  EOAttribute* attribute = [subEntityAttributesToFetch objectAtIndex:j];
		  NSString* attributeName=[attribute name];
		  if (![seenAttributeNames containsObject:attributeName])
		    {
		      [seenAttributeNames addObject:attributeName];
		      [extraAttributes addObject:attribute];
		    }
		}
	    }
	}
    }  
  return extraAttributes;
}

//sorted by name attributes
- (NSArray*) _attributesToFetch
{
  NSAssert2(!_attributesToFetch
	    || [_attributesToFetch isKindOfClass: [NSArray class]],
            @"entity %@ attributesToFetch is not an NSArray but a %@",
            [self name],
            [_attributesToFetch class]);

  if (!_attributesToFetch)
    {
      NSArray *arrays[3] = { [self attributesUsedForLocking],
			     [self primaryKeyAttributes],
			     [self classProperties] };
      NSUInteger arraysCount[3];
      NSUInteger arraysTotalCount=0;
      int iArray=0;
      for(iArray=0;iArray<=2;iArray++)
	{
	  arraysCount[iArray]=[arrays[iArray] count];
	  arraysTotalCount+=arraysCount[iArray];
	}

      NSArray* relationships = [self relationships];
      int relationshipsCount = [relationships count];
      NSMutableDictionary* attrsByName = [NSMutableDictionary dictionaryWithCapacity:arraysTotalCount];
      NSMutableSet* flattenAttrsAndRels = [NSMutableSet setWithCapacity:relationshipsCount+arraysTotalCount/4];      

      for(iArray=0;iArray<=2;iArray++)
	{
	  NSArray* anArray = arrays[iArray];
	  int anArrayCount = arraysCount[iArray];
	  int i=0;
	  for(i=0;i<anArrayCount;i++)
	    {
	      id property = [anArray objectAtIndex:i];
	      if ([property isKindOfClass: GDL2_EOAttributeClass])
		{
		  NSString* propertyName=[property name];
		  NSAssert1(propertyName,@"No name for %@",property);
		  if ([(EOAttribute*)property isFlattened])
		    [flattenAttrsAndRels addObject:propertyName];
		  [attrsByName setObject:property
			       forKey:propertyName];
		}
	    }
	  
	}

      int i=0;
      for(i=0;i<relationshipsCount;i++)
	[flattenAttrsAndRels addObject:[[relationships objectAtIndex:i]name]];

      if ([flattenAttrsAndRels count]>0)
	{
	  NSMutableSet* processed = [NSMutableSet set];
	  NSEnumerator* enumerator = [flattenAttrsAndRels objectEnumerator];
	  id propertyName=nil;
	  while((propertyName=[enumerator nextObject]))
	    {
	      id property=[self anyAttributeNamed:propertyName];
	      if (property==nil)
		property=[self anyRelationshipNamed:propertyName];
	      NSString* relationshipPath = [property relationshipPath];
	      NSAssert1(relationshipPath,@"No relationshipPath for %@",property);
	      if (![processed containsObject:relationshipPath])
		{
		  [self _addAttributesToFetchForRelationshipPath:relationshipPath
			atts: attrsByName];
		  [processed addObject:relationshipPath];
		}
	    }
	}

      if (_flags.isSingleTableEntity)
	{
	  NSArray* attributesToFetch = [[attrsByName allValues]sortedArrayUsingSelector:@selector(eoCompareOnName:)];
	  NSArray* extraAttrs = [self _extraSingleTableAttributesToFetch:attributesToFetch];
	  int extraAttrsCount = [extraAttrs count];
	  if (extraAttrsCount>0)
	    {
	      for(i=0;i<extraAttrsCount;i++)
		{
		  EOAttribute* attribute = [extraAttrs objectAtIndex:i];
		  [attrsByName setObject:attribute
			       forKey:[attribute name]];
		}
	      
	      ASSIGN(_attributesToFetch,[[attrsByName allValues]sortedArrayUsingSelector:@selector(eoCompareOnName:)]);
	    }
	  else
	    {
	      ASSIGN(_attributesToFetch,attributesToFetch);
	    }
	}
      else
	{
	  ASSIGN(_attributesToFetch,[[attrsByName allValues]sortedArrayUsingSelector:@selector(eoCompareOnName:)]);
	}
    }

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

- (NSString*) _inverseRelationshipPathForPath: (NSString*)path
{
  NSString* inversePath = nil;
  NSArray* components = [path componentsSeparatedByString:@"."];
  int componentsCount=[components count];
  if (componentsCount>0)
    {
      EOEntity* entity = self;
      int i=0;
      for(i=0;i<componentsCount;i++)
	{
	  EORelationship* relationship = [entity relationshipNamed:[components objectAtIndex:i]];
	  EORelationship* inverseRelationship = [relationship anyInverseRelationship];
	  if(inversePath == nil)
	    inversePath=[NSMutableString string];
	  else
	    {
	      [(NSMutableString*)inversePath insertString:@"."
				 atIndex:0];
	    }
	  [(NSMutableString*)inversePath insertString:[inverseRelationship name]
			     atIndex:0];
	  entity = [relationship destinationEntity];
	}
    }
  
  return inversePath;
}

- (NSDictionary*) _keyMapForIdenticalKeyRelationshipPath: (NSString*)path
{
  NSMutableArray* sourceKeys = [NSMutableArray array];
  NSMutableArray* destinationKeys = [NSMutableArray array];
  EORelationship* relationship = nil;
  NSArray* joins = nil;
  int joinsCount = 0;
  NSRange dotPos=[path rangeOfString:@"."];  
  if (dotPos.length==0)//Not multihop
    relationship = [self relationshipNamed:path];
  else
    relationship = [self relationshipNamed:[path substringToIndex:dotPos.location]];//First component

  joins = [relationship joins];
  joinsCount = [joins count];
  if (joinsCount>0)
    {
      int i=0;
      for(i=joinsCount-1;i>=0;i--)
	{
	  EOJoin* join = [joins objectAtIndex:i];
	  EOAttribute* sourceAttribute = [join sourceAttribute];
          EOAttribute* destinationAttribute =
            [self _mapAttribute:sourceAttribute 
                  toDestinationAttributeInLastComponentOfRelationshipPath: path];
	  [sourceKeys addObject:[sourceAttribute name]];
	  [destinationKeys addObject:[destinationAttribute name]];
	}
    }
  return [NSDictionary dictionaryWithObjectsAndKeys:
			 sourceKeys, @"sourceKeys",
		       destinationKeys, @"destinationKeys",
		       nil, nil];
}

- (NSDictionary *)_keyMapForRelationshipPath: (NSString *)path
{
  NSDictionary* keyMap=nil;
  NSMutableArray* sourceKeys = nil;
  NSMutableArray* destinationKeys = nil;

  NSRange dotPos=[path rangeOfString:@"."
		       options:NSBackwardsSearch];
  if (dotPos.length==0)//Not multihop relationshipPath
    {
      EORelationship* relationship = [self anyRelationshipNamed:path];
      NSArray* joins = [relationship joins];
      int i=0;
      sourceKeys = [NSMutableArray array];
      destinationKeys = [NSMutableArray array];
      for(i=[joins count]-1;i>=0;i--)
	{
	  EOJoin* join = [joins objectAtIndex:i];
	  [sourceKeys addObject:[[join sourceAttribute] name]];
	  [destinationKeys addObject:[[join destinationAttribute] name]];
	}
    } 
  else
    {
      if ([self _relationshipPathHasIdenticalKeys:path])
	keyMap=[self _keyMapForIdenticalKeyRelationshipPath:path];
      else
	{
	  NSArray* attributesToFetch = [self _attributesToFetch];
	  int attributesToFetchCount=[attributesToFetch count];
	  EORelationship* relationship = [self relationshipForPath:path];
	  NSArray* joins = [relationship joins];
	  int joinsCount = [joins count];
	  int i = 0;

	  sourceKeys = [NSMutableArray array];
	  destinationKeys = [NSMutableArray array];

	  //Path without last component
	  NSString* beginingPath = [path substringToIndex:dotPos.location];

	  for(i=joinsCount-1;i>=0;i--)
	    {
	      EOJoin* join = [joins objectAtIndex:i];
	      EOAttribute* sourceAttribute = [join sourceAttribute];
	      EOAttribute* destinationAttribute = [join destinationAttribute];
	      EOAttribute* finalSourceAttribute = nil;
	      int j=0;
	      for(j=attributesToFetchCount-1;j>=0;j--)
		{
		  finalSourceAttribute = [attributesToFetch objectAtIndex:j];
		  if ([finalSourceAttribute targetAttribute] == sourceAttribute 
		      && [[finalSourceAttribute relationshipPath] isEqualToString:beginingPath]
		      && ![finalSourceAttribute isReadOnly])
		    break;
		}
	      
	      if (finalSourceAttribute == nil)
		{
		  [NSException raise: @"NSIllegalStateException"
			       format: @"%@ entity '%@' is unable to build internal key map for relationship path '%@'",
			       NSStringFromSelector(_cmd),
			       [self name],
			       path];
		}
	      [sourceKeys addObject:[finalSourceAttribute name]];
	      [destinationKeys addObject:[destinationAttribute name]];
	    }
	}  
    }
  if (!keyMap)
    {
      keyMap=[NSDictionary dictionaryWithObjectsAndKeys:
			     sourceKeys, @"sourceKeys",
			   destinationKeys, @"destinationKeys",
			   nil];
    }
  return keyMap;
 }

- (EOAttribute *)_mapAttribute: (EOAttribute *)attribute
toDestinationAttributeInLastComponentOfRelationshipPath: (NSString *)path
{
  EOAttribute* resultAttribute=attribute;
  NSArray *components = nil;

  NSAssert(attribute, @"No attribute");
  NSAssert(path, @"No path");
  NSAssert([path length] > 0, @"Empty path");

  components = [path componentsSeparatedByString: @"."];

  int componentsCount=[components count];
  if (componentsCount>0)
    {
      EOEntity *entity = self;
      NSUInteger i=0;
      for(i=0;i<componentsCount;i++)
	{
	  EORelationship* relationship = [entity relationshipNamed: [components objectAtIndex:i]];
	  NSArray* sourceAttributes = [relationship sourceAttributes];
	  NSArray* destinationAttributes = [relationship destinationAttributes];
	  NSUInteger index = [sourceAttributes indexOfObjectIdenticalTo:resultAttribute];
          if(index == NSNotFound)
	    {
	      [NSException raise: @"NSIllegalStateException"
			   format: @"%@ entity '%@' is unable to map attribute along relationship path '%@'",
			   NSStringFromSelector(_cmd),
			   [self name],
			   path];
	    }
	  else
	    {
	      resultAttribute = [destinationAttributes objectAtIndex:index];
	      entity = [relationship destinationEntity];
	    }
	}
    }

  return resultAttribute;
}

- (BOOL) _relationshipPathIsToMany: (NSString*)relPath
{
  BOOL isToMany = NO;
  NSArray *parts = [relPath componentsSeparatedByString: @"."];
  EOEntity *entity = self;
  int i, count = [parts count];

  for (i = 0 ;i < count; i++)
    {
      EORelationship *rel = [entity relationshipNamed:
				      [parts objectAtIndex: i]];

      isToMany = [rel isToMany];

      if (isToMany)
	break;
      else
        entity = [rel destinationEntity];
    }

  return isToMany;
}

 - (BOOL) _relationshipPathHasIdenticalKeys: (NSString*)path
{
  BOOL has=YES;
  NSArray* components = [path componentsSeparatedByString:@"."];
  int componentsCount = [components count];
  if (componentsCount>0)
    {
      EOEntity* entity = self;
      NSArray* destinationAttributes = nil;
      int i = 0;
      for(i=0;i<componentsCount;i++)
	{
	  EORelationship* relationship = [entity anyRelationshipNamed:[components objectAtIndex:i]];
	  if(i>0)
            {
	      NSArray* sourceAttributes = [relationship sourceAttributes];
	      if(![destinationAttributes containsIdenticalObjectsWithArray:sourceAttributes])
		{
		  has=NO;
		  break;
		}
            }
	  destinationAttributes = [relationship destinationAttributes];
	  entity = [relationship destinationEntity];
        }
    }
  return has;
}
 
@end

@implementation EOEntity (EOEntitySQLExpression)

- (NSString*) valueForSQLExpression: (EOSQLExpression*)sqlExpression
{
  if (sqlExpression == nil)
    return _externalName;
  else
    return [sqlExpression sqlStringForSchemaObjectName:_externalName];
}

@end

@implementation EOEntity (MethodSet11)

- (NSException *)validateObjectForDelete: (id)object
{
  NSMutableArray* exceptions = nil;
  NSArray* relationships = [self relationships];
  int relationshipsCount = [relationships count];
  if (relationshipsCount>0)
    {
      NSArray* classProperties = [self classProperties];
      int i=0;
      for(i=0;i<relationshipsCount;i++)
        {
	  EORelationship* relationship = [relationships objectAtIndex:i];
	  if ([relationship deleteRule] == EODeleteRuleDeny
	      && [classProperties containsObject:relationship])
            {
	      id value = [object valueForKey:[relationship name]];
	      if (value != nil)
		{
		  if ([relationship isToMany])
                    {
		      if ([(NSArray*)value count]>0)
			{
			  if (!exceptions)
			    exceptions = [NSMutableArray arrayWithCapacity:5];

			  [exceptions addObject:
					[NSException validationExceptionWithFormat:
						       @"Removal of '%@' object denied: in its '%@' relationship because there are related objects",
						     [object entityName],
						     [relationship name]]];
			}
                    }
		  else
                    {
		      if (!exceptions)
			exceptions = [NSMutableArray arrayWithCapacity:5];
		      
		      [exceptions addObject:
				    [NSException validationExceptionWithFormat:
						   @"Removal of '%@' object denied: in its '%@' relationship because there is a related object",
						 [object entityName],
						 [relationship name]]];
		    }
		}
	    }
	}
    }
  if (exceptions)
    return [NSException aggregateExceptionWithExceptions:exceptions];
  else
    return nil;
}

/** Retain an array of name of all EOAttributes **/
- (NSArray*) classPropertyAttributeNames
{
  if (!_classPropertyAttributeNames)
    {
      int i=0;
      NSArray *classProperties = [self classProperties];
      int count = [classProperties count];

      _classPropertyAttributeNames = [NSMutableArray new]; 
      
      for (i = 0; i < count; i++)
        {
          EOAttribute *property = [classProperties objectAtIndex: i];
          
          if ([property isKindOfClass: GDL2_EOAttributeClass])
            [(NSMutableArray*)_classPropertyAttributeNames
                              addObject: [property name]];
        };
    }

  return _classPropertyAttributeNames;
}

- (NSArray*) classPropertyToManyRelationshipNames
{
  if (!_classPropertyToManyRelationshipNames)
    {
      NSArray *classProperties = [self classProperties];
      int i, count = [classProperties count];

      _classPropertyToManyRelationshipNames = [NSMutableArray new];

      for (i = 0; i < count; i++)
        {
          EORelationship *property = [classProperties objectAtIndex: i];

          if ([property isKindOfClass:GDL2_EORelationshipClass]
	      && [property isToMany])
            [(NSMutableArray*)_classPropertyToManyRelationshipNames
			      addObject: [property name]];
        }
    }

  return _classPropertyToManyRelationshipNames;
}

- (NSArray*) classPropertyToOneRelationshipNames
{
  if (!_classPropertyToOneRelationshipNames)
    {
      NSArray *classProperties = [self classProperties];
      int i, count = [classProperties count];

      _classPropertyToOneRelationshipNames = [NSMutableArray new]; //or GC ?

      for (i = 0; i <count; i++)
        {
          EORelationship *property = [classProperties objectAtIndex: i];

          if ([property isKindOfClass:GDL2_EORelationshipClass]
	      && ![property isToMany])
            [(NSMutableArray*)_classPropertyToOneRelationshipNames
			      addObject: [property name]];
        }
    }

  return _classPropertyToOneRelationshipNames;
}

- (EOQualifier*) qualifierForDBSnapshot:(NSDictionary*)dbSnapshot
{
  return [self  qualifierForPrimaryKey:dbSnapshot];
}

- (void) _addAttributesToFetchForRelationshipPath: (NSString*)relPath
                                             atts: (NSMutableDictionary*)attributes
{
  NSRange r=[relPath rangeOfString:@"."];
  BOOL isMultiHopRelPath = (r.length>0);
  if (!isMultiHopRelPath
      || [self _relationshipPathIsToMany:relPath]
      || [self _relationshipPathHasIdenticalKeys:relPath])
    {
      NSString* firstPathComponent = 
	(isMultiHopRelPath ? [relPath substringToIndex:r.location] : relPath);
      EORelationship* relationship = [self relationshipNamed:firstPathComponent];
      NSArray* joins = [relationship joins];
      int joinsCount = [joins count];
      if (joinsCount>0)
	{
	  int i = 0;
	  for(i=0;i<joinsCount;i++)
	    {
	      EOAttribute* sourceAttribute =[[joins objectAtIndex:i] sourceAttribute];
	      NSString* sourceAttributeName = [sourceAttribute name];
	      if ([attributes objectForKey:sourceAttributeName]==nil)
		{
		  [attributes setObject:sourceAttribute
			      forKey:sourceAttributeName];
		}
	    }
	}
    }
  else
    {
      EORelationship* relationship = [self relationshipForPath:relPath];
      NSString* firstPathComponents = [relPath relationshipPathByDeletingLastComponent];
      NSArray* joins = [relationship joins];
      int joinsCount = [joins count];
      if (joinsCount>0)
	{
	  int i = 0;
	  for(i=0;i<joinsCount;i++)
	    {
	      EOAttribute* sourceAttribute = [[joins objectAtIndex:i] sourceAttribute];
	      NSEnumerator* attributesEnum = [attributes objectEnumerator];
	      EOAttribute* attribute = nil;
	      EOAttribute* foundAttribute = nil;
	      while((attribute=[attributesEnum nextObject]))
		{
		  EOAttribute* targetAttribute = [attribute targetAttribute];
		  if (targetAttribute == sourceAttribute
		      && [[attribute relationshipPath] isEqual:firstPathComponents]
		      && ![attribute isReadOnly])
		    {
		      foundAttribute = attribute;
		      break;
		    }
		}

	      if (foundAttribute == nil)
		{
		  EOAttribute* anAttribute = [self _flattenAttribute:sourceAttribute
						   relationshipPath:firstPathComponents
						   currentAttributes:attributes];
		  [attributes setObject:anAttribute
			      forKey: [anAttribute name]];
		}
	    }
	}
    }
}

- (NSArray*) dbSnapshotKeys
{
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
             [NSArray arrayWithArray: [attributesToFetch
					resultsOfPerformingSelector:
					  @selector(name)]]);
    }

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
      NSMutableArray* tmpArray
	= AUTORELEASE([GDL2_alloc(NSMutableArray) initWithCapacity: count]);

      for (i = 0; i < count; i++)
        {
          EOAttribute *attribute = GDL2_ObjectAtIndexWithImpPtr(attributesToFetch,&atfOAI,i);

          if ([attribute isFlattened])
            GDL2_AddObjectWithImpPtr(tmpArray,&tAO,attribute);
        };
      flattenedAttributes=tmpArray;
    }
  else
    flattenedAttributes=GDL2_NSArray;

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
              
                  objectToken = GDL2_StringWithCStringAndLength(start,
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

                  GDL2_AddObjectWithImpPtr(expressionArray,&eaAO,objectToken);
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
                                     format: @"%@ -- %@ 0x%p: unterminated character string",
                                     NSStringFromSelector(_cmd),
                                     NSStringFromClass([self class]),
                                     self];
                    }
                }

              if (s != start)
                {
                  objectToken = GDL2_StringWithCStringAndLength(start,
                                                               (unsigned)(s - start));

                  EOFLOGObjectLevelArgs(@"EOEntity", @"addObject O Token: '%@'",
					objectToken);

                  GDL2_AddObjectWithImpPtr(expressionArray,&eaAO,objectToken);
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
          NSAssert2([relationship isKindOfClass: GDL2_EORelationshipClass],
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
                       format: @"%@ -- %@ 0x%p: entity name=%@: relationship \"%@\" used in \"%@\" doesn't exist in entity \"%@\"",
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

  return expressionArray;
}

- (id) _parsePropertyName: (NSString*)propertyName
{
  EOEntity *entity = self;
  EOExpressionArray *expressionArray = nil;
  NSArray *components = nil;
  int i, count = 0;

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
          NSAssert2([relationship isKindOfClass: GDL2_EORelationshipClass],
                    @"relationship is not a EORelationship but a %@. relationship:\n%@",
                    [relationship class],
                    relationship);

          if ([relationship isFlattened])
            {
	      [expressionArray addObjectsFromArray: [relationship _definitionArray]];
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
                           format: @"%@ -- %@ 0x%p: attribute \"%@\" used in \"%@\" doesn't exist in entity %@",
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



  return expressionArray;
}

+(void) _assertNoPropagateKeyCycleWithEntities:(NSMutableArray*)entities
				 relationships:(NSMutableArray*)relationships
{
  EOEntity* entity = [entities lastObject];
  NSArray* entityRelationships = [entity relationships];
  int i=0;
  for(i = [entityRelationships count] - 1; i >= 0; i--)
    {
      EORelationship* relationship = [entityRelationships objectAtIndex:i];
      if ([relationship propagatesPrimaryKey])
	{
	  EOEntity* dstEntity=[relationship destinationEntity];
	  if ([entities containsObject:dstEntity])
	    {
	      NSMutableString* tmpString=[NSMutableString string];
	      int j=0;
	      int c=[relationships count];
	      for(j = 0; j < c; j++)
		{
		  [tmpString appendFormat:@"\n\tEntity: %@ Relationship: %@ => ",
			     [[entities objectAtIndex:j] name],
			     [[relationships objectAtIndex:j] name]];
		}
	      
	      [tmpString appendFormat:@"\n\tEntity: %@ Relationship: %@ => \n\tEntity: %@",
			 [[entities lastObject] name],
			 [relationship name],
			 [dstEntity name]];
	       [NSException raise: @"NSIllegalStateException"
			    format:@"%@ EOEntity propagation cycle discovered in model group while attempting to save. Check your model group and break the following cycle: %@",
			    NSStringFromSelector(_cmd),
			    tmpString];
	    }
	  [relationships addObject:relationship];
	  [entities addObject:dstEntity];
	  [self _assertNoPropagateKeyCycleWithEntities:entities
		relationships:relationships];
	  [relationships removeLastObject];
	  [entities removeLastObject];
	}
    }  
}

-(void)_clearAttributesCaches
{
  _flags.nonUpdateableAttributesInitialized = NO;
}

//MG2014: OK
-(BOOL)_hasNonUpdateableAttributes
{
  if(!_flags.nonUpdateableAttributesInitialized)
    {
      NSArray* attributes = [self attributes];
      NSUInteger attributesCount=[attributes count];
      _flags.nonUpdateableAttributes=NO;
      if (attributesCount>0)
	{
	  NSUInteger i=0;
	  for(i=0;i<attributesCount;i++)
	    {
	      if ([[attributes objectAtIndex:i] _isNonUpdateable])
		{
		  _flags.nonUpdateableAttributes=YES;
		  break;
		}
	    }
	}
      _flags.nonUpdateableAttributesInitialized = YES;
    }
  return _flags.nonUpdateableAttributes;
}
@end

@implementation EOEntity (EOEntityPrivateSingleEntity)
- (BOOL) _isSingleTableEntity
{
  return _flags.isSingleTableEntity;
}

- (EOQualifier*) _singleTableRestrictingQualifier
{
  if (_singleTableRestrictingQualifier == nil)
    {
      NSArray* subEntities = [self subEntities];
      NSUInteger subEntitiesCount=[subEntities count];
      NSUInteger i=0;
      NSMutableArray* qualifiers = [NSMutableArray array];
 
      if (_restrictingQualifier != nil)
	[qualifiers addObject:_restrictingQualifier];

      for(i=0;i<subEntitiesCount;i++)
	{
	  EOQualifier* qualifier = [[subEntities objectAtIndex:i] _singleTableRestrictingQualifier];
	  if (qualifier != nil)
	    [qualifiers addObject:qualifier];
	}
      
      if ([qualifiers count]>0)
	_singleTableRestrictingQualifier = [EOOrQualifier qualifierWithQualifierArray:qualifiers];
    }
  return _singleTableRestrictingQualifier;
}

//MG2014: OK
-(NSString*)_singleTableSubEntityKey
{
  if (_singleTableSubEntityKey == nil
      && _restrictingQualifier != nil
      && [_restrictingQualifier isKindOfClass:[EOKeyValueQualifier class]]
      && sel_isEqual([(EOKeyValueQualifier*)_restrictingQualifier selector],EOQualifierOperatorEqual))
    {
      ASSIGN(_singleTableSubEntityKey,([(EOKeyValueQualifier*)_restrictingQualifier key]));
    }
  return _singleTableSubEntityKey;
}

//MG2014: OK ??
-(id)_subEntityKeyValue
{
  id value=nil;
  if (_restrictingQualifier != nil)
    {
      value = [(EOKeyValueQualifier*)_restrictingQualifier value];
      if (value == nil)
	value=GDL2_EONull;
    }
  return value;
}

//MG2014: OK
-(void)_generateSingleTableSubEntityDictionary:(NSMutableDictionary*)d
{
  NSArray* subEntities = [self subEntities];
  NSUInteger subEntitiesCount=[subEntities count];
  if (subEntitiesCount>0)
    {
      NSUInteger i=0;
      for(i = 0; i<subEntitiesCount; i++)
	{
	  [[subEntities objectAtIndex:i] _generateSingleTableSubEntityDictionary:d];
	}
    }
  id value = [self _subEntityKeyValue];
  if (value != nil)
    {
      [d setObject:self
	 forKey:value];
    }
  ASSIGN(_singleTableSubEntityDictionary,d);
}

//MG2014: OK
-(NSDictionary*)_singleTableSubEntityDictionary
{
  if (_flags.isSingleTableEntity)
    {
      if (_singleTableSubEntityDictionary == nil)
	{
	  NSMutableDictionary* d = [NSMutableDictionary dictionary];
	  [self _generateSingleTableSubEntityDictionary:d];
	}
      return _singleTableSubEntityDictionary;
    }
  else
    return nil;
}

//MG2014: OK
-(EOEntity*) _singleTableSubEntityForRow:(NSDictionary*)row
{
  NSDictionary* d = [self _singleTableSubEntityDictionary];
  if (d != nil)
    {
      NSString* key = [self _singleTableSubEntityKey];
      if (key != nil)
	{
	  id value = [row objectForKey:key];
	  if (value != nil)
	    return [d objectForKey:value];
	}
    }
  return nil;
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
  DESTROY(_entity);

  [super dealloc];
}

- (NSString *) description
{
  return [NSString stringWithFormat: @"<%s %p - Entity: %@>",
                   object_getClassName(self),
                   self,
                   [self entityName]];
}

- (EOEntity *)entity
{
  return _entity;
}

- (EOFetchSpecification *)fetchSpecificationNamed: (NSString *)name
{
  return [_entity fetchSpecificationNamed:name];
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

  [super awakeObject: object
	 fromFetchInEditingContext: context];
  //nothing to do

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



  [super awakeObject: object
         fromInsertionInEditingContext: context];

  relationships = [_entity relationships];
  classProperties = [_entity classProperties];
  count = [relationships count];

  for (i = 0; i < count; i++)
    {
      relationship = GDL2_ObjectAtIndexWithImpPtr(relationships,&relOAI,i);

      if ([classProperties containsObject: relationship])
	{
	  if ([relationship isToMany])
	    {
	      NSString *name = [relationship name];
	      id relationshipValue = 
                GDL2_StoredValueForKeyWithImpPtr(object,&objectSVFK,name);

	      /* We put a value only if there's not already one */
	      if (relationshipValue == nil)
		{
		  /* [Ref: Assigns empty arrays to to-many 
		     relationship properties of newly inserted 
		     enterprise objects] */
		  GDL2_TakeStoredValueForKeyWithImpPtr(object,&objectTSVFK,
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
                    = GDL2_ValueForKeyWithImpPtr(object,&objectVFK,name);

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

}

- (EOClassDescription *)classDescriptionForDestinationKey: (NSString *)detailKey
{
  EORelationship *rel = [_entity relationshipNamed: detailKey];
  EOEntity *destEntity = [rel destinationEntity];
  EOClassDescription *cd = [destEntity classDescriptionForInstances];
  return cd;
}

- (id)createInstanceWithEditingContext: (EOEditingContext *)editingContext
                              globalID: (EOGlobalID *)globalID
                                  zone: (NSZone *)zone
{
  id obj = nil;
  Class objectClass;
  
  NSAssert1(_entity, @"No _entity in %@", self);
  
  objectClass = [_entity classForObjectWithGlobalID: (EOKeyGlobalID*)globalID];
  
  NSAssert2(objectClass, @"No objectClass for globalID=%@. EntityName=%@",
            globalID, [_entity name]);
  
  if (objectClass)
    {
      obj = AUTORELEASE([[objectClass allocWithZone:zone]
			  initWithEditingContext: editingContext
			  classDescription: self
			  globalID: globalID]);
    }
  
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
  EORelationship *rel = [_entity relationshipNamed: relationshipKey];
  EODeleteRule deleteRule = [rel deleteRule];

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
  EOAttribute *attr = nil;

  NSAssert(valueP, @"No value pointer");
  attr = [_entity attributeNamed: key];

  if (attr)
    exception = [attr validateValue: valueP];
  else
    {
      EORelationship* relationship = [_entity relationshipNamed: key];
      if (relationship)
	exception = [relationship validateValue: valueP];
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



  NSAssert(_entity,@"No entity");

  dict = [_entity _dictionaryForInstanceProperties];



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
  NSString* name=nil;
  NSRange dotPos=[externalName rangeOfString:@"."];
  if (dotPos.length==0
      && ![externalName isEqualToString:[externalName lowercaseString]]
      && ![externalName isEqualToString:[externalName uppercaseString]])
    {
      if(!initialCaps 
	 && uni_toupper([externalName characterAtIndex:0])==[externalName characterAtIndex:0])//is uppercase first character ?
	{
	  name=[[[externalName substringToIndex:1] lowercaseString] 
		 stringByAppendingString:[externalName substringFromIndex:1]];
	}
      else
	name=externalName;
    }
  else
    {
      name=[NSMutableString stringWithCapacity:[externalName length]];
      NSArray* parts = [externalName componentsSeparatedByString: separatorString];
      int partsCount = [parts count];
      int i=0;
      BOOL isFirst = YES;
      for(i = 0; i < partsCount; i++)
        {
	  NSString* part = [parts objectAtIndex:i];
	  if ([part length]>0)
            {
	      if(!initialCaps 
		 && isFirst)
                {
		  part = [part lowercaseString];
		  isFirst = NO;
                }
	      else
                {
		  part = [part capitalizedString];
                }
	      [(NSMutableString*)name appendString:part];
            }
        }
      name=[NSString stringWithString:name];
    }
  return name;
}

- (NSString*)stringByMarkingUpcaseTransitionsWithDelimiter:(NSString*)delimiter
{
  NSString* result=nil;
  int len = [self length];
  if (len==0)
    result=[NSString string];
  else
    {
      int sepLen = [delimiter length];
      int i, outlen = 0;
      unichar* selfChars=malloc(sizeof(unichar));
      unichar* resultChars=NULL;
      BOOL lastWasLower = NO;
      
      NSAssert(selfChars,@"Can't alloc");
      
      resultChars=malloc(sizeof(unichar)*len*(sepLen+1));
      if (resultChars==NULL)
	{
	  free(selfChars);
	  NSAssert(NO,@"Can't alloc");
	}
      
      
      [self getCharacters:selfChars];
      
      // We insert separator at all lower to upper transitions
      for (i = 0; i < len; i++)
	{
	  unichar c = selfChars[i];
	  if (c==uni_toupper(c))
	    {
	      if (lastWasLower
		  && i != 0)
		{
		  // lower to UPPER transition!
		  [delimiter getCharacters:resultChars+outlen];
		  outlen += sepLen;
		}
	      lastWasLower = NO;
	    }
	  else 
	    lastWasLower = YES;
	  resultChars[outlen++] = c;
	}	
      result = [NSString stringWithCharacters:resultChars
			 length:outlen];
    }
  return result;
}

+ (NSString *)externalNameForInternalName: (NSString *)internalName
                          separatorString: (NSString *)separatorString
                               useAllCaps: (BOOL)allCaps
{
  NSString* s = [internalName stringByMarkingUpcaseTransitionsWithDelimiter:separatorString];
  return (allCaps ? [s uppercaseString] : [s lowercaseString]);
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
