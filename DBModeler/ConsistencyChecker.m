/**
    ConsistencyChecker.m
 
    Author: Matt Rice <ratmice@yahoo.com>
    Date: 2005, 2006

    This file is part of DBModeler.
    
    <license>
    DBModeler is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    DBModeler is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with DBModeler; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
    </license>
**/

#include "ConsistencyChecker.h"
#include "Preferences.h"

#include <EOModeler/EOModelerApp.h>
#include <EOModeler/EOModelerDocument.h>
#include <EOModeler/EOModelExtensions.h>

#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>
#include <EOAccess/EOModel.h>
#include <EOAccess/EORelationship.h>

#include <Foundation/NSNotification.h>

#define MY_PRETTY NSMutableAttributedString \
	mutableAttributedStringWithBoldSubstitutionsWithFormat

static NSMutableArray *successText;
static EOModelerDocument *doc;

@implementation ConsistencyChecker
+(void) initialize
{
  [[NSNotificationCenter defaultCenter]
  	addObserver:self
  	   selector:@selector(beginConsistencyCheck:)
	       name:EOMCheckConsistencyBeginNotification
	     object:nil];

  [[NSNotificationCenter defaultCenter]
  	addObserver:self
  	   selector:@selector(endConsistencyCheck:)
	       name:EOMCheckConsistencyEndNotification
	     object:nil];

  [[NSNotificationCenter defaultCenter]
  	addObserver:self
  	   selector:@selector(modelConsistencyCheck:)
	       name:EOMCheckConsistencyForModelNotification
	     object:nil];

  successText = [[NSMutableArray alloc] initWithCapacity:8];  
}

+ (void) beginConsistencyCheck:(NSNotification *)notif
{
}

+ (void) endConsistencyCheck:(NSNotification *)notif
{
  unsigned i,c;
  doc = [notif object];
  for (i = 0, c = [successText count]; i < c; i++)
     {
       [doc appendConsistencyCheckSuccessText:[successText objectAtIndex:i]]; 
     }
  doc = nil;
  [successText removeAllObjects];
}
/* helper functions */
static void pass(BOOL flag, NSAttributedString *as)
{
  if (flag)
    {
      [successText addObject:as];
    }
  else
    [doc appendConsistencyCheckErrorText: as];
}

static BOOL isInvalid(NSString *str)
{
  return (str == nil) || ([str length] == 0) ? YES : NO; 
}

+ (void) attributeDetailsCheckForModel:(EOModel *)model
{
  NSArray *ents = [model entities];
  unsigned i, c;
  BOOL flag = YES; 
  
  for (i = 0, c = [ents count]; i < c; i++)
    {
      EOEntity *entity = [ents objectAtIndex:i];
      NSArray *arr = [entity attributes];
      unsigned j, d;

      for (j = 0, d = [arr count]; j < d; j++)
	{
	  EOAttribute *attrib = [arr objectAtIndex:j];
	  NSString *className = [attrib valueClassName];

	  if ([[attrib className] isEqualToString:@"NSNumber"])
	    {
	      if (isInvalid([attrib externalType]))
	        {
		  pass(NO,[MY_PRETTY: @"Fail: %@ of type 'NSNumber has no external type\n",[(EOAttribute *)attrib name]]);
		  flag = NO;
		}
	    }
	  
	  /* TODO check whether NSCalendarDate/NSData require valueFactory...*/
	  if ((!isInvalid(className))
	       && (![className isEqual:@"NSString"]
	             && ![className isEqual:@"NSNumber"]
	             && ![className isEqual:@"NSDecimalNumber"]
		     && ![className isEqual:@"NSDate"]
		     && ![className isEqual:@"NSData"])
	       && (isInvalid([attrib valueFactoryMethodName])))
	    {
	       pass(NO,[MY_PRETTY: @"Fail: attribute '%@' of type '%@' requires a value factory method name\n",[(EOAttribute *)attrib name], className]);
	       flag = NO;
	    }
	}
      /* relationship primary key propagation */
      arr = [entity relationships];
      for (j = 0, d = [arr count]; j < d; j++)
        { 
	  EORelationship *rel = [arr objectAtIndex:j];
	  
	  if ([rel propagatesPrimaryKey] == YES)
	    {
	      NSArray *attribs = [rel sourceAttributes];
	      NSArray *pkAttribs = [[rel entity] primaryKeyAttributes];
	      unsigned k, e;
	      id pkey;
	      BOOL ok = YES;

	      for (k = 0, e = [pkAttribs count]; ok == YES && k < e; i++)
		{
		  pkey = [pkAttribs objectAtIndex:k];
	          ok = [attribs containsObject:pkey];
		}
	      
	      if (ok == NO)
		{
		  pass(NO,[MY_PRETTY: @"Fail: relationship '%@' propagates primary key but its source attributes does not contain the source entity's primary key attributes\n",[(EORelationship *)rel name]]);
		  flag = NO;
		}
	      
	      ok = YES;
	      attribs = [rel destinationAttributes];
	      pkAttribs = [[rel destinationEntity] primaryKeyAttributes];
	      
	      for (k = 0, e = [pkAttribs count]; ok == YES && k < e; i++)
		{
		  pkey = [pkAttribs objectAtIndex:k];
	          ok = [attribs containsObject:pkey];
		}
	      
	      if (ok == NO)
		{
		  pass(NO, [MY_PRETTY: @"Fail: relationship '%@' propagates primary key but its destination attributes does not contain the destination entity's primary key attributes\n",[(EORelationship *)rel name]]);
		  flag = NO;
		}
	    }
        }
    }
  if (flag == YES)
    pass(YES, [MY_PRETTY: @"Success: attribute detail check\n"]);
}

+ (void) entityStoredProcedureCheckForModel:(EOModel *)model
{
  /* TODO */
}

+ (void) storedProcedureCheckForModel:(EOModel *)model
{
 /* TODO */
}

+ (void) inheritanceCheckForModel:(EOModel *)model
{
  BOOL flag = YES; 
  NSArray *ents = [model entities];
  unsigned i,c;
  
  for (i = 0, c = [ents count]; i < c; i++)
    { 
      EOEntity *ent = [ents objectAtIndex:i];
      NSArray *subEnts = [ent subEntities];
      unsigned j, d;
      
      for (j = 0, d = [subEnts count]; j < d; j++)
        {
	  EOEntity *subEnt = [subEnts objectAtIndex:j];
          NSArray *arr = [ent attributes];
	  NSArray *subArr = [subEnt attributes];
	  unsigned k, e;
	  
	  for (k = 0, e = [arr count]; k < e; k++) 
            {
	      EOAttribute *attrib = [arr objectAtIndex:k];
	      
	      if (![subArr containsObject:[(EOAttribute *)attrib name]])
		{
		  pass(NO, [MY_PRETTY: @"FAIL: sub entity '%@' missing parent's '%@' attribute",[(EOEntity *)subEnt name], [(EOAttribute *)attrib name]]);
		  flag = NO;
		}
	    }

	  arr = [ent relationships];
	  for (k = 0, e = [arr count]; k < e; k++)
	    {
	      EORelationship *rel = [arr objectAtIndex:k];
	      EORelationship *subRel = [subEnt relationshipNamed:[(EORelationship *)rel name]];
	      
	      if (!subRel || ![[rel definition] isEqual:[subRel definition]])
		{
		  pass(NO, [MY_PRETTY: @"FAIL: sub entity '%@' missing relationship '%@' or definitions do not match", [(EOEntity *)subEnt name], [(EORelationship *)rel name]]);
		  flag = NO;
		}
	    }

	  arr = [ent primaryKeyAttributes];
	  subArr = [subEnt primaryKeyAttributes];
	  if (![arr isEqual:subArr])
	    {
	      pass(NO, [MY_PRETTY: @"FAIL: sub entity '%@' and parent entities primary keys do not match", [(EOEntity *)subEnt name]]);
	      flag = NO;
	    }
	  if ([[subEnt externalName] isEqual:[ent externalName]] 
	      && (![subEnt restrictingQualifier] || ![ent restrictingQualifier]))
	    {
	      pass(NO, [MY_PRETTY: @"FAIL: sub entity '%@' and parent entity in same table must contain a restricting qualifier", [(EOEntity *)subEnt name]]); 
	      flag = NO;
	    }
	}
    }
 
  if (flag == YES)
    {
      pass(YES, [MY_PRETTY: @"Success: inheritance check"]);
    }
}

+ (void) relationshipCheckForModel:(EOModel *)model
{
  /* TODO */
  NSArray *ents = [model entities];
  unsigned i, c;
  BOOL flag = YES;
  
  for (i = 0, c = [ents count]; i < c; i++)
    {
      EOEntity *ent = [ents objectAtIndex:i];
      NSArray *arr = [ent relationships];
      unsigned j, d;
      
      for (j = 0, d = [arr count]; j < d; j++)
	{
	  id rel = [arr objectAtIndex:j];
	  
	  if (![[rel joins] count])
	    {
	      pass(NO,[MY_PRETTY: @"Fail: relationship '%@' does not contain a join\n", [(EORelationship *)rel name]]);
	      flag = NO;
	    }

	  if ([rel isToMany] == NO)
            {
	      NSArray *pkAttribs = [[rel destinationEntity]
		      				primaryKeyAttributes];
	      NSArray *attribs = [rel destinationAttributes];
	      
	      if (![pkAttribs isEqual:attribs])
		{
		  pass(NO, [MY_PRETTY: @"Fail: destination attributes of relationship '%@' are not the destination entity primary keys\n",[(EORelationship *)rel name]]); 
	          flag = NO;
	        }
	    }

	  if ([rel propagatesPrimaryKey])
	    {
	      NSArray *pkAttribs = [[rel entity] primaryKeyAttributes];
	      NSArray *attribs = [rel sourceAttributes];
	      unsigned k, e;
	      BOOL ok = YES;

	      for (k = 0, e = [pkAttribs count]; ok == YES && k < e; k++) 
		 {
		   ok = [attribs containsObject: [pkAttribs objectAtIndex:k]];
		 }

	      if (ok == NO)
		{
		  pass(NO, [MY_PRETTY: @"Fail: relationship '%@' propagates primary keys but does not contain source entities primary key attributes\n", [(EORelationship *)rel name]]);
		  flag = NO;
		}
	      
	      pkAttribs = [[rel destinationEntity] primaryKeyAttributes];
	      attribs = [rel destinationAttributes];

	      for (k = 0, e = [pkAttribs count]; ok == YES && k < e; k++) 
		 {
		   ok = [attribs containsObject: [pkAttribs objectAtIndex:k]];
	         }

	      if (ok == NO)
		{
		  pass(NO, [MY_PRETTY: @"Fail: relationship '%@' propagates primary keys but does not contain destination entities primary key attributes\n", [(EORelationship *)rel name]]);
		  flag = NO;
		}
	      
	      if ([[rel inverseRelationship] propagatesPrimaryKey])
		{
		  pass(NO,[MY_PRETTY: @"Fail: both relationship '%@' and inverse relationship '%@' should not propagate primary keys\n", [(EORelationship *)rel name], [(EORelationship *)[rel inverseRelationship] name]]);
		  flag = NO;
		}
	    }
	}
    }
  if (flag == YES)
    pass(YES, [MY_PRETTY: @"Success: relationship check\n"]);
}

+ (void) primaryKeyCheckForModel:(EOModel *)model
{
  NSArray *ents = [model entities];
  unsigned i,c;
  BOOL flag = YES;

  for (i = 0, c = [ents count]; i < c; i++)
     {
       EOEntity *entity = [ents objectAtIndex:i];
       NSArray *arr = [entity primaryKeyAttributes];
       
       if (![arr count])
 	 {
           pass(NO,[MY_PRETTY: @"Fail: Entity '%@' does not have a primary key.\n", [(EOEntity *)entity name]]);
	   flag = NO;
	 }
     }
  if (flag == YES)
    pass(YES, [MY_PRETTY:@"Success: primary key check\n"]);
}

+ (void) externalNameCheckForModel:(EOModel *)model
{
  NSArray *ents = [model entities];
  NSArray *arr;
  unsigned i, c, j, d;
  BOOL flag = YES;

  for (i = 0,c = [ents count]; i < c; i++)
    {
      EOEntity *entity = [ents objectAtIndex:i];
      NSString *extName = [entity externalName];
      if (isInvalid(extName))
	{
	  pass(NO,[MY_PRETTY: @"Fail: Entity '%@' does not have an external name\n",
			  	  [(EOEntity *)entity name]]);
	  flag = NO;
	}
      arr = [entity attributes];
      for (j = 0, d = [arr count]; j<d; j++)
        {
          EOAttribute *attrib = [arr objectAtIndex:j];
	  
          extName = [attrib columnName];
          if (isInvalid(extName))
	    {
	      pass(NO,[MY_PRETTY: @"Fail: Attribute '%@' does not have an external name\n",
			  	  [(EOAttribute *)attrib name]]);
	      flag = NO;
            }

	  extName = [attrib valueClassName];
	  if (isInvalid(extName))
	    {
	      pass(NO,[MY_PRETTY: @"Fail: Attribute '%@' does not have a value class name\n", [(EOAttribute *)attrib name]]);
	      flag = NO;
	    }
	}
     }
  if (flag == YES)
    pass(YES, [MY_PRETTY: @"Success: external name check\n"]);
}

+ (void) modelConsistencyCheck:(NSNotification *)notif
{
  EOModel *model = [[notif userInfo] objectForKey:EOMConsistencyModelObjectKey];
  doc = [notif object];

  if ([[DBModelerPrefs sharedPreferences] attributeDetailsCheck])
    [self attributeDetailsCheckForModel:model];
  
  if ([[DBModelerPrefs sharedPreferences] primaryKeyCheck])
    [self primaryKeyCheckForModel:model];
  
  if ([[DBModelerPrefs sharedPreferences] externalNameCheck])
    [self externalNameCheckForModel:model];
  
  if ([[DBModelerPrefs sharedPreferences] relationshipCheck])
    [self relationshipCheckForModel:model];
  
  if ([[DBModelerPrefs sharedPreferences] inheritanceCheck])
    [self inheritanceCheckForModel:model];
  
  if ([[DBModelerPrefs sharedPreferences] storedProcedureCheck])
    [self storedProcedureCheckForModel:model]; 
  
  if ([[DBModelerPrefs sharedPreferences] entityStoredProcedureCheck])
    [self entityStoredProcedureCheckForModel:model];

  doc = nil;
}
@end
