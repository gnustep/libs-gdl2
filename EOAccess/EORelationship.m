/** 
   EORelationship.m <title>EORelationship</title>

   Copyright (C) 2000-2002,2003,2004,2005 Free Software Foundation, Inc.

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

RCS_ID("$Id$")

#ifdef GNUSTEP
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSObjCRuntime.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#include <GNUstepBase/NSObject+GNUstepBase.h>
#endif

#include <EOControl/EOObserver.h>
#include <EOControl/EOMutableKnownKeyDictionary.h>
#include <EOControl/EONSAddOns.h>
#include <EOControl/EODebug.h>

#include <EOAccess/EOModel.h>
#include <EOAccess/EOModelGroup.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOStoredProcedure.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOJoin.h>
#include <EOAccess/EOExpressionArray.h>

#include "EOPrivate.h"
#include "EOAttributePriv.h"
#include "EOEntityPriv.h"

@interface EORelationship (EORelationshipPrivate)
- (void)_setInverseRelationship: (EORelationship *)relationship;
@end


@implementation EORelationship

+ (void)initialize
{
  static BOOL initialized = NO;
  if (!initialized)
    {
      initialized = YES;

      GDL2_EOAccessPrivateInit();
    }
}

/*
 this is used for key-value observing.
 */

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
  if ([theKey isEqualToString:@"joins"]) {
    return NO;
  } 
  return [super automaticallyNotifiesObserversForKey:theKey];
}

+ (id) relationshipWithPropertyList: (NSDictionary *)propertyList
                              owner: (id)owner
{
  return AUTORELEASE([[self alloc] initWithPropertyList: propertyList
				   owner: owner]);
}

+ (EOJoinSemantic) _joinSemanticForName:(NSString*) semanticName
{
  if ([semanticName isEqual: @"EOInnerJoin"])
    return EOInnerJoin;
  else if ([semanticName isEqual: @"EOFullOuterJoin"])
    return EOFullOuterJoin;
  else if ([semanticName isEqual: @"EOLeftOuterJoin"])
    return EOLeftOuterJoin;
  else if ([semanticName isEqual: @"EORightOuterJoin"])
    return EORightOuterJoin;
  else 
  {
    [NSException raise: NSInvalidArgumentException
                format: @"%s: Unknown joinSemantic '%@'", __PRETTY_FUNCTION__, semanticName];
    
  }
  // make the compiler happy
  return EOInnerJoin;
}

+ (NSString *) _nameForJoinSemantic:(EOJoinSemantic) semantic
{
  switch (semantic)
  {
    case EOInnerJoin:
      return @"EOInnerJoin";
      
    case EOFullOuterJoin:
      return @"EOFullOuterJoin";
      
    case EOLeftOuterJoin:
      return @"EOLeftOuterJoin";
      
    case EORightOuterJoin:
      return @"EORightOuterJoin";
  }
  
  [NSException raise: NSInvalidArgumentException
              format: @"%s: Unknown joinSemantic '%d'", __PRETTY_FUNCTION__, semantic];
  
  // make the compiler happy
  return nil;
  
}

- (id)init
{
//OK
  if ((self = [super init]))
    {
      /*
      _sourceNames = [NSMutableDictionary new];
      _destinationNames = [NSMutableDictionary new];
      _userInfo = [NSDictionary new];
      _sourceToDestinationKeyMap = [NSDictionary new];
      */
      _joins = [NSMutableArray new];

    }

  return self;
}

- (void)dealloc
{
  [self _flushCache];

  DESTROY(_name);
  DESTROY(_qualifier);
  DESTROY(_sourceNames);
  DESTROY(_destinationNames);
  DESTROY(_userInfo);
  DESTROY(_internalInfo);
  DESTROY(_docComment);
  DESTROY(_joins);
  DESTROY(_sourceToDestinationKeyMap);
  DESTROY(_sourceRowToForeignKeyMapping);

  DESTROY(_definitionArray);

  _entity = nil;
  _destination = nil;
  
  [super dealloc];
}

- (NSUInteger)hash
{
  return [_name hash];
}

- (id) initWithPropertyList: (NSDictionary *)propertyList
                      owner: (id)owner
{
  //Near OK
  if ((self = [self init]))
    {
      EOModel* model = [owner model];
      NSString* relationshipName = [propertyList objectForKey: @"name"];
      NSString* joinSemanticString = nil;
      NSString* destinationEntityName = nil;
      EOEntity* destinationEntity = nil;
      NSString* deleteRuleString = nil;

      /* so setName: can validate against the owner */
      [self setEntity: owner];
      [self setName: relationshipName]; 

      destinationEntityName = [propertyList objectForKey: @"destination"];
      if (destinationEntityName) //If not, this is because it's a definition
        {
          destinationEntity = [model entityNamed: destinationEntityName];

          _destination = destinationEntity;
        }

      [self setToMany: [[propertyList objectForKey: @"isToMany"]
			 isEqual: @"Y"]];
      [self setIsMandatory: [[propertyList objectForKey: @"isMandatory"]
			      isEqual:@"Y"]];
      [self setOwnsDestination: [[propertyList
				   objectForKey: @"ownsDestination"]
				  isEqual: @"Y"]];
      [self setPropagatesPrimaryKey: [[propertyList
					objectForKey: @"propagatesPrimaryKey"]
				       isEqual: @"Y"]];
      [self setIsBidirectional: [[propertyList objectForKey: @"isBidirectional"]
				  isEqual: @"Y"]];

      [self setUserInfo: [propertyList objectForKey: @"userInfo"]];

      if(!_userInfo)
        [self setUserInfo: [propertyList objectForKey: @"userDictionary"]];

      [self setInternalInfo: [propertyList objectForKey: @"internalInfo"]];
      [self setDocComment: [propertyList objectForKey: @"docComment"]];

      joinSemanticString = [propertyList objectForKey: @"joinSemantic"];
      if (joinSemanticString)
      {
        [self setJoinSemantic: [[self class] _joinSemanticForName:joinSemanticString]];        
      }
      else
      {
          if (destinationEntityName)
            {
              EOFLOGObjectLevelArgs(@"EORelationship", @"!joinSemanticString but destinationEntityName. entityName=%@ relationshipName=%@",
				    [(EOEntity*)owner name],
				    relationshipName);
              NSEmitTODO(); //TODO
              [self notImplemented: _cmd]; //TODO
            }
        }

      deleteRuleString = [propertyList objectForKey: @"deleteRule"];
      EOFLOGObjectLevelArgs(@"EORelationship", @"entityName=%@ relationshipName=%@ deleteRuleString=%@",
			    [(EOEntity*)owner name],
			    relationshipName,
			    deleteRuleString);

      if (deleteRuleString)
        {
          EODeleteRule deleteRule = [self _deleteRuleFromString:
					    deleteRuleString];
          EOFLOGObjectLevelArgs(@"EORelationship",
				@"entityName=%@ relationshipName=%@ deleteRule=%d",
				[(EOEntity*)owner name],
				relationshipName,
				(int)deleteRule);
          NSAssert2(deleteRule >= 0 && deleteRule <= 3,
		    @"Bad deleteRule numeric value: %@ (%d)",
		    deleteRuleString,
		    deleteRule);

          [self setDeleteRule: deleteRule];
        }
    }



  return self;
}

- (void)awakeWithPropertyList: (NSDictionary *)propertyList  //TODO
{
  NSString *definition = [propertyList objectForKey: @"definition"];

  EOFLOGObjectLevelArgs(@"EORelationship", @"definition=%@", definition);

  if (definition)
    {
      [self setDefinition: definition];
    }
  else
    {
      NSString *dataPath = [propertyList objectForKey: @"dataPath"];

      EOFLOGObjectLevelArgs(@"EORelationship", @"dataPath=%@", dataPath);

      if (dataPath)
        {
          NSEmitTODO(); //TODO
          [self notImplemented: _cmd]; // TODO
        }
      else
        {
          NSArray *joins = [propertyList objectForKey: @"joins"];
          int count = [joins count];

          EOFLOGObjectLevelArgs(@"EORelationship", @"joins=%@", joins);

          if (count > 0)
            {
              int i;

              for (i = 0; i < count; i++)
                {
                  NSDictionary *joinPList = 
		    [joins objectAtIndex: i];
                  /*NSString *joinSemantic = 
		    [joinPList objectForKey: @"joinSemantic"];*/
                  NSString *sourceAttributeName = 
		    [joinPList objectForKey:@"sourceAttribute"];
                  EOAttribute *sourceAttribute = 
		    [_entity attributeNamed:sourceAttributeName];		    
                  EOEntity *destinationEntity = 
		    [self destinationEntity];
                  NSString *destinationAttributeName = 
		    [joinPList objectForKey:@"destinationAttribute"];
                  EOAttribute *destinationAttribute = 
		    [destinationEntity attributeNamed:destinationAttributeName];
                  EOJoin *join = nil;

                  NSAssert4(sourceAttribute, @"No sourceAttribute named \"%@\" in entity \"%@\" in relationship %@\nEntity: %@",
                            sourceAttributeName,
                            [_entity name],
                            self,
                            _entity);

                  NSAssert3(destinationEntity,@"No destination entity for relationship named '%@' in entity named '%@': %@",
                            [self name],
                            [[self entity]name],
                            self);

                  NSAssert4(destinationAttribute, @"No destinationAttribute named \"%@\" in entity \"%@\" in relationship %@\nEntity: %@",
                            destinationAttributeName,
                            [destinationEntity name],
                            self,
                            destinationEntity);

                  NS_DURING
                    {
                      join = [EOJoin joinWithSourceAttribute: sourceAttribute
				     destinationAttribute: destinationAttribute];
                    }
                  NS_HANDLER
                    {
                      [NSException raise: NSInvalidArgumentException
                                   format: @"%@ -- %@ 0x%p: cannot create join for relationship '%@': %@", 
                                   NSStringFromSelector(_cmd), 
                                   NSStringFromClass([self class]), 
                                   self, 
                                   [self name], 
                                   [localException reason]];
                    }
                  NS_ENDHANDLER;

                  EOFLOGObjectLevelArgs(@"EORelationship", @"join=%@", join);

                  [self addJoin: join];
                }
            }
          /*
            NSArray *array;
            NSEnumerator *enumerator;
            EOModel *model = [_entity model];
            id joinPList;
            
            if(_destination)
            {
            id destinationEntityName = [_destination autorelease];
            
            _destination = [[model entityNamed:destinationEntityName] retain];
            if(!_destination)
            {
          NSEmitTODO();  //TODO
            [self notImplemented:_cmd]; // TODO
            }
            }
          */
        }
    }
  /* ??
  if(!(_destination || _definitionArray))
    {
          NSEmitTODO();  //TODO
      [self notImplemented:_cmd]; // TODO
    };
  */


}

- (void)encodeIntoPropertyList: (NSMutableDictionary *)propertyList
{
  NS_DURING //Just for debugging
    {
      //VERIFY
      [propertyList setObject: [self name]
                    forKey: @"name"];
      
      if ([self isFlattened])
        {
          NSString *definition = [self definition];
          NSAssert(definition,@"No definition");
          [propertyList setObject: definition
                        forKey: @"definition"];
        }
      else
        {
          [propertyList setObject: ([self isToMany] ? @"Y" : @"N")
                        forKey: @"isToMany"];
          if ([self destinationEntity])
            {
              NSAssert2([[self destinationEntity] name],
                        @"No entity name in relationship named %@ entity named %@",
                        [self name],
                        [[self entity]name]);
              [propertyList setObject: [[self destinationEntity] name] // if we put entity, it loops !!
                            forKey: @"destination"];  
            };
        }
      
      if ([self isMandatory])
      {
        [propertyList setObject: @"Y"
                         forKey: @"isMandatory"];
      }
      
      if ([self ownsDestination])
      {
        [propertyList setObject: @"Y"
                         forKey: @"ownsDestination"];
      }
      
      if ([self propagatesPrimaryKey])
      {
        [propertyList setObject: @"Y"
                         forKey: @"propagatesPrimaryKey"];
      }
      
      {
        int joinsCount = [_joins count];
        
        if (joinsCount > 0)
          {
            NSMutableArray *joinsArray = [NSMutableArray array];
            int i = 0;
            
            for(i = 0; i < joinsCount; i++)
              {
                NSMutableDictionary *joinDict = [NSMutableDictionary dictionary];
                EOJoin *join = [_joins objectAtIndex: i];
                
                NSAssert([[join sourceAttribute] name],
                         @"No source attribute name");

                [joinDict setObject: [[join sourceAttribute] name]
                          forKey: @"sourceAttribute"];

                NSAssert([[join destinationAttribute] name],
                         @"No destination attribute name");
                [joinDict setObject: [[join destinationAttribute] name]
                          forKey: @"destinationAttribute"];

                [joinsArray addObject: joinDict];
              }
            
            [propertyList setObject: joinsArray
                          forKey: @"joins"]; 
          }
        
        NSAssert([self joinSemanticString],
                 @"No joinSemanticString");
        [propertyList setObject: [self joinSemanticString]
                      forKey: @"joinSemantic"];
      }
    }
  NS_HANDLER
    {
      NSLog(@"exception in EORelationship encodeIntoPropertyList: self=%p class=%@",
	    self, [self class]);
      NSDebugMLog(@"exception in EORelationship encodeIntoPropertyList: self=%p class=%@",
	    self, [self class]);
      NSLog(@"exception=%@", localException);
      NSDebugMLog(@"exception=%@", localException);
      [localException raise];
    }
  NS_ENDHANDLER;
}

- (NSString *)description
{
  NSString *dscr = nil;

  NS_DURING //Just for debugging
    {
      dscr = [NSString stringWithFormat: @"<%s %p - name=%@ entity=%@ destinationEntity=%@ definition=%@",
		       object_getClassName(self),
		       (void*)self,
		       [self name],
		       [[self entity]name],
		       [[self destinationEntity] name],
		       [self definition]];

      dscr = [dscr stringByAppendingFormat: @" userInfo=%@",
                   [self userInfo]];
      dscr = [dscr stringByAppendingFormat: @" joinSemantic=%@",
              [[self class] _nameForJoinSemantic:_joinSemantic]];      
      dscr = [dscr stringByAppendingFormat: @" joins=%@",
                   [self joins]];
      dscr = [dscr stringByAppendingFormat: @" sourceAttributes=%@",
                   [self sourceAttributes]];
      dscr = [dscr stringByAppendingFormat: @" destinationAttributes=%@",
                   [self destinationAttributes]];

      /*TODO  dscr = [dscr stringByAppendingFormat:@" componentRelationships=%@",
        [self componentRelationships]];*/

      dscr = [dscr stringByAppendingFormat: @" isCompound=%s isFlattened=%s isToMany=%s isBidirectional=%s>",
		   ([self isCompound] ? "YES" : "NO"),
                   ([self isFlattened] ? "YES" : "NO"),
                   ([self isToMany] ? "YES" : "NO"),
                   ([self isBidirectional] ? "YES" : "NO")];
    }
  NS_HANDLER
    {
      NSLog(@"exception in EORelationship description: self=%p class=%@",
	    self, [self class]);
      NSDebugMLog(@"exception in EORelationship description: self=%p class=%@",
                  self, [self class]);
      NSLog(@"exception=%@", localException);
      NSDebugMLog(@"exception=%@", localException);

      [localException raise];
    }
  NS_ENDHANDLER;

  return dscr;
}

- (NSString *)name
{
  return _name;
}

/** Returns the relationship's source entity. **/
- (EOEntity *)entity
{
  return _entity;
}

/** Returns the relationship's destination entity (direct destination entity or 
destination entity of the last relationship in definition. **/
- (EOEntity *)destinationEntity
{
  //OK
  // May be we could cache destination ? Hard to do because klast relationship may have its destination entity change.
  EOEntity *destinationEntity = _destination;

  if (!destinationEntity)
    {
      if ([self isFlattened])
        {
          EORelationship *lastRelationship = [_definitionArray lastObject];

          destinationEntity = [lastRelationship destinationEntity];

          NSAssert3(destinationEntity, @"No destinationEntity in last relationship: %@ of relationship %@ in entity %@",
                    lastRelationship, self, [_entity name]);
        }
      else
        {
	  [self _joinsChanged];
	  destinationEntity = _destination;
	}
    }
  else if ([destinationEntity isKindOfClass: [NSString class]] == YES)
    destinationEntity = [[_entity model] 
			  entityNamed: (NSString*)destinationEntity];

  return destinationEntity;
}

- (BOOL) isParentRelationship
{
  BOOL isParentRelationship=NO;
  EOEntity *destinationEntity = [self destinationEntity];
  if(destinationEntity != nil
     && destinationEntity == [_entity parentEntity])
    {
      NSArray* attributes = [self sourceAttributes];
      NSArray* pkAttributes = [_entity primaryKeyAttributes];
      if([attributes containsIdenticalObjectsWithArray:pkAttributes])
	{
	  attributes = [self destinationAttributes];
	  pkAttributes = [_destination primaryKeyAttributes];
	  isParentRelationship=[attributes containsIdenticalObjectsWithArray:pkAttributes];
	}
    }

  return isParentRelationship;
}

/** Returns YES when the relationship traverses at least two entities 
(exemple: aRelationship.anotherRelationship), NO otherwise. 
**/
- (BOOL)isFlattened
{
  return (_definitionArray==nil ? NO : YES);
}

/** return YES if the relation if a to-many one, NO otherwise (please read books 
to know what to-many mean :-)  **/
- (BOOL)isToMany
{
  return _flags.isToMany;
}

/** Returns YES if the relationship have more than 1 join (i.e. join on more that one (sourceAttribute/destinationAttribute), NO otherwise (1 or less join) **/

- (BOOL)isCompound
{
  //OK
  return [_joins count] > 1;
}

- (NSArray *)joins
{
  return _joins;
}

- (NSArray *)sourceAttributes
{
  if (!_sourceAttributes)
    {
      int i, count = [_joins count];

      _sourceAttributes = [NSMutableArray new];

      for (i = 0; i < count; i++)
        {
          EOJoin *join = [_joins objectAtIndex: i];
          [(NSMutableArray*)_sourceAttributes addObject:
			      [join sourceAttribute]];
        }
    }

  return _sourceAttributes;
}

- (NSArray *)destinationAttributes
{
  if (!_destinationAttributes)
    {
      int i, count = [_joins count];

      _destinationAttributes = [NSMutableArray new];

      for (i = 0; i < count; i++)
        {
          EOJoin *join = [_joins objectAtIndex: i];

          [(NSMutableArray *)_destinationAttributes addObject:
			      [join destinationAttribute]];
        }
    }

  return _destinationAttributes;
}

- (EOJoinSemantic)joinSemantic
{
  return _joinSemantic;
}

/*
 this seems to be GNUstep only -- dw
 */

- (NSString*)joinSemanticString
{  
  return [[self class] _nameForJoinSemantic:[self joinSemantic]];
}

/**
 * Returns the array of relationships composing this flattend relationship.
 * Returns nil of the reciever isn't flattend.
 */
- (NSArray *)componentRelationships
{
  return _definitionArray;
}

- (NSDictionary *)userInfo
{
  return _userInfo;
}

- (NSString *)docComment
{
  return _docComment;
}

- (NSString *)definition
{
  //OK
  NSString *definition = nil;

  NS_DURING //Just for debugging
    {
      definition = [_definitionArray valueForSQLExpression: nil];
    }
  NS_HANDLER
    {
      NSLog(@"exception in EORelationship definition: self=%p class=%@",
	    self, [self class]);
      NSLog(@"exception in EORelationship definition: self=%@ _definitionArray=%@",
	    self, _definitionArray);
      NSLog(@"exception=%@", localException);

      [localException raise];
    }
  NS_ENDHANDLER;

  return definition;
}

/** Returns the value to use in an EOSQLExpression. **/
- (NSString*) valueForSQLExpression: (EOSQLExpression*)sqlExpression
{
  return [self name];
}

- (BOOL)referencesProperty: (id)property
{
  if (property == nil)
    return NO;  
  
  if ([self isFlattened])
  {
    return [_definitionArray referencesObject:property];
  }
  
  if (_joins) {
    NSEnumerator  *joinEnumer = [_joins objectEnumerator];
    EOJoin        *join;
    
    while ((join = [joinEnumer nextObject])) {
      if (([join sourceAttribute] == property) || ([join destinationAttribute] == property))
      {
        return YES;
      }
      
    }    
  }
  
  return NO;
}

- (EODeleteRule)deleteRule
{



  return _flags.deleteRule;
}

- (BOOL)isMandatory
{
  return _flags.isMandatory;
}

- (BOOL)propagatesPrimaryKey
{
  return _flags.propagatesPrimaryKey;
}

- (BOOL)isBidirectional
{
  return _flags.isBidirectional;
}

- (BOOL)isReciprocalToRelationship: (EORelationship *)relationship
{
  BOOL isReciprocal = NO;
  EOEntity *entity = [self entity];
  EOEntity *relationshipDestinationEntity = [relationship destinationEntity];

  EOFLOGObjectLevelArgs(@"EORelationship", @"entity %p name=%@",
			entity, [entity name]);
  EOFLOGObjectLevelArgs(@"EORelationship",
			@"relationshipDestinationEntity %p name=%@",
			relationshipDestinationEntity,
			[relationshipDestinationEntity name]);

  if (entity == relationshipDestinationEntity)
    {
      if ([self isFlattened])
        {
          if ([relationship isFlattened])
            {
              //Now compare each components in reversed order 
              NSArray *selfComponentRelationships =
		[self componentRelationships];
              NSArray *relationshipComponentRelationships =
		[relationship componentRelationships];
              int selfComponentRelationshipsCount =
		[selfComponentRelationships count];
              int relationshipComponentRelationshipsCount =
		[relationshipComponentRelationships count];

              //May be we can imagine that they may not have the same number of components //TODO
              if (selfComponentRelationshipsCount
		  == relationshipComponentRelationshipsCount) 
                {
                  int i, j;
                  BOOL foundEachInverseComponent = YES;

                  for(i = (selfComponentRelationshipsCount - 1), j = 0;
		      foundEachInverseComponent && i >= 0;
		      i--, j++)
                    {
                      EORelationship *selfRel =
			[selfComponentRelationships objectAtIndex: i];
                      EORelationship *relationshipRel =
			[relationshipComponentRelationships objectAtIndex: j];

                      foundEachInverseComponent =
			[selfRel isReciprocalToRelationship: relationshipRel];
                    }

                  if (foundEachInverseComponent)
                    isReciprocal = YES;
                }
            }
        }
      else
        {
          //WO doesn't test inverses entity; we does.
          EOEntity *relationshipEntity = [relationship entity];
          EOEntity *destinationEntity = [self destinationEntity];

          EOFLOGObjectLevelArgs(@"EORelationship",
				@"relationshipEntity %p name=%@",
				relationshipEntity, [relationshipEntity name]);
          EOFLOGObjectLevelArgs(@"EORelationship",
				@"destinationEntity %p name=%@",
				destinationEntity, [destinationEntity name]);

          if (relationshipEntity == destinationEntity)
            {
              NSArray *joins = [self joins];
              NSArray *relationshipJoins = [relationship joins];
              int joinsCount = [joins count];
              int relationshipJoinsCount = [relationshipJoins count];

              EOFLOGObjectLevelArgs(@"EORelationship",
				    @"joinsCount=%d,relationshipJoinsCount=%d",
				    joinsCount, relationshipJoinsCount);

              if (joinsCount == relationshipJoinsCount)
                {
                  BOOL foundEachInverseJoin = YES;
                  int iJoin;

                  for (iJoin = 0;
		       foundEachInverseJoin && iJoin < joinsCount;
		       iJoin++)
                    {                  
                      EOJoin *join = [joins objectAtIndex: iJoin];
                      int iRelationshipJoin;
                      BOOL foundInverseJoin = NO;

                      EOFLOGObjectLevelArgs(@"EORelationship", @"%d join=%@",
					    iJoin, join);

                      for (iRelationshipJoin = 0;
			   !foundInverseJoin && iRelationshipJoin < joinsCount;
			   iRelationshipJoin++)
                        {
                          EOJoin *relationshipJoin =
			    [relationshipJoins objectAtIndex:iRelationshipJoin];

                          EOFLOGObjectLevelArgs(@"EORelationship",
						@"%d relationshipJoin=%@",
						iRelationshipJoin,
						relationshipJoin);

                          foundInverseJoin = [relationshipJoin
					       isReciprocalToJoin: join];

                          EOFLOGObjectLevelArgs(@"EORelationship",
						@"%d foundInverseJoin=%s",
						iRelationshipJoin,
						(foundInverseJoin ? "YES" : "NO"));
                        }

                      if (!foundInverseJoin)
                        foundEachInverseJoin = NO;

                      EOFLOGObjectLevelArgs(@"EORelationship",
					    @"%d foundEachInverseJoin=%s",
					    iJoin,
					    (foundEachInverseJoin ? "YES" : "NO"));
                    }

                  EOFLOGObjectLevelArgs(@"EORelationship",
					@"foundEachInverseJoin=%s",
					(foundEachInverseJoin ? "YES" : "NO"));

                  if (foundEachInverseJoin)
                    isReciprocal = YES;
                }
            }
        }
    }

  return isReciprocal;
}

/** "Search only already created inverse relationship in destination entity 
relationships. Nil if none" **/
- (EORelationship *)inverseRelationship
{
  if (!_inverseRelationship)
    {
      EOEntity* destinationEntity = [self destinationEntity];
      NSArray* destinationEntityRelationships = 
	[destinationEntity relationships];

      if ([destinationEntityRelationships count] > 0)
        {
          int i, count = [destinationEntityRelationships count];

          for (i = 0; !_inverseRelationship && i < count; i++)
            {
              EORelationship *testRelationship =
		[destinationEntityRelationships objectAtIndex: i];

              if ([self isReciprocalToRelationship: testRelationship])
                {
                  ASSIGN(_inverseRelationship, testRelationship);
                }
            }
        }
    }

  return _inverseRelationship;
}

- (EORelationship *) _makeFlattenedInverseRelationship
{
  //OK
  EORelationship *inverseRelationship = nil;
  NSMutableString *invDefinition = nil;
  NSString *name = nil;
  int i, count;

  NSAssert([self isFlattened], @"Not Flatten Relationship");
  EOFLOGObjectLevel(@"EORelationship", @"add joins");

  count = [_definitionArray count];

  for (i = count - 1; i >= 0; i--)
    {
      EORelationship *rel = [_definitionArray objectAtIndex: i];
      EORelationship *invRel = [rel anyInverseRelationship];
      NSString *invRelName = [invRel name];

      if (invDefinition)
        {
          if (i < (count - 1))
            [invDefinition appendString: @"."];

	  [invDefinition appendString: invRelName];
        }
      else
        invDefinition = [NSMutableString stringWithString: invRelName];
    }

  inverseRelationship = [[EORelationship new] autorelease];
  [inverseRelationship setEntity: [self destinationEntity]];

  name = [NSString stringWithFormat: @"_eofInv_%@_%@",
		   [_entity name],
		   _name];
  [inverseRelationship setName: name]; 
  [inverseRelationship setDefinition: invDefinition]; 

  EOFLOGObjectLevel(@"EORelationship", @"add inverse rel");

  [(NSMutableArray*)[[self destinationEntity] _hiddenRelationships]
		    addObject: inverseRelationship]; //not very clean !!!
  EOFLOGObjectLevel(@"EORelationship", @"set inverse rel");

  [inverseRelationship _setInverseRelationship: self];

  return inverseRelationship;
}

- (EORelationship*) _makeInverseRelationship
{
  EORelationship *inverseRelationship;
  NSString *name;
  NSArray *joins = nil;
  unsigned int i, count;

  NSAssert(![self isFlattened], @"Flatten Relationship");

  inverseRelationship = [[EORelationship new] autorelease];

  name = [NSString stringWithFormat: @"_eofInv_%@_%@",
		   [_entity name],
		   _name];
  [inverseRelationship setName: name]; 

  joins = [self joins];
  count = [joins count];

  EOFLOGObjectLevel(@"EORelationship", @"add joins");

  for (i = 0; i < count; i++)
    {
      EOJoin *join = [joins objectAtIndex: i];
      EOAttribute *sourceAttribute = [join sourceAttribute];
      EOAttribute *destinationAttribute = [join destinationAttribute];
      EOJoin *inverseJoin = [EOJoin joinWithSourceAttribute:
				      destinationAttribute //inverse souce<->destination attributes
				    destinationAttribute: sourceAttribute];

      [inverseRelationship addJoin: inverseJoin];
    }

  EOFLOGObjectLevel(@"EORelationship",@"add inverse rel");

  [(NSMutableArray*)[[self destinationEntity] _hiddenRelationships]
		    addObject: inverseRelationship]; //not very clean !!!

  EOFLOGObjectLevel(@"EORelationship", @"set inverse rel");

  [inverseRelationship _setInverseRelationship: self];

  /* call this last to avoid calls to [_destination _setIsEdited] */
  [inverseRelationship setEntity: _destination];

  return inverseRelationship;
}

- (EORelationship*) hiddenInverseRelationship
{
  if (!_hiddenInverseRelationship)
    {
      if ([self isFlattened]) 
        _hiddenInverseRelationship = [self _makeFlattenedInverseRelationship];
      else
        _hiddenInverseRelationship = [self _makeInverseRelationship];
    }

  return _hiddenInverseRelationship;
}

- (EORelationship *)anyInverseRelationship
{
  EORelationship *inverseRelationship = [self inverseRelationship];

  if (!inverseRelationship)
      inverseRelationship = [self hiddenInverseRelationship];

  return inverseRelationship;
}

- (unsigned int)numberOfToManyFaultsToBatchFetch
{
  return _batchCount;
}

- (BOOL)ownsDestination
{
  return _flags.ownsDestination;
}

- (EOQualifier *)qualifierWithSourceRow: (NSDictionary *)sourceRow
{
  EOQualifier* q = nil;
  EOQualifier* q1 = [self qualifierOmittingAuxiliaryQualifierWithSourceRow:sourceRow];
  EOQualifier* q2 = [self auxiliaryQualifier];
  if (q1 != nil)
    {
      if (q2!=nil)
	q=[EOAndQualifier qualifierWithQualifiers:q1,q2,nil];
      else
	q=q1;
    }
  else
    q=q2;
  return q;
}

@end /* EORelationship */


@implementation EORelationship (EORelationshipEditing)

- (NSException *)validateName: (NSString *)name
{
  const char *p, *s = [name cString];
  int exc = 0;
  NSArray *storedProcedures = nil;

  if ([_name isEqual:name])
    return nil;

  if (!name || ![name length])
    exc++;
  if (!exc)
    {
      p = s;
      while (*p)
        {
          if(!isalnum(*p) &&
             *p != '@' && *p != '#' && *p != '_' && *p != '$')
            {
              exc++;
              break;
            }
          p++;
        }
      if (!exc && *s == '$')
        exc++;
  
    if (exc)
      return [NSException exceptionWithName: NSInvalidArgumentException
                         reason: [NSString stringWithFormat: @"%@ -- %@ 0x%p: argument \"%@\" contains invalid char '%c'", 
					  NSStringFromSelector(_cmd),
					  NSStringFromClass([self class]),
					  self,
                                         name,
					 *p]
                        userInfo: nil];
      
      if ([[self entity] _hasAttributeNamed: name])
        exc++;
      else if ([[self entity] anyRelationshipNamed: name])
        exc++;
      else if ((storedProcedures = [[[self entity] model] storedProcedures]))
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
                if (exc)
                  break;
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

- (void)setToMany: (BOOL)flag
{
  if ([self isFlattened])
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%p: receiver is a flattened relationship",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  if (_flags.isToMany != flag)
    {
      [self willChange];
      [_entity _setIsEdited];
      _flags.isToMany = flag;
    }
}

- (void)setName: (NSString *)name
{
  [[self validateName: name] raise];
  [self willChange];
  [_entity _setIsEdited];

  ASSIGNCOPY(_name, name);
}

- (void)setDefinition: (NSString *)definition
{
  EOFLOGObjectLevelArgs(@"EORelationship", @"definition=%@", definition);

  [self _flushCache];
  [self willChange];

  if (definition)
    {
      _flags.isToMany = NO;

      NSAssert1(_entity,@"No entity for relationship %@",
                self);

      ASSIGN(_definitionArray, [_entity _parseRelationshipPath: definition]);

      EOFLOGObjectLevelArgs(@"EORelationship", @"_definitionArray=%@", _definitionArray);
      EOFLOGObjectLevelArgs(@"EORelationship", @"[self definition]=%@", [self definition]);

      _destination = nil;

      {        
        //TODO VERIFY
        //TODO better ?
        int i, count = [_definitionArray count];

        EOFLOGObjectLevelArgs(@"EORelationship", @"==> _definitionArray=%@",
			      _definitionArray);

        for (i = 0; !_flags.isToMany && i < count; i++)
          {
            EORelationship *rel = [_definitionArray objectAtIndex: i];

            if ([rel isKindOfClass: GDL2_EORelationshipClass])
              {
                if ([rel isToMany])
                  _flags.isToMany = YES;
            }
          else
            break;
        }
      }

    }
  else /* definition == nil */
    {
      DESTROY(_definitionArray);
    }
  /* Ayers: Not sure what justifies this. */
  [_entity _setIsEdited];


}

/**
 * <p>Sets the entity of the reciever.</p>
 * <p>If the receiver already has an entity assigned to it the old relationship
 * will will be removed first.</p>
 * <p>This method is used by [EOEntity-addRelationship:] and
 * [EOEntity-removeRelationship:] which should be used for general relationship
 * manipulations.  This method should only be useful
 * when creating flattend relationships programmatically.</p>
 */
- (void)setEntity: (EOEntity *)entity
{
  if (entity != _entity)
    {
      [self _flushCache];
      [self willChange];

      if (_entity)
	{
	  /* Check if we are still in the entities arrays to
	     avoid recursive loop when removeRelationship:
	     calls this method.  */
	  NSString *relationshipName = [self name];
          if (self == [_entity relationshipNamed: relationshipName])
	    [_entity removeRelationship: self];
	}
      _entity = entity;
    }
  /* This method is used by EOEntity's remove/addRelatinship: and is not
     responsible for calling _setIsEdited on the entity.  */
}

- (void)setUserInfo: (NSDictionary *)dictionary
{
  [self willChange];
  ASSIGN(_userInfo, dictionary);
  /* Ayers: Not sure what justifies this. */
  [_entity _setIsEdited];
}

- (void)setInternalInfo: (NSDictionary *)dictionary
{
  [self willChange];
  ASSIGN(_internalInfo, dictionary);
  /* Ayers: Not sure what justifies this. */
  [_entity _setIsEdited];
}

- (void)setDocComment: (NSString *)docComment
{
  [self willChange];
  ASSIGNCOPY(_docComment, docComment);
  /* Ayers: Not sure what justifies this. */
  [_entity _setIsEdited];
}

- (void)setPropagatesPrimaryKey: (BOOL)flag
{
  if (_flags.propagatesPrimaryKey != flag)
    [self willChange];

  _flags.propagatesPrimaryKey = flag;
}

- (void)setIsBidirectional: (BOOL)flag
{
  if (_flags.isBidirectional != flag)
    [self willChange];

  _flags.isBidirectional = flag;
}

- (void)setOwnsDestination: (BOOL)flag
{
  if (_flags.ownsDestination != flag)
    [self willChange];

  _flags.ownsDestination = flag;
}

- (void)addJoin: (EOJoin *)join
{    
  EOFLOGObjectLevelArgs(@"EORelationship", @"Add join: %@\nto %@", join, self);
  
  if ([self isFlattened] == YES)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"%@ -- %@ 0x%p: receiver is a flattened relationship",
		   NSStringFromSelector(_cmd),
		   NSStringFromClass([self class]),
		   self];
    }
  else
    {
      EOEntity *destinationEntity = [self destinationEntity];
      EOEntity *sourceEntity = [self entity];
      EOAttribute *sourceAttribute = [join sourceAttribute];
      EOAttribute *destinationAttribute = [join destinationAttribute];
      
      EOFLOGObjectLevelArgs(@"EORelationship", @"destinationEntity=%@", destinationEntity);
      
      NSAssert3(sourceAttribute, @"No source attribute in join %@ in relationship %@ of entity %@",
		join,
		self,
		sourceEntity);
      
      NSAssert3(destinationAttribute, @"No destination attribute in join %@ in relationship %@ of entity %@",                
		join,
		self,
		sourceEntity);
      
      if ([sourceAttribute isFlattened] == YES
	  || [destinationAttribute isFlattened] == YES)
	{
	  [NSException raise: NSInvalidArgumentException
		       format: @"%@ -- %@ 0x%p: join's attributes are flattened",
		       NSStringFromSelector(_cmd),
		       NSStringFromClass([self class]),
		       self];
	}
      else
	{
	  EOEntity *joinDestinationEntity = [destinationAttribute entity];
	  EOEntity *joinSourceEntity = [sourceAttribute entity];
	  
	  /*          if (destinationEntity && ![[destinationEntity name] isEqual:[joinSourceEntity name]])
		      {
		      [NSException raise:NSInvalidArgumentException
		      format:@"%@ -- %@ 0x%x: join source entity (%@) is not equal to last join entity (%@)",
		      NSStringFromSelector(_cmd),
		      NSStringFromClass([self class]),
		      self,
		      [joinSourceEntity name],
		      [destinationEntity name]];
		      }*/
	  
	  if (sourceEntity
	      && ![[joinSourceEntity name] isEqual: [sourceEntity name]])
	    {
	      [NSException raise: NSInvalidArgumentException
			   format: @"%@ -- %@ 0x%p (%@): join source entity (%@) is not equal to relationship entity (%@)",
			   NSStringFromSelector(_cmd),
			   NSStringFromClass([self class]),
			   self,
			   [self name],
			   [joinSourceEntity name],
			   [sourceEntity name]];
	    }
	  else if (destinationEntity
		   && ![[joinDestinationEntity name]
			 isEqual: [destinationEntity name]])
	    {
	      [NSException raise: NSInvalidArgumentException
			   format: @"%@ -- %@ 0x%p (%@): join destination entity (%@) is not equal to relationship destination entity (%@)",
			   NSStringFromSelector(_cmd),
			   NSStringFromClass([self class]),
			   self,
			   [self name],
			   [joinDestinationEntity name],
			   [destinationEntity name]];
	    }
	  else
	    {
	      if ([_sourceAttributes count])
		{
		  EOAttribute *sourceAttribute = [join sourceAttribute];
		  EOAttribute *destinationAttribute;
		  
		  destinationAttribute = [join destinationAttribute];
		  
		  if (([_sourceAttributes indexOfObject: sourceAttribute]
		       != NSNotFound)
		      && ([_destinationAttributes
			    indexOfObject: destinationAttribute]
			  != NSNotFound))
		    {
		      [NSException raise: NSInvalidArgumentException
				   format: @"%@ -- %@ 0x%p: TODO",
				   NSStringFromSelector(_cmd),
				   NSStringFromClass([self class]),
				   self];
		    }
		}
        
	      [self _flushCache];
	      // do we still need willChange when we are not putting EORelationships into ECs? -- dw
	      [self willChange];
	      // needed for KV bbserving
	      [self willChangeValueForKey:@"joins"];
	      
	      EOFLOGObjectLevel(@"EORelationship", @"really add");
	      EOFLOGObjectLevelArgs(@"EORelationship", @"XXjoins %p class%@",
				    _joins, [_joins class]);
	      
	      if (!_joins)
		_joins = [NSMutableArray new];
	      
	      [(NSMutableArray *)_joins addObject: join];      
	      
	      EOFLOGObjectLevelArgs(@"EORelationship", @"XXjoins %p class%@",
				    _joins, [_joins class]);
	      
	      EOFLOGObjectLevel(@"EORelationship", @"added");
	      
	      [self _joinsChanged];
	      [self didChangeValueForKey:@"joins"];
	      
	      /* Ayers: Not sure what justifies this. MGuesdon: EOF seems to do it */
	      [_entity _setIsEdited];
	    }
	}
    }
}

- (void)removeJoin: (EOJoin *)join
{
  if ([self isFlattened] == YES)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"%@ -- %@ 0x%p: receiver is a flattened relationship",
		   NSStringFromSelector(_cmd),
		   NSStringFromClass([self class]),
		   self];
    }
  else
    {
      [self _flushCache];
  
      [self willChangeValueForKey:@"joins"];

      [self willChange];
      [(NSMutableArray *)_joins removeObject: join];

      EOFLOGObjectLevelArgs(@"EORelationship", @"XXjoins %p class%@",
		       _joins, [_joins class]);

      [self _joinsChanged];

      /* Ayers: Not sure what justifies this. MGuesdon: EOF seems to do it */
      [_entity _setIsEdited];
      [self didChangeValueForKey:@"joins"];
    }
}

- (void)setJoinSemantic: (EOJoinSemantic)joinSemantic
{
  [self willChange];
  _joinSemantic = joinSemantic;
}

- (void)beautifyName
{
  /*+ Make the name conform to the Next naming style
    NAME -> name, FIRST_NAME -> firstName +*/
  NSArray  *listItems;
  NSString *newString = [NSString string];
  int	    anz, i;

  EOFLOGObjectFnStartOrCond2(@"ModelingClasses", @"EORelationship");
  
  /* Makes the receiver's name conform to a standard convention. Names that 
conform to this style are all lower-case except for the initial letter of 
each embedded word other than the first, which is upper case. Thus, "NAME" 
becomes "name", and "FIRST_NAME" becomes "firstName".*/
  
  if ((_name) && ([_name length] > 0))
    {
      listItems = [_name componentsSeparatedByString: @"_"];
      newString = [newString stringByAppendingString:
			       [[listItems objectAtIndex: 0] lowercaseString]];
      anz = [listItems count];

      for (i = 1; i < anz; i++)
	{
	  newString = [newString stringByAppendingString:
				   [[listItems objectAtIndex: i]
				     capitalizedString]];
	}

    // Exception abfangen
    NS_DURING
      {
        [self setName:newString];
      }
    NS_HANDLER
      {
        NSLog(@"%@ in Class: EORlationship , Method: beautifyName >> error : %@",
	      [localException name], [localException reason]);
      }
    NS_ENDHANDLER;
  }
  
  EOFLOGObjectFnStopOrCond2(@"ModelingClasses", @"EORelationship");
}

- (void)setNumberOfToManyFaultsToBatchFetch: (unsigned int)size
{
  [self willChange];
  _flags.useBatchFaulting=YES;
  _batchCount = size;
}

- (void)setDeleteRule: (EODeleteRule)deleteRule
{
  NSAssert1(deleteRule >= 0 && deleteRule <= 3,
	    @"Bad deleteRule numeric value: %d",
            deleteRule);

  [self willChange];
  _flags.deleteRule = deleteRule;
}

- (void)setIsMandatory: (BOOL)isMandatory
{
  if (_flags.isMandatory!=isMandatory)
    [self willChange];
  _flags.isMandatory = isMandatory;
}

@end

@implementation EORelationship (EORelationshipValueMapping)

/**
 * If the reciever is a manditory relationship, this method
 * returns an exception if the value pointed to by VALUEP is
 * either nil or the EONull instance for to-one relationships
 * or an empty NSArray for to-many relationships.  Otherwise
 * it returns nil.  EOClassDescription adds further information
 * to this exception before it gets passed to the application or
 * user.
 */
- (NSException *)validateValue: (id*)valueP
{
  NSException *exception = nil;

  NSAssert(valueP, @"No value pointer");

  if ([self isMandatory])
    {
      BOOL isToMany = [self isToMany];

      if (isToMany == NO)
	{
	  if (_isNilOrEONull(*valueP))
	    {
	      EOEntity *destinationEntity = [self destinationEntity];
	      EOEntity *entity = [self entity];
	      
	      exception = [NSException validationExceptionWithFormat:
					 @"The %@ property of %@ must have a %@ assigned",
				       [self name],
				       [entity name],
				       [destinationEntity name]];
	    }
	}
      else
	{
	  if ([*valueP count] == 0)
	    {
	      EOEntity *destinationEntity = [self destinationEntity];
	      EOEntity *entity = [self entity];
	      
	      exception = [NSException validationExceptionWithFormat:
					 @"The %@ property of %@ must have at least one %@",
				       [self name],
				       [entity name],
				       [destinationEntity name]];
	    }
	}
    }

  return exception;
}

@end

@implementation EORelationship (EORelationshipPrivate)

/*
  This method is private to GDL2 to allow the inverse relationship
  to be set from the original relationship.  It exists to avoid the
  ASSIGN(inverseRelationship->_inverseRelationship, self);
  and to insure that associations will be updated if we ever display
  inverse relationships in DBModeler.
*/
- (void)_setInverseRelationship: (EORelationship*)relationship
{
  [self willChange];
  ASSIGN(_inverseRelationship,relationship);
}

@end

@implementation EORelationship (EORelationshipXX)

- (NSArray*) _intermediateAttributes
{
  NSMutableArray *intermediateAttributes=[NSMutableArray array];
  NSArray* firstRelJoins=[[self firstRelationship] joins];
  NSArray* lastRelJoins=[[self lastRelationship] joins];

  [intermediateAttributes addObjectsFromArray:
			    [firstRelJoins resultsOfPerformingSelector:
				     @selector(destinationAttribute)]];

  [intermediateAttributes addObjectsFromArray:
			    [lastRelJoins resultsOfPerformingSelector:
				     @selector(sourceAttribute)]];

  return [NSArray arrayWithArray: intermediateAttributes];
}

/** Return the last relationship if self is flattened, self otherwise.
**/
- (EORelationship*) lastRelationship
{
  EORelationship *lastRel;

  if ([self isFlattened])
    {
      NSAssert(!_definitionArray || [_definitionArray count] > 0,
               @"Definition array is empty");

      lastRel = [[self _definitionArray] lastObject];
    }
  else
    lastRel = self;

  return lastRel;
}

/** Return the 1st relationship if self is flattened, self otherwise.
**/
- (EORelationship*) firstRelationship
{
  EORelationship *firstRel;

  if ([self isFlattened])
    {
      NSAssert(!_definitionArray || [_definitionArray count] > 0,
               @"Definition array is empty");

      firstRel = [[self _definitionArray] objectAtIndex: 0];
    }
  else
    firstRel = self;

  return firstRel;
}

- (EOEntity*) intermediateEntity
{
  id intermediateEntity = nil;

  if ([self isToManyToOne])
    {
      int i, count = [_definitionArray count];

      for (i = (count - 1); !intermediateEntity && i >= 0; i--)
        {
          EORelationship *rel = [_definitionArray objectAtIndex: i];

          if ([rel isToMany])
            intermediateEntity = [rel destinationEntity];
        }
    }

  return intermediateEntity;
}

- (BOOL) isMultiHop
{
  return [self isFlattened];
}

- (void) _setSourceToDestinationKeyMap: (NSDictionary*)sourceToDestinationKeyMap
{
  ASSIGN(_sourceToDestinationKeyMap,sourceToDestinationKeyMap);
}

- (EOQualifier*) qualifierForDBSnapshot: (NSDictionary*)dbSnapshot
{
  EOQualifier* qualifier = nil;

  EORelationship* relationship = self;
  NSMutableArray* qualifiers = nil;
  BOOL isFlattenedToMany = NO;
  NSString*  relationshipPath = nil;

  if([self isFlattened])
    {
      if ([self isToMany])
	{
	  relationshipPath = [[self anyInverseRelationship]relationshipPath];
	  isFlattenedToMany = true;
	  relationship = [self firstRelationship];
	}
      else
	relationship = [self lastRelationship];
    }

  NSDictionary* sourceToDestinationKeyMap = [self _sourceToDestinationKeyMap];
  NSArray* sourceKeys = [sourceToDestinationKeyMap objectForKey:@"sourceKeys"];
  NSArray* destinationKeys = [sourceToDestinationKeyMap objectForKey:@"destinationKeys"];
  NSArray* joins = [relationship joins];
  int joinsCount=[joins count];
  int i = 0;

  for(i=0;i<joinsCount;i++)
    {
      EOJoin* join = [joins objectAtIndex:i];
      NSString* attrName=nil;
      NSString* qualifierKey=nil;
      id qualifierValue=nil;
      if (isFlattenedToMany)
	{
	  attrName = [[join sourceAttribute] name];
	  qualifierKey = [[relationshipPath stringByAppendingString:@"."]stringByAppendingString:attrName];
	}
      else
	{
	  qualifierKey = [[join destinationAttribute] name];
	  attrName = [sourceKeys objectAtIndex:[destinationKeys indexOfObject:qualifierKey]];
	}
      qualifierValue = [dbSnapshot objectForKey:attrName];
      if(qualifierValue != nil)
	{
	  EOQualifier* q = [EOKeyValueQualifier qualifierWithKey:qualifierKey
						operatorSelector:EOQualifierOperatorEqual
						value:qualifierValue];
	  if (qualifiers == nil)
	    qualifiers = [NSMutableArray array];
	  [qualifiers addObject:q];
	}
    }

  if([qualifiers count]>0)
    {
      if ([qualifiers count] > 1)
	qualifier = [EOAndQualifier qualifierWithQualifierArray:qualifiers];
      else
	qualifier = [qualifiers objectAtIndex:0];
    }
  return qualifier;

}

- (NSDictionary*) primaryKeyForTargetRowFromSourceDBSnapshot:(NSDictionary*)dbSnapshot
{
  NSDictionary* sourceToDestinationKeyMap = [self _sourceToDestinationKeyMap];
  NSArray* sourceKeys = [sourceToDestinationKeyMap objectForKey:@"sourceKeys"];
  NSArray* destinationKeys = [sourceToDestinationKeyMap objectForKey:@"destinationKeys"];
  NSMutableDictionary* pk = [NSMutableDictionary dictionaryWithDictionary:dbSnapshot
						 keys:sourceKeys];
  [pk translateFromKeys:sourceKeys
      toKeys:destinationKeys];
  return pk;
}

/** Return relationship path (like toRel1.toRel2) if self is flattened, slef name otherwise.
**/
- (NSString*)relationshipPath
{
  NSString *relationshipPath = nil;

  if ([self isFlattened])
    {
      int i, count = [_definitionArray count];

      for (i = 0; i < count; i++)
        {
          EORelationship *relationship = [_definitionArray objectAtIndex: i];
          NSString *relationshipName = [relationship name];

          if (relationshipPath)
            [(NSMutableString*)relationshipPath appendString: @"."];
          else
            relationshipPath = [NSMutableString string];

          [(NSMutableString*)relationshipPath appendString: relationshipName];
        }
    }
  else
    relationshipPath = [self name];

  return relationshipPath;
}

-(BOOL)isToManyToOne
{
  BOOL isToManyToOne = NO;

  if ([self isFlattened])
    {
      int l=0;
      int count = [_definitionArray count];
      int i=0;
      for(i=0;i<count;i++)
	{
          EORelationship* relationship = [_definitionArray objectAtIndex: i];
	  switch(l)
            {
            case 0:
	      if([relationship isToMany])
		l = 1;
	      else  if([relationship isParentRelationship])
		return NO;
	      break;
            case 1:
	      if([relationship isToMany]
		 || [[relationship anyInverseRelationship]isParentRelationship])
		return NO;
	      else
                l = 2;
                break;
            case 2:
	      if([relationship isToMany]
		 || ![[relationship anyInverseRelationship] isParentRelationship])
		return NO;
	      break;
            default:
                break;
	    }
	}
      if (l==2)
	isToManyToOne=YES;
    }      

  return isToManyToOne;
}

-(NSDictionary*)_sourceToDestinationKeyMap
{
  if (!_sourceToDestinationKeyMap)
    {
      NSString *relationshipPath = [self relationshipPath];

      ASSIGN(_sourceToDestinationKeyMap,
	     [_entity _keyMapForRelationshipPath: relationshipPath]);
    }

  return _sourceToDestinationKeyMap;
}

- (BOOL)foreignKeyInDestination
{
  BOOL foreignKeyInDestination = NO;

  if([self isToMany])
    foreignKeyInDestination=YES;
  else
    {
      NSArray* sourceAttributes = [self sourceAttributes];
      NSArray* pkAttributes = [_entity primaryKeyAttributes];
      int sourceAttributesCount=[sourceAttributes count];
      int pkAttributesCount=[pkAttributes count];
      if (sourceAttributesCount==pkAttributesCount)
	{
	  foreignKeyInDestination=YES;
	  int i=0;
	  for(i=0;foreignKeyInDestination && i<sourceAttributesCount;i++)
	    {
	      EOAttribute* attribute = [sourceAttributes objectAtIndex:i];
	      if ([pkAttributes indexOfObjectIdenticalTo:attribute] == NSNotFound)
		foreignKeyInDestination=NO;
	    }
	}
    }

  return foreignKeyInDestination;
}

@end

@implementation EORelationship (EORelationshipPrivate2)

- (BOOL) isPropagatesPrimaryKeyPossible
{
  BOOL isPropagatesPrimaryKeyPossible=NO;

  NSArray* joins = [self joins];

  NSArray* sourceAttributes = [joins resultsOfPerformingSelector:@selector(sourceAttribute)];
  //MGuesdon: why ordering names ?
  NSSet* sourceAttributeNames = [NSSet setWithArray:[[sourceAttributes resultsOfPerformingSelector:@selector(name)] 
						      sortedArrayUsingSelector:@selector(compare:)]];
  NSSet* sourcePKAttributeNames = [NSSet setWithArray:[_entity primaryKeyAttributeNames]];

  if([sourceAttributeNames isSubsetOfSet:sourcePKAttributeNames])
    {
      NSArray* destinationAttributes = [joins resultsOfPerformingSelector:@selector(destinationAttribute)];
      //MGuesdon: why ordering names ?
      NSSet* destinationAttributeNames = [NSSet setWithArray:[[destinationAttributes resultsOfPerformingSelector:@selector(name)]
							       sortedArrayUsingSelector:@selector(compare:)]];
      NSSet* destinationPKAttributeNames = [NSSet setWithArray:[[self destinationEntity]primaryKeyAttributeNames]];

      if ([destinationAttributeNames isSubsetOfSet:destinationPKAttributeNames])
	{
	  isPropagatesPrimaryKeyPossible=[[self inverseRelationship] propagatesPrimaryKey];
	}
    }
  return isPropagatesPrimaryKeyPossible;
};

- (EOQualifier*) qualifierOmittingAuxiliaryQualifierWithSourceRow: (NSDictionary*)sourceRow
{
  return [self qualifierForDBSnapshot:sourceRow];
}

- (EOQualifier*) auxiliaryQualifier
{
  return _qualifier;
}

- (void) setAuxiliaryQualifier: (EOQualifier*)qualifier
{
  DESTROY(_qualifier);
  if (qualifier)
    _qualifier=[qualifier copy];
}

/** Return dictionary of key/value for destination object of source row/object **/
- (EOMutableKnownKeyDictionary *) _foreignKeyForSourceRow: (NSDictionary*)row
{
  return [EOMutableKnownKeyDictionary dictionaryFromDictionary: row
				      subsetMapping:[self _sourceRowToForeignKeyMapping]];
}

- (EOMKKDSubsetMapping*) _sourceRowToForeignKeyMapping
{
  if (!_sourceRowToForeignKeyMapping)
    {
      NSDictionary *sourceToDestinationKeyMap = 
	[self _sourceToDestinationKeyMap];

      NSArray *sourceKeys = 
	[sourceToDestinationKeyMap objectForKey: @"sourceKeys"];

      NSArray *destinationKeys = 
	[sourceToDestinationKeyMap objectForKey: @"destinationKeys"];

      EOEntity *destinationEntity = 
	[self destinationEntity];

      EOMKKDInitializer *destinationDictionaryInitializer = 
	[destinationEntity _adaptorDictionaryInitializer];

      EOMKKDInitializer *adaptorDictionaryInitializer = 
	[_entity _adaptorDictionaryInitializer];

      EOMKKDSubsetMapping *sourceRowToForeignKeyMapping = 
	[destinationDictionaryInitializer subsetMappingForSourceDictionaryInitializer: adaptorDictionaryInitializer
					  sourceKeys: sourceKeys
					  destinationKeys: destinationKeys];

      NSAssert3(sourceRowToForeignKeyMapping!=nil,
		@"Unable to map destination %@ for relationship %@ in entity %@. To one relationships must be joined on the primary key of the destination.",
		[destinationEntity name],
		[self name],
		[_entity name]);
      ASSIGN(_sourceRowToForeignKeyMapping, sourceRowToForeignKeyMapping);
    }

  return _sourceRowToForeignKeyMapping;
}

- (NSArray*) _sourceAttributeNames
{
  //MGuesdon: if flattened, EOF returns firstRelationship sourceAttribute names 
  //which is incoherent with -sourceAttributes
  //Here we return sourceAttribute names, flattened or not  

  return [[self sourceAttributes]
	   resultsOfPerformingSelector: @selector(name)];
}

- (EOJoin*) joinForAttribute: (EOAttribute*)attribute
{
  EOJoin *join = nil;
  int count = [_joins count];
  if (count>0)
    {
      int i=0;
      for (i = 0; !join && i < count; i++)
	{
	  EOJoin *aJoin = [_joins objectAtIndex: i];
	  if ([attribute isEqual: [aJoin sourceAttribute]]
	      || [attribute isEqual: [aJoin destinationAttribute]])
	    {
	      join = aJoin;
	    }
	}
    }

  return join;
}

- (void) _flushCache
{
  DESTROY(_sourceAttributes);
  DESTROY(_destinationAttributes);

  EORelationship* inverseRelationship=AUTORELEASE(RETAIN(_inverseRelationship));
  DESTROY(_inverseRelationship);
  if (inverseRelationship!=nil)
    [inverseRelationship _flushCache];

  if (_hiddenInverseRelationship!=nil)
    {
      [[[self destinationEntity]_hiddenRelationships] removeObjectIdenticalTo:_hiddenInverseRelationship];
      DESTROY(_hiddenInverseRelationship);
    }

  DESTROY(_sourceRowToForeignKeyMapping);
  _destination = nil;
}

- (EOExpressionArray*) _definitionArray
{
  return _definitionArray;
}

- (NSString*) _stringFromDeleteRule: (EODeleteRule)deleteRule
{
  NSString *deleteRuleString = nil;

  switch(deleteRule)
    {
    case EODeleteRuleNullify:
      deleteRuleString = @"EODeleteRuleNullify";
      break;
    case EODeleteRuleCascade:
      deleteRuleString = @"EODeleteRuleCascade";
      break;
    case EODeleteRuleDeny:
      deleteRuleString = @"EODeleteRuleDeny";
      break;
    case EODeleteRuleNoAction:
      deleteRuleString = @"EODeleteRuleNoAction";
      break;
    default:
      [NSException raise: NSInvalidArgumentException
                   format: @"%@ -- %@ 0x%p: invalid deleteRule code for relationship '%@': %d", 
                   NSStringFromSelector(_cmd), 
                   NSStringFromClass([self class]), 
                   self, 
                   [self name], 
                   (int)deleteRule];
      break;
    }

  return deleteRuleString;
}

- (EODeleteRule) _deleteRuleFromString: (NSString*)deleteRuleString
{
  EODeleteRule deleteRule = 0;

  if ([deleteRuleString isEqualToString: @"EODeleteRuleNullify"])
    deleteRule = EODeleteRuleNullify;
  else if ([deleteRuleString isEqualToString: @"EODeleteRuleCascade"])
    deleteRule = EODeleteRuleCascade;
  else if ([deleteRuleString isEqualToString: @"EODeleteRuleDeny"])
    deleteRule = EODeleteRuleDeny;
  else if ([deleteRuleString isEqualToString: @"EODeleteRuleNoAction"])
    deleteRule = EODeleteRuleNoAction;
  else 
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%p: invalid deleteRule string for relationship '%@': %@", 
                 NSStringFromSelector(_cmd), 
                 NSStringFromClass([self class]), 
                 self, 
                 [self name], 
                 deleteRuleString];

  return deleteRule;
}

- (NSDictionary*) _rightSideKeyMap
{
  NSDictionary *keyMap = nil;

  if ([self isToManyToOne])
    { 
      int definitionArrayCount=[_definitionArray count];
      EOEntity* entity = nil;
      NSMutableString* relationshipPath = nil;
      int k = 0;
      int i = 0;
      for(i=0; i < definitionArrayCount; i++)
        {
	  EORelationship* relationship = [_definitionArray objectAtIndex:i];
	  switch(k)
            {
            case 0:
	      if([relationship isToMany])
                {
		  k = 1;
		  entity=[relationship destinationEntity];
                }
                break;
            case 1:
	      if (relationshipPath)
		[relationshipPath appendString: @"."];
	      else
		relationshipPath = [NSMutableString string];
	      [relationshipPath appendString: [relationship name]];
	      break;
            default:
	      break;
            }
        }
      keyMap=[entity _keyMapForIdenticalKeyRelationshipPath:relationshipPath];
    }
  return keyMap;
}

- (NSDictionary *) _leftSideKeyMap
{
  NSDictionary *keyMap = nil;

  if ([self isToManyToOne])
    { 
      int definitionArrayCount=[_definitionArray count];
      NSMutableString* relationshipPath = nil;
      int i = 0;
      for(i=0; i < definitionArrayCount; i++)
        {
	  EORelationship* relationship = [_definitionArray objectAtIndex:i];
	  if (relationshipPath)
	    [relationshipPath appendString: @"."];
	  else
	    relationshipPath = [NSMutableString string];
	  [relationshipPath appendString: [relationship name]];
	  if ([relationship isToMany])
	     break;
        }

      keyMap=[[self entity]_keyMapForIdenticalKeyRelationshipPath:relationshipPath];
    }

  return keyMap;
}

- (EORelationship*)_substitutionRelationshipForRow: (NSDictionary*)row
{
  EOEntity* entity = [self entity];
  EOModelGroup* modelGroup = [[entity model]modelGroup];
  EORelationship* relationship = self;
  if(modelGroup != nil
     && modelGroup->_delegateRespondsTo.relationshipForRow)
    {
      relationship = [[modelGroup delegate] entity:entity
					    relationshipForRow:row
					    relationship:self];
    }
  return relationship;
}

- (void) _joinsChanged
{
  if ([_joins count] > 0)
    {
      EOJoin *join = [_joins objectAtIndex: 0];
      EOAttribute *destinationAttribute = [join destinationAttribute];
      EOEntity *destinationEntity = [destinationAttribute entity];

      _destination = destinationEntity;
    }
  else
    {
      _destination = nil;
    }
}

@end
