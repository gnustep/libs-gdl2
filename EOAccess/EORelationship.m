/** 
   EORelationship.m <title>EORelationship</title>

   Copyright (C) 2000-2002 Free Software Foundation, Inc.

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

static char rcsId[] = "$Id$";

#import <Foundation/NSArray.h>
#import <Foundation/NSUtilities.h>

#import <Foundation/NSException.h>

#import <EOAccess/EOModel.h>
#import <EOAccess/EOAttribute.h>
#import <EOAccess/EOAttributePriv.h>
#import <EOAccess/EOEntity.h>
#import <EOAccess/EOEntityPriv.h>
#import <EOAccess/EOStoredProcedure.h>
#import <EOAccess/EORelationship.h>
#import <EOAccess/EOJoin.h>
#import <EOAccess/EOExpressionArray.h>

#import <EOControl/EOObserver.h>
#import <EOControl/EOMutableKnownKeyDictionary.h>
#import <EOControl/EONSAddOns.h>
#import <EOControl/EODebug.h>


@implementation EORelationship

- init
{
//OK
  if ((self = [super init]))
    {
/*      _sourceNames = [NSMutableDictionary new];
      _destinationNames = [NSMutableDictionary new];
      _userInfo = [NSDictionary new];
      _sourceToDestinationKeyMap = [NSDictionary new];
      _joins = [GCMutableArray new];
*/
    }

  return self;
}

- (void)dealloc
{
  DESTROY(_name);
  DESTROY(_qualifier);
  DESTROY(_sourceNames);
  DESTROY(_destinationNames);
  DESTROY(_userInfo);
  DESTROY(_internalInfo);
  DESTROY(_docComment);
  DESTROY(_sourceToDestinationKeyMap);
  DESTROY(_sourceRowToForeignKeyMapping);

  [super dealloc];
}

- (void)gcDecrementRefCountOfContainedObjects
{
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EORelationship", @"self=%@", self);

  EOFLOGObjectLevel(@"EORelationship",
		    @"definitionArray gcDecrementRefCount");
  [(id)_definitionArray gcDecrementRefCount];

  EOFLOGObjectLevel(@"EORelationship",
		    @"_inverseRelationship gcDecrementRefCount");
  [_inverseRelationship gcDecrementRefCount];

  EOFLOGObjectLevel(@"EORelationship",
		    @"_hiddenInverseRelationship gcDecrementRefCount");
  [_hiddenInverseRelationship gcDecrementRefCount];

  EOFLOGObjectLevel(@"EORelationship", @"_entity gcDecrementRefCount");
  [_entity gcDecrementRefCount];

  EOFLOGObjectLevel(@"EORelationship",
		    @"_destination gcDecrementRefCount");
  [_destination gcDecrementRefCount];

  EOFLOGObjectLevelArgs(@"EORelationship",
			@"_joins %p gcDecrementRefCount (class=%@)",
			_joins, [_joins class]);
  [(id)_joins gcDecrementRefCount];

  EOFLOGObjectLevelArgs(@"EORelationship",
			@"_sourceAttributes gcDecrementRefCount (class=%@)",
			[_sourceAttributes class]);
  [(id)_sourceAttributes gcDecrementRefCount];

  EOFLOGObjectLevelArgs(@"EORelationship",
			@"_destinationAttributes gcDecrementRefCount (class=%@)",
			[_destinationAttributes class]);
  [(id)_destinationAttributes gcDecrementRefCount];

  EOFLOGObjectLevelArgs(@"EORelationship",
			@"_componentRelationships gcDecrementRefCount (class=%@)",
			[_componentRelationships class]);
  [(id)_componentRelationships gcDecrementRefCount];

  EOFLOGObjectFnStop();
}

- (BOOL)gcIncrementRefCountOfContainedObjects
{
  if (![super gcIncrementRefCountOfContainedObjects])
    return NO;

  [(id)_definitionArray gcIncrementRefCount];
  [_inverseRelationship gcIncrementRefCount];
  [_hiddenInverseRelationship gcIncrementRefCount];
  [_entity gcIncrementRefCount];
  [_destination gcIncrementRefCount];
  [(id)_joins gcIncrementRefCount];
  [(id)_sourceAttributes gcIncrementRefCount];
  [(id)_destinationAttributes gcIncrementRefCount];
  [(id)_componentRelationships gcIncrementRefCount];

  [(id)_definitionArray gcIncrementRefCountOfContainedObjects];
  [_inverseRelationship gcIncrementRefCountOfContainedObjects];
  [_hiddenInverseRelationship gcIncrementRefCountOfContainedObjects];
  [_entity gcIncrementRefCountOfContainedObjects];
  [_destination gcIncrementRefCountOfContainedObjects];
  [(id)_joins gcIncrementRefCountOfContainedObjects];
  [(id)_sourceAttributes gcIncrementRefCountOfContainedObjects];
  [(id)_destinationAttributes gcIncrementRefCountOfContainedObjects];
  [(id)_componentRelationships gcIncrementRefCountOfContainedObjects];

  return YES;
}

- (unsigned)hash
{
  return [_name hash];
}

+ (id) relationshipWithPropertyList: (NSDictionary *)propertyList
                              owner: (id)owner
{
  return [[[self alloc] initWithPropertyList: propertyList
                        owner: owner] autorelease];
}

- (id) initWithPropertyList: (NSDictionary *)propertyList
                      owner: (id)owner
{
  //Near OK
  if ((self = [self init]))
    {
      NSString *joinSemanticString = nil;
      EOModel *model;
      NSString* destinationEntityName = nil;
      EOEntity* destinationEntity = nil;
      NSString* deleteRuleString = nil;
      NSString* relationshipName;

      EOFLOGObjectFnStart();

      model = [owner model];
      relationshipName = [propertyList objectForKey: @"name"];

      [self setName: relationshipName]; 
      [self setEntity: owner];
      [self setCreateMutableObjects: YES];

      destinationEntityName = [propertyList objectForKey: @"destination"];

      if (destinationEntityName) //If not, this is because it's a definition
        {
          destinationEntity = [model entityNamed: destinationEntityName];
          ASSIGN(_destination, destinationEntity);
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
          if ([joinSemanticString isEqual: @"EOInnerJoin"])
            [self setJoinSemantic: EOInnerJoin];
          else if ([joinSemanticString isEqual: @"EOFullOuterJoin"])
            [self setJoinSemantic: EOFullOuterJoin];
          else if ([joinSemanticString isEqual: @"EOLeftOuterJoin"])
            [self setJoinSemantic: EOLeftOuterJoin];
          else if ([joinSemanticString isEqual: @"EORightOuterJoin"])
            [self setJoinSemantic: EORightOuterJoin];
          else
            {
              EOFLOGObjectLevelArgs(@"EORelationship", @"Unknown joinSemanticString=%@. entityName=%@ relationshipName=%@",
				    joinSemanticString,
				    [owner name],
				    relationshipName);
              NSEmitTODO(); //TODO
              [self notImplemented: _cmd]; //TODO
            }
        }
      else
        {
          if (destinationEntityName)
            {
              EOFLOGObjectLevelArgs(@"EORelationship", @"!joinSemanticString but destinationEntityName. entityName=%@ relationshipName=%@",
				    [owner name],
				    relationshipName);
              NSEmitTODO(); //TODO
              [self notImplemented: _cmd]; //TODO
            }
        }

      deleteRuleString = [propertyList objectForKey: @"deleteRule"];
      EOFLOGObjectLevelArgs(@"EORelationship", @"entityName=%@ relationshipName=%@ deleteRuleString=%@",
			    [owner name],
			    relationshipName,
			    deleteRuleString);

      if (deleteRuleString)
        {
          EODeleteRule deleteRule = [self _deleteRuleFromString:
					    deleteRuleString];
          EOFLOGObjectLevelArgs(@"EORelationship",
				@"entityName=%@ relationshipName=%@ deleteRule=%d",
				[owner name],
				relationshipName,
				(int)deleteRule);
          NSAssert2(deleteRule >= 0 && deleteRule < 4,
		    @"Bad deleteRule numeric value: %@ (%d)",
		    deleteRuleString,
		    deleteRule);

          [self setDeleteRule: deleteRule];
        }
    }

  EOFLOGObjectFnStop();

  return self;
}

- (void)awakeWithPropertyList: (NSDictionary *)propertyList  //TODO
{
  //OK for definition
  NSString *definition;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EORelationship", @"self=%@", self);

  definition = [propertyList objectForKey: @"definition"];

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
                  NSDictionary *joinPList;
                  NSString *joinSemantic;
                  NSString *sourceAttributeName;
                  EOAttribute *sourceAttribute;
                  EOEntity *destinationEntity;
                  NSString *destinationAttributeName = nil;
                  EOAttribute *destinationAttribute = nil;
                  EOJoin *join = nil;

                  joinPList = [joins objectAtIndex: i];
                  joinSemantic = [joinPList objectForKey: @"joinSemantic"];

                  sourceAttributeName = [joinPList objectForKey:
						     @"sourceAttribute"];
                  sourceAttribute = [_entity attributeNamed:
					       sourceAttributeName];

                  NSAssert4(sourceAttribute, @"No sourceAttribute named \"%@\" in entity \"%@\" in relationship %@\nEntity: %@",
                            sourceAttributeName,
                            [_entity name],
                            self,
                            _entity);

                  destinationEntity = [self destinationEntity];
                  destinationAttributeName = [joinPList
					       objectForKey:
						 @"destinationAttribute"];
                  destinationAttribute = [destinationEntity
					   attributeNamed:
					     destinationAttributeName];

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
                                   format: @"%@ -- %@ 0x%x: cannot create join for relationship '%@': %@", 
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

  [self setCreateMutableObjects: NO]; //?? tc say yes, mirko no

  EOFLOGObjectFnStop();
}

- (void)encodeIntoPropertyList: (NSMutableDictionary *)propertyList
{
  //VERIFY
  [propertyList setObject: [self name]
                forKey: @"name"];

  if ([self isFlattened])
    {
      NSString *definition = [self definition];

      [propertyList setObject: definition
                    forKey: @"definition"];
    }
  else
    {
      [propertyList setObject: ([self isToMany] ? @"Y" : @"N")
                    forKey: @"isToMany"];
      [propertyList setObject: [self destinationEntity]
                    forKey: @"destination"];  
    }

  if ([self isMandatory])
    [propertyList setObject: @"Y"
                  forKey: @"isMandatory"];

  if ([self ownsDestination])
    {
      NSEmitTODO(); //TODO
      [self notImplemented: _cmd]; //TODO
    }

  if ([self propagatesPrimaryKey])
    {
      NSEmitTODO(); //TODO
      [self notImplemented: _cmd]; //TODO
    }

  {
    int joinsCount = [_joins count];

    if (joinsCount > 0)
      {
        NSMutableArray *joinsArray = [NSMutableArray array];
        int i;

        for(i = 0; i < joinsCount; i++)
          {
            NSMutableDictionary *joinDict = [NSMutableDictionary dictionary];
            EOJoin *join = [_joins objectAtIndex: i];

            [joinDict setObject: [[join sourceAttribute] name]
                      forKey: @"sourceAttribute"];
            [joinDict setObject: [[join destinationAttribute] name]
		      forKey: @"destinationAttribute"];
            [joinsArray addObject: joinDict];
          }

	[propertyList setObject: joinsArray
		      forKey: @"joins"]; 
      }

    [propertyList setObject: [self joinSemanticString]
                  forKey: @"joinSemantic"];
  }
}

- (NSString *)description
{
  NSString *dscr = nil;

  NS_DURING //Just for debugging
    {
      dscr = [NSString stringWithFormat: @"<%s %p - name=%@ entity=%@ destinationEntity=%@ definition=%@",
		       object_get_class_name(self),
		       (void*)self,
		       [self name],
		       [[self entity]name],
		       [[self destinationEntity] name],
		       [self definition]];

      dscr = [dscr stringByAppendingFormat: @" userInfo=%@",
                   [self userInfo]];
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
      NSLog(@"exception in EORelationship definition: self name=%@ _definitionArray=%@",
	    [self name], _definitionArray);
      NSLog(@"exception=%@", localException);

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
    }
  else if ([destinationEntity isKindOfClass: [NSString class]] == YES)
    destinationEntity = [[_entity model] 
			  entityNamed: (NSString*)destinationEntity];

  return destinationEntity;
}

- (BOOL) isParentRelationship
{
  BOOL isParentRelationship = NO;
  /*EOEntity *destinationEntity = [self destinationEntity];
    EOEntity *parentEntity = [_entity parentEntity];*///nil

  NSEmitTODO();  //TODO
  // [self notImplemented:_cmd]; //TODO...

  return isParentRelationship;
}

/** Returns YES when the relationship traverses at least two entities 
(exemple: aRelationship.anotherRelationship), NO otherwise. 
**/
- (BOOL)isFlattened
{
  if (_definitionArray)
    return [_definitionArray isFlattened];
  else
    return NO;
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
  //OK
  if (!_sourceAttributes)
    {
      int i, count = [_joins count];

      _sourceAttributes = [GCMutableArray new];

      for (i = 0; i < count; i++)
        {
          EOJoin *join = [_joins objectAtIndex: i];
          [(GCMutableArray*)_sourceAttributes addObject:
			      [join sourceAttribute]];
        }
    }

  return _sourceAttributes;
}

- (NSArray *)destinationAttributes
{
  //OK
  if (!_destinationAttributes)
    {
      int i, count = [_joins count];

      _destinationAttributes = [GCMutableArray new];

      for (i = 0; i < count; i++)
        {
          EOJoin *join = [_joins objectAtIndex: i];

          [(GCMutableArray*)_destinationAttributes addObject:
			      [join destinationAttribute]];
        }
    }

  return _destinationAttributes;
}

- (EOJoinSemantic)joinSemantic
{
  return _joinSemantic;
}

- (NSString*)joinSemanticString
{
  NSString *joinSemanticString = nil;

  switch ([self joinSemantic])
    {
    case EOInnerJoin:
      joinSemanticString = @"EOInnerJoin";
      break;
    case EOFullOuterJoin:
      joinSemanticString = @"EOFullOuterJoin";
      break;
    case EOLeftOuterJoin:
      joinSemanticString = @"EOLeftOuterJoin";
      break;
    case EORightOuterJoin:
      joinSemanticString = @"EORightOuterJoin";
      break;
    default:
      NSAssert1(NO, @"Unknwon join semantic code %d",
		(int)[self joinSemantic]);
      break;
    }

  return joinSemanticString;
}

- (NSArray *)componentRelationships
{
  if (!_componentRelationships)
    {
      return _definitionArray; //OK ??????
      NSEmitTODO();  //TODO
      [self notImplemented: _cmd]; //TODO
    }

  return _componentRelationships;
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
  EOFLOGObjectLevelArgs(@"EORelationship", @"EORelationship %p", self);

  NSEmitTODO();  //TODO
//  return [self notImplemented:_cmd]; //TODO
//return name ??

  return [self name];
}

- (BOOL)referencesProperty: (id)property
{
  BOOL referencesProperty = NO;

  NSEmitTODO();  //TODO
  EOFLOGObjectLevelArgs(@"EORelationship", @"in referencesProperty:%@",
			property);

  referencesProperty = ([[self sourceAttributes]
			  indexOfObject: property] != NSNotFound
			|| [[self destinationAttributes]
			     indexOfObject: property] != NSNotFound
			|| [[self componentRelationships]
			     indexOfObject: property] != NSNotFound);

  return referencesProperty;
}

- (EODeleteRule)deleteRule
{
  EOFLOGObjectFnStart();
  EOFLOGObjectFnStop();

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
  //Should be OK
  BOOL isReciprocal = NO;
  EOEntity *entity;
  EOEntity *relationshipDestinationEntity = nil;

  EOFLOGObjectFnStart();

  entity = [self entity]; //OK
  relationshipDestinationEntity = [relationship destinationEntity];

  EOFLOGObjectLevelArgs(@"EORelationship", @"entity %p name=%@",
			entity, [entity name]);
  EOFLOGObjectLevelArgs(@"EORelationship",
			@"relationshipDestinationEntity %p name=%@",
			relationshipDestinationEntity,
			[relationshipDestinationEntity name]);

  if (entity == relationshipDestinationEntity) //Test like that ?
    {
      if ([self isFlattened]) //OK
        {
          if ([relationship isFlattened]) //OK
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
          else
            {
              NSEmitTODO(); //TODO
              [self notImplemented: _cmd]; //TODO
            }
        }
      else
        {
          //WO doens't test inverses entity 
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

  EOFLOGObjectFnStop();

  return isReciprocal;
}

/** "Search only already created inverse relationship in destination entity 
relationships. Nil if none" **/
- (EORelationship *)inverseRelationship
{
  //OK
  EOFLOGObjectFnStart();

  if (!_inverseRelationship)
    {
      EOEntity *destinationEntity;
      NSArray *destinationEntityRelationships;

      destinationEntity = [self destinationEntity];
      NSDebugLog(@"destinationEntity name=%@", [destinationEntity name]);

      destinationEntityRelationships = [destinationEntity relationships];

      NSDebugLog(@"destinationEntityRelationships=%@",
		 destinationEntityRelationships);

      if ([destinationEntityRelationships count] > 0)
        {
          int i, count = [destinationEntityRelationships count];

          for (i = 0; !_inverseRelationship && i < count; i++)
            {
              EORelationship *testRelationship =
		[destinationEntityRelationships objectAtIndex: i];

              NSDebugLog(@"testRelationship=%@", testRelationship);

              if ([self isReciprocalToRelationship: testRelationship])
                {
                  ASSIGN(_inverseRelationship, testRelationship);
                }
            }
        }

      NSDebugLog(@"_inverseRelationship=%@", _inverseRelationship);
    }

  EOFLOGObjectFnStop();

  return _inverseRelationship;
}

- (EORelationship *) _makeFlattenedInverseRelationship
{
  //OK
  EORelationship *inverseRelationship = nil;
  NSMutableString *invDefinition = nil;
  NSString *name = nil;
  int i, count;

  EOFLOGObjectFnStart();

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

  [inverseRelationship setInverseRelationship: self];

  EOFLOGObjectFnStop();

  return inverseRelationship;
}

- (EORelationship*) _makeInverseRelationship
{
  //OK
  EORelationship *inverseRelationship;
  NSString *name;
  NSArray *joins = nil;
  int i, count;

  EOFLOGObjectFnStart();

  NSAssert(![self isFlattened], @"Flatten Relationship");

  inverseRelationship = [[EORelationship new] autorelease];
  [inverseRelationship setEntity: _destination];

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

  [inverseRelationship setInverseRelationship: self];

  EOFLOGObjectFnStop();

  return inverseRelationship;
}

- (EORelationship*) hiddenInverseRelationship
{
  //OK
  EOFLOGObjectFnStart();

  if (!_hiddenInverseRelationship)
    {
      if ([self isFlattened]) 
        _hiddenInverseRelationship = [self _makeFlattenedInverseRelationship];
      else
        _hiddenInverseRelationship = [self _makeInverseRelationship];
    }

  EOFLOGObjectFnStop();

  return _hiddenInverseRelationship;
}

- (EORelationship *)anyInverseRelationship
{
  //OK
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
  [self notImplemented: _cmd];//TODO
  return nil;
}

@end /* EORelationship */


@implementation EORelationship (EORelationshipEditing)

- (NSException *)validateName: (NSString *)name
{
  //Seems OK
  const char *p, *s = [name cString];
  int exc = 0;
  NSArray *storedProcedures = nil;

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
      
      if ([[self entity] anyAttributeNamed: name])
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
    return [NSException exceptionWithName: NSInvalidArgumentException
                        reason: [NSString stringWithFormat: @"%@ -- %@ 0x%x: argument \"%@\" contains invalid chars", 
					  NSStringFromSelector(_cmd),
					  NSStringFromClass([self class]),
					  self,
                                         name]
                        userInfo: nil];
  else
    return nil;
}

- (void)setToMany: (BOOL)flag
{
  //OK
  if ([self isFlattened])
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: receiver is a flattened relationship",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];

  _flags.isToMany = flag;
}

- (void)setName: (NSString *)name
{
  //OK
  [[self validateName: name] raise];
  [self willChange];
  [_entity _setIsEdited];

  ASSIGN(_name, name);
}

- (void)setDefinition: (NSString *)definition
{
  //Near OK
  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EORelationship", @"definition=%@", definition);

  if (definition)
    {
      [self _flushCache];
      [self willChange];

      _flags.isToMany = NO;

      ASSIGN(_definitionArray, [_entity _parseRelationshipPath: definition]);

      EOFLOGObjectLevelArgs(@"EORelationship", @"_definitionArray=%@", _definitionArray);
      EOFLOGObjectLevelArgs(@"EORelationship", @"[self definition]=%@", [self definition]);

      DESTROY(_destination); //No ? Assign destination ?

      {        
        //TODO VERIFY
        //TODO better ?
        int i, count = [_definitionArray count];

        EOFLOGObjectLevelArgs(@"EORelationship", @"==> _definitionArray=%@",
			      _definitionArray);

        for (i = 0; !_flags.isToMany && i < count; i++)
          {
            EORelationship *rel = [_definitionArray objectAtIndex: i];

            if ([rel isKindOfClass: [EORelationship class]])
              {
                if ([rel isToMany])
                  _flags.isToMany = YES;
            }
          else
            break;
        }
      }

      [_entity _setIsEdited];
    }

  EOFLOGObjectFnStop();
}

- (void)setEntity: (EOEntity *)entity
{
  //OK
  if (entity != _entity)
    {
      [self _flushCache];
      [self willChange];
      ASSIGN(_entity, entity);
    }
}

- (void)setUserInfo: (NSDictionary *)dictionary
{
  //OK
  [self willChange];
  ASSIGN(_userInfo, dictionary);
  [_entity _setIsEdited];
}

- (void)setInternalInfo: (NSDictionary *)dictionary
{
  //OK
  [self willChange];
  ASSIGN(_internalInfo, dictionary);
  [_entity _setIsEdited];
}

- (void)setDocComment: (NSString *)docComment
{
  //OK
  [self willChange];
  ASSIGN(_docComment, docComment);
  [_entity _setIsEdited];
}

- (void)setPropagatesPrimaryKey: (BOOL)flag
{
  //OK
  if (_flags.propagatesPrimaryKey != flag)
    [self willChange];

  _flags.propagatesPrimaryKey = flag;
}

- (void)setIsBidirectional: (BOOL)flag
{
  //OK
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
  EOAttribute *sourceAttribute = nil;
  EOAttribute *destinationAttribute = nil;

  EOFLOGObjectFnStart();

  EOFLOGObjectLevelArgs(@"EORelationship", @"Add join: %@\nto %@", join, self);

  if ([self isFlattened] == YES)
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: receiver is a flattened relationship",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];
  else
    {
      EOEntity *destinationEntity = [self destinationEntity];
      EOEntity *sourceEntity = [self entity];

      EOFLOGObjectLevelArgs(@"EORelationship", @"destinationEntity=%@", destinationEntity);

      if (!destinationEntity)
        {
          NSEmitTODO(); //TODO
          EOFLOGObjectLevelArgs(@"EORelationship", @"self=%@", self);
          //TODO ??
        };

      sourceAttribute = [join sourceAttribute];

      NSAssert3(sourceAttribute, @"No source attribute in join %@ in relationship %@ of entity %@",
                join,
                self,
                sourceEntity);

      destinationAttribute = [join destinationAttribute];

      NSAssert3(destinationAttribute, @"No destination attribute in join %@ in relationship %@ of entity %@",                
                join,
                self,
                sourceEntity);

      if ([sourceAttribute isFlattened] == YES
	  || [destinationAttribute isFlattened] == YES)
        [NSException raise: NSInvalidArgumentException
                     format: @"%@ -- %@ 0x%x: join's attributes are flattened",
                     NSStringFromSelector(_cmd),
                     NSStringFromClass([self class]),
                     self];
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
              [NSException raise: NSInvalidArgumentException
                           format: @"%@ -- %@ 0x%x (%@): join source entity (%@) is not equal to relationship entity (%@)",
                           NSStringFromSelector(_cmd),
                           NSStringFromClass([self class]),
                           self,
                           [self name],
                           [joinSourceEntity name],
                           [sourceEntity name]];
          else if (destinationEntity
		   && ![[joinDestinationEntity name]
			 isEqual: [destinationEntity name]])
              [NSException raise: NSInvalidArgumentException
                           format: @"%@ -- %@ 0x%x (%@): join destination entity (%@) is not equal to relationship destination entity (%@)",
                           NSStringFromSelector(_cmd),
                           NSStringFromClass([self class]),
                           self,
                           [self name],
                           [joinDestinationEntity name],
                           [destinationEntity name]];
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
                    [NSException raise: NSInvalidArgumentException
                                 format: @"%@ -- %@ 0x%x: TODO",
                                 NSStringFromSelector(_cmd),
                                 NSStringFromClass([self class]),
                                 self];
                }

                [self _flushCache];
                [self willChange];

                EOFLOGObjectLevel(@"EORelationship", @"really add");
                EOFLOGObjectLevelArgs(@"EORelationship", @"XXjoins %p class%@",
				      _joins, [_joins class]);

                if ([self createsMutableObjects])
                  {
                    if (!_joins)
                      _joins = [GCMutableArray new];

                    [(GCMutableArray *)_joins addObject: join];      

                    EOFLOGObjectLevelArgs(@"EORelationship", @"XXjoins %p class%@",
					  _joins, [_joins class]);

                    //NO: will be recomputed      [(GCMutableArray *)_sourceAttributes addObject:[join sourceAttribute]];
                    //NO: will be recomputed      [(GCMutableArray *)_destinationAttributes addObject:[join destinationAttribute]];
                  }
                else
                  {
                    if (_joins)
                      _joins = [[[_joins autorelease]
				  arrayByAddingObject: join] retain];
                    else
                      _joins = [[GCArray arrayWithObject: join] retain];

                    EOFLOGObjectLevelArgs(@"EORelationship", @"XXjoins %p class%@",
					  _joins, [_joins class]);

                    /*NO: will be recomputed      _sourceAttributes = [[[_sourceAttributes autorelease]
                      arrayByAddingObject:[join sourceAttribute]]
                      retain];
                      _destinationAttributes = [[[_destinationAttributes autorelease]
                      arrayByAddingObject:
                      [join destinationAttribute]]
                      retain];
                    */
                  }

                EOFLOGObjectLevel(@"EORelationship", @"added");

                [self _joinsChanged];
                [_entity _setIsEdited];
            }
        }
    }

  EOFLOGObjectFnStop();
}

- (void)removeJoin: (EOJoin *)join
{
  EOFLOGObjectFnStart();

  [self _flushCache];
  [self willChange];

  if ([self isFlattened] == YES)
    [NSException raise: NSInvalidArgumentException
                 format: @"%@ -- %@ 0x%x: receiver is a flattened relationship",
                 NSStringFromSelector(_cmd),
                 NSStringFromClass([self class]),
                 self];
  else
    {
      if ([self createsMutableObjects])
        {
          [(GCMutableArray *)_joins removeObject: join];

          /*NO: will be recomputed      [(GCMutableArray *)_sourceAttributes
            removeObject:[join sourceAttribute]];
            [(GCMutableArray *)_destinationAttributes
            removeObject:[join destinationAttribute]];
          */

          EOFLOGObjectLevelArgs(@"EORelationship", @"XXjoins %p class%@",
		       _joins, [_joins class]);
        }
      else
        {
	  GCMutableArray	*ma = [_joins mutableCopy];
	  GCArray		*a = (GCArray *)_joins;

	  [ma removeObject: join];
	  _joins = ma;
          [a release];

          EOFLOGObjectLevelArgs(@"EORelationship", @"XXjoins %p class%@",
				_joins, [_joins class]);

          /*NO: will be recomputed
            _sourceAttributes = [[_sourceAttributes autorelease] mutableCopy];
            [(GCMutableArray *)_sourceAttributes
            removeObject:[join sourceAttribute]];
            _sourceAttributes = [[_sourceAttributes autorelease] copy];
      
            _destinationAttributes = [[_destinationAttributes autorelease]
            mutableCopy];
            [(GCMutableArray *)_destinationAttributes
            removeObject:[join destinationAttribute]];
            _destinationAttributes = [[_destinationAttributes autorelease] copy];
          */
        }

      [self _joinsChanged];
      [_entity _setIsEdited];
    }

  EOFLOGObjectFnStop();
}

- (void)setJoinSemantic: (EOJoinSemantic)joinSemantic
{
  //OK
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
  _batchCount = size;
}

- (void)setDeleteRule: (EODeleteRule)deleteRule
{
  NSAssert1(deleteRule >= 0 && deleteRule < 4,
	    @"Bad deleteRule numeric value: %d",
            deleteRule);

  _flags.deleteRule = deleteRule;
}

- (void)setIsMandatory: (BOOL)isMandatory
{
  //OK
  [self willChange];
  _flags.isMandatory = isMandatory;
}

@end

@implementation EORelationship(EORelationshipValueMapping)

- (NSException *)validateValue: (id*)valueP
{
  //OK
  NSException *exception = nil;

  EOFLOGObjectFnStart();

  NSAssert(valueP, @"No value pointer");

  if ([self isMandatory])
    {
      BOOL isToMany = [self isToMany];

      if ((isToMany == NO && *valueP == nil)
	  || (isToMany == YES && [*valueP count] == 0))
        {
          EOEntity *destinationEntity = [self destinationEntity];
          EOEntity *entity = [self entity];

          exception = [NSException validationExceptionWithFormat:
				     @"The %@ property of %@ must have a %@ assigned",
				   [self name],
				   [entity name],
				   [destinationEntity name]];
          /* //TODO userinfo:
            userInfo {
            EOValidatedObjectUserInfoKey = {
            ...
            }; 
            }; 
            EOValidatedPropertyUserInfoKey = quotationPlace; 
            }EOValidatedObjectUserInfoKey={
            ...
            }; 
            }
            EOValidatedPropertyUserInfoKey=quotationPlace            
          */
        }
    }

  if (!exception)
    {
      NSEmitTODO(); //TODO
      [self notImplemented:_cmd]; //TODO
    }

  EOFLOGObjectFnStop();

  return exception;
}

@end

@implementation EORelationship (EORelationshipPrivate)

- (void)setCreateMutableObjects: (BOOL)flag
{
  if (_flags.createsMutableObjects != flag)
    {
      _flags.createsMutableObjects = flag;

      if (_flags.createsMutableObjects)
        {
          _joins = [[_joins autorelease] mutableCopy];

          EOFLOGObjectLevelArgs(@"EORelationship", @"XXjoins %p class%@",
		       _joins, [_joins class]);

          DESTROY(_sourceAttributes);
          DESTROY(_destinationAttributes);
          /*Will be recomputed later      _sourceAttributes = [[_sourceAttributes autorelease] mutableCopy];
            _destinationAttributes = [[_destinationAttributes autorelease]
            mutableCopy];
          */
        }
      else
        {
          _joins = [[_joins autorelease] copy];

          EOFLOGObjectLevelArgs(@"EORelationship", @"XXjoins %p class%@",
		       _joins, [_joins class]);

          DESTROY(_sourceAttributes);
          DESTROY(_destinationAttributes);

          /*Will be recomputed later      _sourceAttributes = [[_sourceAttributes autorelease] copy];
            _destinationAttributes = [[_destinationAttributes autorelease] copy];
          */
        }
    }
}

- (BOOL)createsMutableObjects
{
  return _flags.createsMutableObjects;
}

- (void)setInverseRelationship: (EORelationship*)relationship
{
  ASSIGN(_inverseRelationship,relationship);
}

@end

@implementation EORelationship (EORelationshipXX)

- (NSArray*) _intermediateAttributes
{
  //Verify !!
  NSMutableArray *intermediateAttributes;
  EORelationship *rel;
  NSArray *joins;

  //all this works on flattened and non flattened relationship.
  intermediateAttributes = [NSMutableArray array];
  rel = [self firstRelationship];
  joins = [rel joins];
  //??
  [intermediateAttributes addObjectsFromArray:
			    [joins resultsOfPerformingSelector:
				     @selector(destinationAttribute)]];

  rel = [self lastRelationship];
  joins = [rel joins];
  //  attribute = [joins sourceAttribute];
  //??
  [intermediateAttributes addObjectsFromArray:
			    [joins resultsOfPerformingSelector:
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
  //TODO verify
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
  //TODO verify
  BOOL isMultiHop = NO;

  if ([self isFlattened])
    {
      isMultiHop = YES;
    }

  return isMultiHop;
}

- (void) _setSourceToDestinationKeyMap: (id)param0
{
  [self notImplemented: _cmd]; // TODO
}

- (id) qualifierForDBSnapshot: (id)param0
{
  return [self notImplemented: _cmd]; // TODO
}

- (id) primaryKeyForTargetRowFromSourceDBSnapshot: (id)param0
{
  return [self notImplemented:_cmd]; // TODO
}

/** Return relationship path (like toRel1.toRel2) if self is flattened, slef name otherwise.
**/
- (NSString*)relationshipPath
{
  //Seems OK
  NSString *relationshipPath = nil;

  EOFLOGObjectFnStart();

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

  EOFLOGObjectFnStop();

  return relationshipPath;
}

-(BOOL)isToManyToOne
{
  BOOL isToManyToOne = NO;

  EOFLOGObjectFnStart();

  if ([self isFlattened])
    {
      BOOL isToMany = YES;
      int count = [_definitionArray count];

      if (count >= 2)
        {
          EORelationship *firstRelationship = [_definitionArray
						objectAtIndex: 0];

          isToMany = [firstRelationship isToMany];

          if (!isToMany)
            {
              if ([firstRelationship isParentRelationship])
                {
                  NSEmitTODO();  //TODO
                  EOFLOGObjectLevelArgs(@"EORelationship", @"self=%@", self);
                  EOFLOGObjectLevelArgs(@"EORelationship", @"firstRelationship=%@",
			       firstRelationship);

                  [self notImplemented: _cmd]; //TODO
                }
            }

          if (isToMany)
            {
              EORelationship *secondRelationship = [_definitionArray
						     objectAtIndex: 0];

              if (![secondRelationship isToMany])
                {
                  EORelationship *invRel = [secondRelationship
					     anyInverseRelationship];

                  if (invRel)
                    secondRelationship = invRel;

                  isToManyToOne = YES;

                  if ([secondRelationship isParentRelationship])
                    {
                      NSEmitTODO();  //TODO
                      EOFLOGObjectLevelArgs(@"EORelationship", @"self=%@", self);
                      EOFLOGObjectLevelArgs(@"EORelationship", @"secondRelationship=%@",
				   secondRelationship);

                      [self notImplemented: _cmd]; //TODO
                    }
                }
            }
        }
    }

  EOFLOGObjectFnStop();

  return isToManyToOne;
}

-(NSDictionary*)_sourceToDestinationKeyMap
{
  //OK
  EOFLOGObjectFnStart();

  if (!_sourceToDestinationKeyMap)
    {
      NSString *relationshipPath = [self relationshipPath];

      ASSIGN(_sourceToDestinationKeyMap,
	     [_entity _keyMapForRelationshipPath: relationshipPath]);
    }

  EOFLOGObjectFnStop();

  return _sourceToDestinationKeyMap;
}

- (BOOL)foreignKeyInDestination
{
  NSArray *destAttributes;
  NSArray *primaryKeyAttributes;
  int destAttributesCount;
  int primaryKeyAttributesCount;
  BOOL foreignKeyInDestination = NO;

  EOFLOGObjectFnStart();

  destAttributes = [self destinationAttributes];
  primaryKeyAttributes = [[self destinationEntity] primaryKeyAttributes];

  destAttributesCount = [destAttributes count];
  primaryKeyAttributesCount = [primaryKeyAttributes count];

  EOFLOGObjectLevelArgs(@"EORelationship", @"destAttributes=%@",
			destAttributes);
  EOFLOGObjectLevelArgs(@"EORelationship", @"primaryKeyAttributes=%@",
			primaryKeyAttributes);

  if (destAttributesCount > 0 && primaryKeyAttributesCount > 0)
    {
      int i;

      for (i = 0;
	   !foreignKeyInDestination && i < destAttributesCount;
	   i++)
	{
	  EOAttribute *attribute = [destAttributes objectAtIndex: i];
	  int pkAttrIndex = [primaryKeyAttributes
			      indexOfObjectIdenticalTo: attribute];

	  foreignKeyInDestination = (pkAttrIndex == NSNotFound);
	}
    }

  EOFLOGObjectFnStop();

  EOFLOGObjectLevelArgs(@"EORelationship", @"foreignKeyInDestination=%s",
			(foreignKeyInDestination ? "YES" : "NO"));

  return foreignKeyInDestination;
}

@end

@implementation EORelationship (EORelationshipPrivate2)

- (BOOL) isPropagatesPrimaryKeyPossible
{
/*
  NSArray* joins=[self joins];
  NSArray* joinsSourceAttributes=[joins resultsOfPerformingSelector:@selector(sourceAttribute)];
  NSArray* joinsDestinationAttributes=[joins resultsOfPerformingSelector:@selector(destinationAttribute)];

joinsSourceAttributes names
sortedArrayUsingSelector:compare:

result count

joinsDestinationAttributes names
sortedArrayUsingSelector:compare:
inverseRelationship
inv entity [EOEntity]:
inv ventity primaryKeyAttributeNames
count
dest entity
dst entity primaryKeyAttributeNames 

*/
  EOFLOGObjectFnStart();

  [self notImplemented: _cmd]; // TODO

  EOFLOGObjectFnStop();

  return NO;
};

- (id) qualifierOmittingAuxiliaryQualifierWithSourceRow: (id)param0
{
  return [self notImplemented: _cmd]; // TODO
}

- (id) auxiliaryQualifier
{
  return nil; //[self notImplemented:_cmd]; // TODO
}

- (void) setAuxiliaryQualifier: (id)param0
{
  [self notImplemented:_cmd]; // TODO
}

- (NSDictionary*) _foreignKeyForSourceRow: (NSDictionary*)row
{
  NSDictionary *foreignKey = nil;
  EOMKKDSubsetMapping *sourceRowToForeignKeyMapping;

  EOFLOGObjectFnStart();

  sourceRowToForeignKeyMapping = [self _sourceRowToForeignKeyMapping];

  EOFLOGObjectLevelArgs(@"EORelationship", @"self=%@",self);
  EOFLOGObjectLevelArgs(@"EORelationship", @"sourceRowToForeignKeyMapping=%@",
	       sourceRowToForeignKeyMapping);

  foreignKey = [EOMutableKnownKeyDictionary dictionaryFromDictionary: row
					    subsetMapping:
					      sourceRowToForeignKeyMapping];

  EOFLOGObjectLevelArgs(@"EORelationship", @"row=%@\nforeignKey=%@", row, foreignKey);

  EOFLOGObjectFnStop();

  return foreignKey;
}

- (EOMKKDSubsetMapping*) _sourceRowToForeignKeyMapping
{
  EOFLOGObjectFnStart();

  if (!_sourceRowToForeignKeyMapping)
    {
      NSDictionary *sourceToDestinationKeyMap;
      NSArray *sourceKeys;
      NSArray *destinationKeys;
      EOEntity *destinationEntity;
      EOMKKDInitializer *primaryKeyDictionaryInitializer;
      EOMKKDInitializer *adaptorDictionaryInitializer;
      EOMKKDSubsetMapping *sourceRowToForeignKeyMapping;

      sourceToDestinationKeyMap = [self _sourceToDestinationKeyMap];

      EOFLOGObjectLevelArgs(@"EORelationship", @"sourceToDestinationKeyMap=%@",
		   sourceToDestinationKeyMap);

      sourceKeys = [sourceToDestinationKeyMap objectForKey: @"sourceKeys"];
      EOFLOGObjectLevelArgs(@"EORelationship", @"sourceKeys=%@", sourceKeys);

      destinationKeys = [sourceToDestinationKeyMap
			  objectForKey: @"destinationKeys"];
      EOFLOGObjectLevelArgs(@"EORelationship", @"destinationKeys=%@", destinationKeys);


      destinationEntity = [self destinationEntity];
      primaryKeyDictionaryInitializer = [destinationEntity
					  _primaryKeyDictionaryInitializer];

      EOFLOGObjectLevelArgs(@"EORelationship", @"destinationEntity named %@  primaryKeyDictionaryInitializer=%@",
		   [destinationEntity name],
		   primaryKeyDictionaryInitializer);

      adaptorDictionaryInitializer = [_entity _adaptorDictionaryInitializer];
      EOFLOGObjectLevelArgs(@"EORelationship",@"entity named %@ adaptorDictionaryInitializer=%@",
                  [_entity name],
                  adaptorDictionaryInitializer);

      sourceRowToForeignKeyMapping = 
	[primaryKeyDictionaryInitializer
	  subsetMappingForSourceDictionaryInitializer:
	    adaptorDictionaryInitializer
	  sourceKeys: sourceKeys
	  destinationKeys: destinationKeys];

      ASSIGN(_sourceRowToForeignKeyMapping, sourceRowToForeignKeyMapping);

      EOFLOGObjectLevelArgs(@"EORelationship",@"%@ to %@: _sourceRowToForeignKeyMapping=%@",
		   [_entity name],
		   [destinationEntity name],
		   _sourceRowToForeignKeyMapping);
    }

  EOFLOGObjectFnStop();

  return _sourceRowToForeignKeyMapping;
}

- (NSArray*) _sourceAttributeNames
{
  //Seems OK
  return [[self sourceAttributes]
	   resultsOfPerformingSelector: @selector(name)];
}

- (EOJoin*) joinForAttribute: (EOAttribute*)attribute
{
  //OK
  EOJoin *join = nil;
  int i, count = [_joins count];

  for (i = 0; !join && i < count; i++)
    {
      EOJoin *aJoin = [_joins objectAtIndex: i];
      EOAttribute *sourceAttribute = [aJoin sourceAttribute];

      if ([attribute isEqual: sourceAttribute])
        join = aJoin;
    }

  return join;
}

- (void) _flushCache
{
  //VERIFY
  //[self notImplemented:_cmd]; // TODO
  DESTROY(_sourceAttributes);
  DESTROY(_destinationAttributes);
  DESTROY(_inverseRelationship);
  DESTROY(_hiddenInverseRelationship);
}

- (EOExpressionArray*) _definitionArray
{
  //VERIFY
  return _definitionArray;
}

- (NSString*) _stringFromDeleteRule: (EODeleteRule)deleteRule
{
  NSString *deleteRuleString = nil;

  switch(deleteRule)
    {
    case EODeleteRuleNullify:
      deleteRuleString = @"";
      break;
    case EODeleteRuleCascade:
      deleteRuleString = @"";
      break;
    case EODeleteRuleDeny:
      deleteRuleString = @"";
      break;
    case EODeleteRuleNoAction:
      deleteRuleString = @"";
      break;
    default:
      [NSException raise: NSInvalidArgumentException
                   format: @"%@ -- %@ 0x%x: invalid deleteRule code for relationship '%@': %d", 
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
                 format: @"%@ -- %@ 0x%x: invalid deleteRule string for relationship '%@': %@", 
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

  NSEmitTODO();  //TODO

  [self notImplemented: _cmd]; // TODO

  if ([self isToManyToOne])
    {
      int count = [_definitionArray count];

      if (count >= 2) //??
        {
          EORelationship *rel0 = [_definitionArray objectAtIndex: 0];

          if ([rel0 isToMany]) //??
            {
              EOEntity *entity = [rel0 destinationEntity];
              EORelationship *rel1 = [_definitionArray objectAtIndex: 1];

              keyMap = [entity _keyMapForIdenticalKeyRelationshipPath:
				 [rel1 name]];
            }
        }
    }

  return keyMap;
}

- (id) _leftSideKeyMap
{
  NSDictionary *keyMap = nil;

  NSEmitTODO();  //TODO

  [self notImplemented: _cmd]; // TODO

  if ([self isToManyToOne])
    {
      int count = [_definitionArray count];

      if (count >= 2) //??
        {
          EORelationship *rel = [_definitionArray objectAtIndex: 0];

          if ([rel isToMany]) //??
            {
              EOEntity *entity = [rel entity];

              keyMap = [entity _keyMapForIdenticalKeyRelationshipPath:
				 [rel name]];
            }
        }
    }

  return keyMap;
}

- (EORelationship*)_substitutionRelationshipForRow: (NSDictionary*)row
{
  EOEntity *entity = [self entity];
  EOModel *model = [entity model];
  EOModelGroup *modelGroup = [model modelGroup];

  if (modelGroup)
    {
      //??
      //NSEmitTODO();  //TODO
    }

  return self;
}

- (void) _joinsChanged
{
  //TODO VERIFY
  int count;

  EOFLOGObjectFnStart();

  count = [_joins count];

  EOFLOGObjectLevelArgs(@"EORelationship", @"_joinsChanged:%@\nin %@", _joins, self);

  if (count > 0)
    {
      int i;

      for (i = 0; i < count; i++)
        {
          EOJoin *join = [_joins objectAtIndex: i];
          EOAttribute *destinationAttribute = [join destinationAttribute];
          EOEntity *destinationEntity = [destinationAttribute entity];

          ASSIGN(_destination, destinationEntity);
        }
    }
  else
    {
      DESTROY(_destination);
    }
//_joins count
  //[self notImplemented:_cmd]; // TODO-NOW
/*
join destinationAttribute
attr entity
*/

  EOFLOGObjectFnStop();
}

@end
