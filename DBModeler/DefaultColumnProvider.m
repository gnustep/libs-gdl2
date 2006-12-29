/**
    DefaultColumnProvider.m
 
    Author: Matt Rice <ratmice@yahoo.com>
    Date: Apr 2005, 2006

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


#include "DefaultColumnProvider.h"
#include "ModelerEntityEditor.h"

#include <EOModeler/EOModelerApp.h>
#include <EOInterface/EOColumnAssociation.h>
#include <EOAccess/EOAttribute.h>
#include <EOAccess/EOEntity.h>

#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSImage.h>

#include <Foundation/NSDictionary.h>

#define DICTSIZE(dict) (sizeof(dict) / sizeof(dict[0]))

static DefaultColumnProvider *_sharedDefaultColumnProvider;
static NSMutableDictionary *_aspectsAndKeys;

NSMutableArray *DefaultEntityColumns;
NSMutableArray *DefaultAttributeColumns;
NSMutableArray *DefaultRelationshipColumns;

struct column_info {
  NSString *key;
  NSString *name;
  BOOL isDefault;
};

static struct column_info attribute_columns[] = {
	{@"isPrimaryKey",	@"Primary key",		YES},
	{@"isClassProperty",	@"Class property",	YES},
	{@"allowNull",		@"Allows null",		YES}, 
	{@"isUsedForLocking",	@"Locking",		YES},
	{@"name",		@"Name",		YES},
	{@"columnName",		@"Column name",		YES},
	{@"valueClassName",	@"Value class name",	YES},
	{@"externalType",	@"External Type",	YES},
	{@"definition",		@"Definition",		NO},
	{@"precision",		@"Precision", 	 	NO},	
	{@"readFormat",		@"Read format", 	NO},
	{@"scale",		@"Scale",		NO}, 
	{@"valueType",		@"Value type",		NO},
	{@"width",		@"Width",		YES}, 
	{@"writeFormat",	@"Write format",	NO} 
};
  
static struct column_info relationship_columns[]= {
	{@"isClassProperty",		@"Class property",	YES},
	{@"definition",			@"Definition",		NO}, 
	{@"name",			@"Name",		YES},
	{@"destinationEntity.name",	@"Destination Entity",  YES}	
	
};

static struct column_info entity_columns[] = {
	{@"name",		@"Name",		YES},
	{@"className",		@"Class name",		YES},
	{@"externalName",	@"External name",	YES},
	{@"externalQuery",	@"External query",	NO},
	{@"parentEntity.name",	@"Parent",		NO}

};

@implementation DefaultColumnProvider
/* function to create a NSDictionary out of the c arrays..
 * which looks like
 { 
   Class = { 
   	     columnName1 = "aspectKey1";
	     columnName2 = "aspectKey2";
	   };
	   
   Class2 = {
	      otherColumnName = "otherAspectKey";
   	    };
 }
 */
void registerColumnsForClass(struct column_info columns[], int count, Class aClass,NSMutableArray *defaultColumnsArray)
{
  id *objects;
  id *keys;
  int i;
  size_t size;
  NSDictionary *tmp;
  size = (count * sizeof(id));

  objects = (id *)NSZoneMalloc([_sharedDefaultColumnProvider zone], size);
  keys = (id *)NSZoneMalloc([_sharedDefaultColumnProvider zone], size);

  for (i = 0; i < count; i++)
     {
       objects[i] = columns[i].key;
       keys[i] = columns[i].name;
       if (columns[i].isDefault == YES)
	 {
	   [defaultColumnsArray addObject:keys[i]]; 
	 }
     }
  tmp = [NSDictionary dictionaryWithObjects:objects
	  			    forKeys:keys
				      count:count];
  [EOMApp registerColumnNames: [tmp allKeys]
	  	     forClass: aClass
		     provider:_sharedDefaultColumnProvider];
  NSZoneFree([_sharedDefaultColumnProvider zone], objects);
  NSZoneFree([_sharedDefaultColumnProvider zone], keys);
  
  [_aspectsAndKeys setObject: tmp 
		      forKey: aClass];
}

+ (void)initialize
{
  
  DefaultEntityColumns = [[NSMutableArray alloc] init];
  DefaultAttributeColumns = [[NSMutableArray alloc] init];
  DefaultRelationshipColumns = [[NSMutableArray alloc] init];
  
  _sharedDefaultColumnProvider = [[self alloc] init];
  _aspectsAndKeys = [[NSMutableDictionary alloc] init]; 
  registerColumnsForClass(attribute_columns,
		  	  DICTSIZE(attribute_columns),
			  [EOAttribute class],
			  DefaultAttributeColumns); 
  registerColumnsForClass(entity_columns,
		  	  DICTSIZE(entity_columns),
			  [EOEntity class],
			  DefaultEntityColumns);
  registerColumnsForClass(relationship_columns,
		  	  DICTSIZE(relationship_columns),
			  [EORelationship class],
			  DefaultRelationshipColumns);
}

- (void) setupTitleForColumn:(NSTableColumn *)tc named:(NSString *)name
{
  NSTableHeaderCell *headerCell = (id)[tc headerCell];
  if ([name isEqual:@"Primary key"])
    {
      NSImage *img = [NSImage imageNamed:@"Key_Header"];
      [headerCell setImage:img];
    }
  else if ([name isEqual:@"Class property"])
    [headerCell setImage:[NSImage imageNamed:@"ClassProperty_Header"]];
  else if ([name isEqual:@"Locking"])
    [headerCell setImage:[NSImage imageNamed:@"Locking_Header"]];
  else if ([name isEqual:@"Allows null"])
    [headerCell setImage:[NSImage imageNamed:@"AllowsNull_Header"]];
  else if ([name isEqual:@"Name"])
    {
      [tc setWidth:100.0];
      [headerCell setStringValue:name];
      return;
    }
  else
    {
      [headerCell setStringValue:name];
    }
  [tc sizeToFit];
}

- (NSCell *)cellForColumnNamed:(NSString *)name
{

  /* TODO need a switch button for "Locking" and "Allows null" */
  if ([name isEqual:@"Primary key"])
    {
      NSButtonCell *cell = [[NSButtonCell alloc] initImageCell:nil];
      
      [cell setButtonType:NSSwitchButton];
      [cell setImagePosition:NSImageOnly];
      [cell setBordered:NO];
      [cell setBezeled:NO];
      [cell setAlternateImage:[NSImage imageNamed:@"Key_On"]];
      [cell setControlSize: NSSmallControlSize];
      [cell setEditable:NO];
      return AUTORELEASE(cell);
    }
  else if ([name isEqual:@"Class property"])
    {
      NSButtonCell *cell = [[NSButtonCell alloc] initImageCell:nil];

      [cell setButtonType:NSSwitchButton];
      [cell setImagePosition:NSImageOnly];
      [cell setBordered:NO];
      [cell setBezeled:NO];
      [cell setAlternateImage:[NSImage imageNamed:@"ClassProperty_On"]];
      [cell setControlSize: NSSmallControlSize];
      [cell setEditable:NO];
      return AUTORELEASE(cell);
    }
  else if ([name isEqual:@"Locking"])
    {
      NSButtonCell *cell = [[NSButtonCell alloc] initImageCell:nil];

      [cell setButtonType:NSSwitchButton];
      [cell setImagePosition:NSImageOnly];
      [cell setBordered:NO];
      [cell setBezeled:NO];
      [cell setAlternateImage:[NSImage imageNamed:@"Locking_On"]];
      [cell setControlSize: NSSmallControlSize];
      [cell setEditable:NO];
      return AUTORELEASE(cell);
    }
  else if ([name isEqual:@"Allows null"])
    {
      NSButtonCell *cell = [[NSButtonCell alloc] initImageCell:nil];

      [cell setButtonType:NSSwitchButton];
      [cell setImagePosition:NSImageOnly];
      [cell setBordered:NO];
      [cell setBezeled:NO];
      [cell setAlternateImage:[NSImage imageNamed:@"AllowsNull_On"]];
      [cell setControlSize: NSSmallControlSize];
      [cell setEditable:NO];
      return AUTORELEASE(cell);
    }
  else
    {
      NSTextFieldCell *cell = [[NSTextFieldCell alloc] init];
      [cell setEditable:YES];
      return AUTORELEASE(cell);
    }
}

- (void)initColumn:(NSTableColumn *)tc
             class:(Class)class 
	      name:(NSString *)columnName 
      displayGroup:(EODisplayGroup *)displayGroup 
          document:(EOModelerDocument *)doc
{
    EOColumnAssociation *association;
    NSCell		*cell;
    NSString		*aspectKey;
    NSString		*aspect;

    aspectKey = [[_aspectsAndKeys objectForKey:class] objectForKey:columnName];
    aspect = @"value";
    association = [[EOColumnAssociation alloc] initWithObject:tc];
    cell = [self cellForColumnNamed:columnName];
    [tc setEditable: [cell isEditable]];
    [tc setDataCell:cell];
    [self setupTitleForColumn:tc named:columnName];
    [association bindAspect:aspect displayGroup:displayGroup key:aspectKey];
    [association establishConnection];
    [association release];
}

@end
