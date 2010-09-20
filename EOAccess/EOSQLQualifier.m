/** 
   EOSQLQualifier.m <title>EOSQLQualifier Class</title>

   Copyright (C) 2002,2003,2004,2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: February 2002

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

#include <stdio.h>
#include <string.h>

#ifdef GNUSTEP
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/NSDebug+GNUstepBase.h>
#include <GNUstepBase/NSObject+GNUstepBase.h>
#include <GNUstepBase/NSString+GNUstepBase.h>
#endif

#include <EOAccess/EOSQLQualifier.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOJoin.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOSQLExpression.h>
#include <EOAccess/EOExpressionArray.h>

#include <EOControl/EOQualifier.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EOObjectStoreCoordinator.h>
#include <EOControl/EONull.h>
#include <EOControl/EODebug.h>

#include "EOPrivate.h"
#include "EOEntityPriv.h"

@implementation EOSQLQualifier
+ (EOQualifier *)qualifierWithQualifierFormat: (NSString *)format, ...
{
  NSEmitTODO();  //TODO
  [self notImplemented: _cmd]; //TODO
  return nil;
}

- (id)initWithEntity: (EOEntity *)entity 
     qualifierFormat: (NSString *)qualifierFormat, ...
{
  va_list           args;
  NSMutableString   *sqlString;

  NSAssert(entity,@"no entity specified");

  ASSIGN(_entity, entity);

  va_start (args, qualifierFormat);
  sqlString = [NSString stringWithFormat: qualifierFormat arguments: args];
  va_end (args);

  _contents = [[EOExpressionArray alloc] initWithPrefix: sqlString
					 infix: nil
					 suffix: nil];

  return self;
}

- (EOQualifier *)schemaBasedQualifierWithRootEntity:(EOEntity *)entity
{
  return self;
}

- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)sqlExpression
{
  return [_contents expressionValueForContext:nil];
}

- (void)dealloc
{
  DESTROY(_entity);
  DESTROY(_contents);

  [super dealloc];
}
@end


/* Undocumente method which uses EORequestConcreteImplementation
   to determine an implementation to use for non EOF-Qualifiers.
 */
@implementation EOQualifier (EOQualifierSQLGeneration)
- (EOQualifier *)schemaBasedQualifierWithRootEntity:(EOEntity *)entity
{
  NSEmitTODO();  //TODO
  [self notImplemented: _cmd];
  return nil;
}
- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)sqlExpression
{
  NSEmitTODO();  //TODO
  [self notImplemented: _cmd];
  return nil;
}
@end

@implementation EOAndQualifier (EOQualifierSQLGeneration)

- (NSString *)sqlStringForSQLExpression: (EOSQLExpression *)sqlExpression
{
  //OK?
  //Ayers: Review (This looks correct, time to cleanup.)
  return [sqlExpression sqlStringForConjoinedQualifiers: _qualifiers];

/*
//TODO finish to add sqlExpression
  NSEnumerator *qualifiersEnum=nil;
  EOQualifier *qualifier=nil;
  NSMutableString *sqlString = nil;

  qualifiersEnum = [_qualifiers objectEnumerator];
  while ((qualifier = [qualifiersEnum nextObject]))
    {
      if (!sqlString)
        {
	  sqlString = [NSMutableString stringWithString:
					 [(id <EOQualifierSQLGeneration>)qualifier sqlStringForSQLExpression:sqlExpression]];
        }
      else
        {
	  [sqlString appendFormat:@" %@ %@",
		     @"AND",
		     [(id <EOQualifierSQLGeneration>)qualifier sqlStringForSQLExpression:sqlExpression]];
        }
    }
  return sqlString;
*/
}

- (EOQualifier *)schemaBasedQualifierWithRootEntity: (EOEntity *)entity
{
  EOQualifier *returnedQualifier = self;
  int qualifierCount = 0;
  BOOL atLeastOneDifferentQualifier = NO; // YES if we find a changed qualifier


  qualifierCount = [_qualifiers count];

  if (qualifierCount > 0)
    {
      NSMutableArray *qualifiers = [NSMutableArray array];
      int i;

      for (i = 0; i < qualifierCount; i++)
	{
	  EOQualifier *qualifier = [_qualifiers objectAtIndex: i];
	  EOQualifier *schemaBasedQualifierTmp =
	    [(id <EOQualifierSQLGeneration>)qualifier
					    schemaBasedQualifierWithRootEntity:
					      entity];

          if (schemaBasedQualifierTmp != qualifier)
            atLeastOneDifferentQualifier = YES;

          // Allows nil schemaBasedQualifier
          if (schemaBasedQualifierTmp)
            [qualifiers addObject: schemaBasedQualifierTmp];
	}

      // If we've found at least a different qualifier, return a new EOAndQualifier
      if (atLeastOneDifferentQualifier)
        {
          if ([qualifiers count]>0)
            {
              returnedQualifier = [[self class] 
                                    qualifierWithQualifierArray:qualifiers];
            }
          else
            returnedQualifier = nil;
        };
    }



  return returnedQualifier;
}

@end

@implementation EOOrQualifier (EOQualifierSQLGeneration)

- (NSString *)sqlStringForSQLExpression: (EOSQLExpression *)sqlExpression
{
  //OK?
  //Ayers: Review (This looks correct, time to cleanup.)
  return [sqlExpression sqlStringForDisjoinedQualifiers: _qualifiers];

/*
  NSEnumerator *qualifiersEnum;
  EOQualifier *qualifier;
  NSMutableString *sqlString = nil;

  qualifiersEnum = [_qualifiers objectEnumerator];
  while ((qualifier = [qualifiersEnum nextObject]))
    {
      if (!sqlString)
        {
	  sqlString = [NSMutableString stringWithString:
					 [(id <EOQualifierSQLGeneration>)qualifier sqlStringForSQLExpression: sqlExpression]];
        }
      else
        {
	  [sqlString appendFormat: @" %@ %@",
		     @"OR",
		     [(id <EOQualifierSQLGeneration>)qualifier sqlStringForSQLExpression: sqlExpression]];
        }
    }

  return sqlString;
*/
}

- (EOQualifier *)schemaBasedQualifierWithRootEntity: (EOEntity *)entity
{
  EOQualifier *returnedQualifier = self;
  int qualifierCount = 0;
  BOOL atLeastOneDifferentQualifier = NO; // YES if we find a changed qualifier


  qualifierCount = [_qualifiers count];

  if (qualifierCount > 0)
    {
      NSMutableArray *qualifiers = [NSMutableArray array];
      int i;

      for (i = 0; i < qualifierCount; i++)
	{
	  EOQualifier *qualifier = [_qualifiers objectAtIndex: i];
	  EOQualifier *schemaBasedQualifierTmp =
	    [(id <EOQualifierSQLGeneration>)qualifier
					    schemaBasedQualifierWithRootEntity:
					      entity];

          if (schemaBasedQualifierTmp != qualifier)
            atLeastOneDifferentQualifier = YES;

          // Allows nil schemaBasedQualifier
          if (schemaBasedQualifierTmp)
            [qualifiers addObject: schemaBasedQualifierTmp];
	}

      // If we've found at least a different qualifier, return a new EOOrQualifier
      if (atLeastOneDifferentQualifier)
        {
          if ([qualifiers count]>0)
            {
              returnedQualifier = [[self class] 
                                    qualifierWithQualifierArray:qualifiers];
            }
          else
            returnedQualifier = nil;
        };
    }



  return returnedQualifier;
}

@end

@implementation EOKeyComparisonQualifier (EOQualifierSQLGeneration)

- (NSString *)sqlStringForSQLExpression: (EOSQLExpression *)sqlExpression
{
  return [sqlExpression sqlStringForKeyComparisonQualifier: self];
}

- (EOQualifier *)schemaBasedQualifierWithRootEntity: (EOEntity *)entity
{
  return self; // MG: Not sure
}

@end

@implementation EOKeyValueQualifier (EOQualifierSQLGeneration)

+ (void)initialize
{
  static BOOL initialized=NO;
  if (!initialized)
    {
      initialized=YES;

      GDL2_EOAccessPrivateInit();
    };
};

- (NSString *)sqlStringForSQLExpression: (EOSQLExpression *)sqlExpression
{
  return [sqlExpression sqlStringForKeyValueQualifier: self];
}

- (EOQualifier *)schemaBasedQualifierWithRootEntity: (EOEntity *)entity
{
  EOQualifier *qualifier = nil;
  NSMutableArray *qualifiers = nil;
  id key;
  EORelationship *relationship;



  EOFLOGObjectLevelArgs(@"EOQualifier", @"self=%@", self);

  key = [self key];
  EOFLOGObjectLevelArgs(@"EOQualifier", @"key=%@", key);
  
  // 2 cases: key finish by an attrbue name  (attrName or rel1.rel2.rel3.attrName)
  // or by an relationship  (rel1 or rel1.rel2.rel3)

  // So find which one is it for key

  relationship = [entity relationshipForPath: key];
  EOFLOGObjectLevelArgs(@"EOQualifier", @"relationship=%@", relationship);

  // It's a relationship (case 2), so we'll have to work
  if (relationship)
    {
      EORelationship *destinationRelationship;
      NSDictionary *keyValues = nil;
      id value = nil;
      EOEditingContext* editingContext = nil;
      EOObjectStore *rootObjectStore = nil;
      NSMutableArray *destinationAttributeNames = [NSMutableArray array];
      NSArray *joins;
      int i, count;
      SEL sel = NULL;

      // keyPrefix for new qualifier attribute names
      NSString* keyPrefix=nil; 

      NSString* relName=[relationship name];

      // Verify if key is a single relationship or a relationship key path
      if (![key isEqualToString:relName])
        {
          // It is a relationship key path: we'll have to prefix join(s) 
          // attribute name
          // keyPrefix is the keyPath without last relationship name
          // ex: rel1.rel2. if key was rel1.rel2.rel3
          keyPrefix=[key stringByDeletingSuffix:relName];
        };

      // if relationship is flattened, we'll have to add 
      // last relationship path prefix to keyPrefix !
      if ([relationship isFlattened])
        {
          NSString* relDef=nil;
          destinationRelationship = [relationship lastRelationship];
          
          relDef=[relationship definition];

          // something like rel1.rel2.relA.relB. or relA.relB.
          if (keyPrefix)
            keyPrefix=[keyPrefix stringByAppendingString:relDef];
          else
            keyPrefix=relDef;

          keyPrefix=[keyPrefix stringByAppendingString:@"."];
        }
      else
        {
          destinationRelationship = relationship;
        };

      EOFLOGObjectLevelArgs(@"EOQualifier", @"key=%@ keyPrefix=%@", 
                            key, keyPrefix);

      joins = [destinationRelationship joins];
      count = [joins count];

      for (i = 0; i < count; i++)
        {
          EOJoin *join = [joins objectAtIndex: i];
          EOAttribute *destinationAttribute = [join destinationAttribute];
          NSString *destinationAttributeName = [destinationAttribute name];

          [destinationAttributeNames addObject: destinationAttributeName];
        }

      value = [self value];
      EOFLOGObjectLevelArgs(@"EOQualifier", @"value=%@", value);

      editingContext = [value editingContext];
      rootObjectStore = [editingContext rootObjectStore];

      EOFLOGObjectLevelArgs(@"EOQualifier", @"rootObjectStore=%@",
			    rootObjectStore);
      EOFLOGObjectLevelArgs(@"EOQualifier", @"destinationAttributeNames=%@",
			    destinationAttributeNames);
      
      keyValues = [(EOObjectStoreCoordinator*)rootObjectStore
                                              valuesForKeys:
                                                destinationAttributeNames
                                              object: value];
      EOFLOGObjectLevelArgs(@"EOQualifier", @"keyValues=%@", keyValues);

      sel = [self selector];

      for (i = 0; i < count; i++)
        {
          EOQualifier *tmpQualifier = nil;
          NSString *attributeName = nil;
          NSString *destinationAttributeName;
          EOJoin *join = [joins objectAtIndex: i];
          id attributeValue = nil;

          EOFLOGObjectLevelArgs(@"EOQualifier",@"join=%@",join);

          destinationAttributeName = [destinationAttributeNames
				     objectAtIndex: i];

          if (destinationRelationship != relationship)
            {
              // flattened: take destattr
              attributeName = destinationAttributeName;
            }
          else
            {
              EOAttribute *sourceAttribute = [join sourceAttribute];

              attributeName = [sourceAttribute name];
            }

          if (keyPrefix)
            attributeName=[keyPrefix stringByAppendingString:attributeName];

          EOFLOGObjectLevelArgs(@"EOQualifier", 
                                @"key=%@ keyPrefix=%@ attributeName=%@", 
                                key, keyPrefix,attributeName);

          attributeValue = [keyValues objectForKey:destinationAttributeName];

          EOFLOGObjectLevelArgs(@"EOQualifier", 
                                @"destinationAttributeName=%@ attributeValue=%@", 
                                destinationAttributeName, attributeValue);

          tmpQualifier = [EOKeyValueQualifier
			   qualifierWithKey: attributeName
			   operatorSelector: sel
			   value: (attributeValue ? attributeValue : GDL2_EONull)];

          EOFLOGObjectLevelArgs(@"EOQualifier", 
                                @"tmpQualifier=%@", 
                                tmpQualifier);

          if (qualifier)//Already a qualifier
            {
              //Create an array of qualifiers
              qualifiers = [NSMutableArray arrayWithObjects: qualifier,
					   tmpQualifier, nil];
              qualifier = nil;
            }
          else if (qualifiers) //Already qualifiers
            //Add this one
            [qualifiers addObject: tmpQualifier];
          else
            //No previous qualifier
            qualifier = tmpQualifier;
        }

      if (qualifiers)
        {
          qualifier = [EOAndQualifier qualifierWithQualifierArray: qualifiers];
        }
    }
  else // It's not a relationship. Nothing to do.
    qualifier = self;

  EOFLOGObjectLevelArgs(@"EOQualifier", @"self=%@", self);
  EOFLOGObjectLevelArgs(@"EOQualifier", @"result qualifier=%@", qualifier);



  return qualifier;
}

@end

@implementation EONotQualifier (EOQualifierSQLGeneration)

- (NSString *)sqlStringForSQLExpression: (EOSQLExpression *)sqlExpression
{
  return [sqlExpression sqlStringForNegatedQualifier: _qualifier];
}

- (EOQualifier *)schemaBasedQualifierWithRootEntity: (EOEntity *)entity
{
  EOQualifier *returnedQualifier = self;
  EOQualifier *schemaBasedQualifier;

  schemaBasedQualifier 
    = [_qualifier schemaBasedQualifierWithRootEntity: entity];

  // If we've got a different qualifier, return a new EONotQualifier
  if (schemaBasedQualifier != _qualifier)
    {
      returnedQualifier 
	= [[self class] qualifierWithQualifier: schemaBasedQualifier];
    }

  return returnedQualifier;
}

@end


@implementation NSString (NSStringSQLExpression)

- (NSString *) valueForSQLExpression: (EOSQLExpression *)sqlExpression
{
  return self;
}

@end
