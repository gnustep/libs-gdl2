/**
 EOMEEOAccessAdditions.m <title>EOMEDocument Class</title>
 
 Copyright (C) Free Software Foundation, Inc.
 
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
 This file is part of EOModelEditor.
 
 <license>
 EOModelEditor is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.
 
 EOModelEditor is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with EOModelEditor; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 </license>
 **/

#import "EOMEEOAccessAdditions.h"

NSMutableArray *DefaultEntityColumns;
NSMutableArray *DefaultAttributeColumns;
NSMutableArray *DefaultRelationshipColumns;

static NSDictionary * defaultEOAttributeColumnNamesDict = nil;
static NSDictionary * allEOAttributeColumnNamesDict = nil;
static NSDictionary * allEORelationshipColumnNamesDict = nil;
static NSDictionary * allEOStoredProcedureColumnNamesDict = nil;

static NSArray * EOAttributeObserverKeys = nil;
static NSArray * EORelationshipObserverKeys = nil;
static NSArray * EOStoredProcedureObserverKeys = nil;
static NSArray * EOEOModelObserverKeys = nil;

struct column_info {
  NSString *key;
  NSInteger tag;
  NSString *name;
  BOOL isDefault;
};

static struct column_info attribute_columns[] = {
  {@"isPrimaryKey",      0, @"Primary key",      YES},
  {@"isClassProperty",   1, @"Class property",   YES},
  {@"allowNull",         2, @"Allows null",      YES}, 
  {@"isUsedForLocking",  3, @"Locking",          YES},
  {@"name",              4, @"Name",             YES},
  {@"columnName",        5, @"Column name",      YES},
  {@"valueClassName",    6, @"Value class name", YES},
  {@"externalType",      7, @"External Type",    YES},
  {@"width",             8, @"Width",            YES}, 
  {@"definition",        9, @"Definition",        NO},
  {@"precision",        10, @"Precision",         NO},
  {@"readFormat",       11, @"Read format",       NO},
  {@"scale",            12, @"Scale",             NO}, 
  {@"valueType",        13, @"Value type",        NO},
  {@"writeFormat",      14, @"Write format",      NO}, 
  {nil,                 1000, nil,                  NO} 
};

static struct column_info relationship_columns[]= {
  {@"isToMany",                          0,  @"Cardinality",     YES},
  {@"isClassProperty",                   1,  @"Class property",     YES},
  {@"name",                              2,  @"Name",               YES},
  {@"destinationEntity.name",            3,  @"Destination Entity", YES},
  {@"humanReadableSourceAttributes",     4,  @"Source Attribute",   YES},
  {@"humanReadableDestinationAttributes",5,  @"Destination Attribute",   YES},
  {@"definition",                        6,  @"Definition",          NO}, 
  {nil,                 1000, nil,                  NO} 
};

static struct column_info entity_columns[] = {
  {@"name",               0, @"Name",           YES},
  {@"className",          1, @"Class name",     YES},
  {@"externalName",       2, @"External name",  YES},
  {@"externalQuery",      4, @"External query",  NO},
  {@"parentEntity.name",  5, @"Parent",          NO},
  {nil,                 1000, nil,                  NO} 
};

static struct column_info procedure_columns[] = {
  {@"name",               0, @"Name",           YES},
  {@"parameterDirection", 1, @"Direction",      YES},
  {@"columnName",         2, @"Column name",    YES},
  {@"valueClassName",     3, @"Value class name",NO},
  {@"externalType",       4, @"External type",   NO},
  {@"width",              5, @"Width",           NO},
  {@"precision",          6, @"Precision",       NO},
  {@"scale",              7, @"Scale",           NO},
  {@"valueType",          8, @"Value type",      NO},
  {nil,                 1000, nil,                  NO} 
};

@implementation EOMEEOAccessAdditions

+ (void)initialize
{
  if (DefaultRelationshipColumns) {
    // nothing to do
    return;
  }
  
  NSLog(@"%s", __PRETTY_FUNCTION__);
  
  DefaultRelationshipColumns = [[NSMutableArray alloc] init];
  
  //  _sharedDefaultColumnProvider = [[self alloc] init];
  //  _aspectsAndKeys = [[NSMutableDictionary alloc] init]; 
}

+ (NSDictionary*) defaultColumnNamesForDict:(struct column_info*) staticDict onlyDefault:(BOOL) onlyDefault
{
  NSInteger i = 0;
  NSMutableDictionary * mDict = [NSMutableDictionary new];
  
  for (i = 0; staticDict[i].key != nil; i++)
  {
    if ((onlyDefault == NO) || (staticDict[i].isDefault == YES))
    {
      NSDictionary * sDict = [NSDictionary dictionaryWithObjectsAndKeys:staticDict[i].name, @"name",
                              staticDict[i].key, @"key", nil];
      
      [mDict setObject: sDict
                forKey: [NSNumber numberWithInteger:staticDict[i].tag]];      
    }
  }
  
  return mDict;
}

+ (NSArray*) keysFromDict:(struct column_info*) staticDict
{
  NSMutableArray * mArray = [NSMutableArray array];
  NSInteger i = 0;

  for (i = 0; staticDict[i].key != nil; i++)
  {
    [mArray addObject:staticDict[i].key];     
  }
  return mArray;
}

@end


@implementation EOAttribute (EOMEEOAccessAdditions)


+ (NSDictionary*) defaultColumnNames
{
  if (!defaultEOAttributeColumnNamesDict) {
    defaultEOAttributeColumnNamesDict = [EOMEEOAccessAdditions defaultColumnNamesForDict:&attribute_columns[0] 
                                                                             onlyDefault:YES];
  }
  return defaultEOAttributeColumnNamesDict;
}

+ (NSDictionary*) allColumnNames
{
  if (!allEOAttributeColumnNamesDict) {
    allEOAttributeColumnNamesDict = [EOMEEOAccessAdditions defaultColumnNamesForDict:&attribute_columns[0] 
                                                                         onlyDefault:NO];
  }
  return allEOAttributeColumnNamesDict;
}

- (NSArray*) observerKeys
{
  if (!EOAttributeObserverKeys) {
    NSMutableArray  * mutArray;
    NSArray         * tmpArray = [NSArray arrayWithArray:[EOMEEOAccessAdditions 
                                                          keysFromDict:&attribute_columns[0]]];

    mutArray = [NSMutableArray arrayWithArray:tmpArray];
    
    tmpArray = [NSArray arrayWithObjects:@"isReadOnly",
                                         @"allowsNull",
                                         @"parameterDirection",
                                         nil];
    
    [mutArray addObjectsFromArray:tmpArray];
    
    EOAttributeObserverKeys = mutArray;
    [EOAttributeObserverKeys retain];
  }
  return EOAttributeObserverKeys;
}

@end

@implementation EORelationship (EOMEEOAccessAdditions)

+ (NSDictionary*) allColumnNames
{
  if (!allEORelationshipColumnNamesDict) {
    allEORelationshipColumnNamesDict = [EOMEEOAccessAdditions defaultColumnNamesForDict:&relationship_columns[0] 
                                                                            onlyDefault:NO];
  }
  return allEORelationshipColumnNamesDict;
}

- (NSArray*) observerKeys
{
  if (!EORelationshipObserverKeys) {
    EORelationshipObserverKeys = [NSArray arrayWithObjects:@"toMany",
                                  @"classProperty",
                                  @"name",
                                  @"destinationEntity",
                                  @"definition",
                                  @"joins",
                                  @"joinSemantic",
                                  @"isMandatory",
                                  @"numberOfToManyFaultsToBatchFetch",
                                  @"deleteRule",
                                  @"ownsDestination",
                                  @"propagatesPrimaryKey",
                                  nil];
    [EORelationshipObserverKeys retain];
  }
  return EORelationshipObserverKeys;
}

- (NSArray*) sourceAttributeNames
{
  NSMutableArray * mArray = [NSMutableArray array];
  NSEnumerator   * enumer = [[self sourceAttributes] objectEnumerator];
  EOAttribute    * currentAttr = nil;
  
  while ((currentAttr = [enumer nextObject])) {
    [mArray addObject:[currentAttr name]];
  }
  
  return mArray;
}

- (NSString*) humanReadableSourceAttributes
{
  return [[self sourceAttributeNames] componentsJoinedByString:@", "];
}

- (NSArray*) destinationAttributeNames
{
  NSMutableArray * mArray = [NSMutableArray array];
  NSEnumerator   * enumer = [[self destinationAttributes] objectEnumerator];
  EOAttribute    * currentAttr = nil;
  
  while ((currentAttr = [enumer nextObject])) {
    [mArray addObject:[currentAttr name]];
  }
  
  return mArray;
}


- (NSString*) humanReadableDestinationAttributes
{
  return [[self destinationAttributeNames] componentsJoinedByString:@", "];
}

- (EOJoin*) joinFromAttributeNamed:(NSString*) atrName
{
  NSArray      * joins = [self joins];
  NSEnumerator * enumer;
  EOJoin       * currentJoin;
  
  if ([joins count] < 1) {
    return nil;
  }
  
  enumer = [joins objectEnumerator];
  
  while ((currentJoin = [enumer nextObject])) {
    if (([[[currentJoin sourceAttribute] name] isEqual:atrName])) {
      return currentJoin;
    }
  }
  
  return nil;
}

- (EOJoin*) joinToAttributeNamed:(NSString*) atrName
{
  NSArray      * joins = [self joins];
  NSEnumerator * enumer;
  EOJoin       * currentJoin;
  
  if ([joins count] < 1) {
    return nil;
  }
  
  enumer = [joins objectEnumerator];
  
  while ((currentJoin = [enumer nextObject])) {
    if (([[[currentJoin destinationAttribute] name] isEqual:atrName])) {
      return currentJoin;
    }
  }
  
  return nil;
}


@end

@implementation EOEntity (EOMEEOAccessAdditions)

- (NSArray*) attributeNames
{
  NSMutableArray * mArray = [NSMutableArray array];
  NSEnumerator   * enumer = [[self attributes] objectEnumerator];
  EOAttribute    * currentAttr = nil;
  
  while ((currentAttr = [enumer nextObject])) {
    [mArray addObject:[currentAttr name]];
  }
  
  return mArray;
}

- (NSArray*) observerKeys
{
  if (!EORelationshipObserverKeys) {
    EORelationshipObserverKeys = [NSArray arrayWithObjects:@"externalName",
                                  @"className",
                                  @"name",
                                  @"maxNumberOfInstancesToBatchFetch",
                                  @"externalQuery",
                                  nil];
    [EORelationshipObserverKeys retain];
  }
  return EORelationshipObserverKeys;
}


@end

@implementation EOStoredProcedure (EOMEEOAccessAdditions)

+ (NSDictionary*) allColumnNames
{
  if (!allEOStoredProcedureColumnNamesDict) {
    allEOStoredProcedureColumnNamesDict = [EOMEEOAccessAdditions defaultColumnNamesForDict:&procedure_columns[0] 
                                                                               onlyDefault:NO];
  }
  return allEOStoredProcedureColumnNamesDict;
}

- (NSArray*) observerKeys
{
  if (!EOStoredProcedureObserverKeys) {
    EOStoredProcedureObserverKeys = [NSArray arrayWithObjects:@"externalName",
                                     @"name",
                                     @"parameterDirection",
                                     nil];
    [EOStoredProcedureObserverKeys retain];
  }
  return EOStoredProcedureObserverKeys;
}


@end

@implementation EOModel (EOMEEOAccessAdditions)

- (NSArray*) observerKeys
{
  if (!EOEOModelObserverKeys) {
    EOEOModelObserverKeys = [NSArray arrayWithObjects:@"connectionDictionary",
                             @"userInfo",
                             nil];
    [EOEOModelObserverKeys retain];
  }
  return EOEOModelObserverKeys;
}

@end
