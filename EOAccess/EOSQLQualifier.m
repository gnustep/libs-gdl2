/** 
   EOSQLQualifier.m <title>EOSQLQualifier Class</title>

   Copyright (C) 2002 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.coù>
   Date: February 2002

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

#include <stdio.h>
#include <string.h>

#ifdef GNUSTEP
#include <Foundation/NSDictionary.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSUtilities.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GNUstep.h>
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOAccess/EOSQLQualifier.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EORelationship.h>
#include <EOAccess/EOJoin.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOSQLExpression.h>

#include <EOControl/EOQualifier.h>
#include <EOControl/EOEditingContext.h>
#include <EOControl/EOObjectStoreCoordinator.h>
#include <EOControl/EONull.h>
#include <EOControl/EODebug.h>


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
  NSEmitTODO();  //TODO
  [self notImplemented: _cmd]; //TODO

  return nil;
}

- (EOQualifier *)schemaBasedQualifierWithRootEntity:(EOEntity *)entity
{
  [self notImplemented: _cmd];
  return nil;
}

- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)sqlExpression
{
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
  EOFLOGObjectFnStart();

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

	  [qualifiers addObject: schemaBasedQualifierTmp];
	}

      // If we've found at least a different qualifier, return a new EOAndQualifier
      if (atLeastOneDifferentQualifier)
          returnedQualifier = [[self class] qualifierWithQualifierArray:qualifiers];
    }

  EOFLOGObjectFnStop();

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
  EOFLOGObjectFnStart();

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

	  [qualifiers addObject: schemaBasedQualifierTmp];
	}

      // If we've found at least a different qualifier, return a new EOOrQualifier
      if (atLeastOneDifferentQualifier)
          returnedQualifier = [[self class] qualifierWithQualifierArray:qualifiers];
    }

  EOFLOGObjectFnStop();

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
  //TODO
  [self notImplemented: _cmd];
  return nil;
}

@end

@implementation EOKeyValueQualifier (EOQualifierSQLGeneration)

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

  EOFLOGObjectFnStart();

  key = [self key];
  EOFLOGObjectLevelArgs(@"EOQualifier", @"key=%@", key);

  relationship = [entity relationshipForPath: key];
  EOFLOGObjectLevelArgs(@"EOQualifier", @"relationship=%@", relationship);

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

      if ([relationship isFlattened])
        destinationRelationship = [relationship lastRelationship];
      else
        destinationRelationship = relationship;
      
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
      /*
when flattened: ???
             entity relationshipForPath:key
             and get joins on it ?
      */

      for (i = 0; i < count; i++)
        {
          EOQualifier *tmpQualifier = nil;
          NSString *attributeName = nil;
          NSString *destinationAttributeName;
          EOJoin *join = [joins objectAtIndex: i];
          id attributeValue = nil;
          EONull *eoNull=[EONull null];

          EOFLOGObjectLevelArgs(@"EOQualifier",@"join=%@",join);

          destinationAttributeName = [destinationAttributeNames
				     objectAtIndex: i];

          if (destinationRelationship != relationship)
            {
              // flattened: take destattr
              attributeName = [NSString stringWithFormat: @"%@.%@",
					key, destinationAttributeName];
              //==> rel.attr
            }
          else
            {
              EOAttribute *sourceAttribute = [join sourceAttribute];

              attributeName = [sourceAttribute name];
            }

          attributeValue = [keyValues objectForKey:destinationAttributeName];
          tmpQualifier = [EOKeyValueQualifier
			   qualifierWithKey: attributeName
			   operatorSelector: sel
			   value: (attributeValue ? attributeValue : eoNull)];

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
  else
    qualifier = self;

  EOFLOGObjectFnStop();

  return qualifier;
}

@end

@implementation EONotQualifier (EOQualifierSQLGeneration)

- (NSString *)sqlStringForSQLExpression: (EOSQLExpression *)sqlExpression
{
  return [sqlExpression sqlStringForNegatedQualifier: self];
}

- (EOQualifier *)schemaBasedQualifierWithRootEntity: (EOEntity *)entity
{
  //TODO
  [self notImplemented: _cmd];
  return nil;
}

@end


@implementation NSString (NSStringSQLExpression)

- (NSString *) valueForSQLExpression: (EOSQLExpression *)sqlExpression
{
  return self;
}

@end
