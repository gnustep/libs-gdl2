/**
    DefaultColumnProvider.m
 
    Author: Matt Rice <ratmice@yahoo.com>
    Date: Apr 2005

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
#include <AppKit/NSCell.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSImage.h>

#include <Foundation/NSDictionary.h>

#define DICTSIZE(dict) (sizeof(dict) / sizeof(dict[0]))
#define uhuh (id)1
static DefaultColumnProvider *_sharedDefaultColumnProvider;
static NSMutableDictionary *_aspectsAndKeys;

/*	object			key 			default */
static id attribute_columns[][3] = {
	@"allowsNull",		@"Allows null",		nil, 
	@"isClassProperty",	@"Class property",	uhuh,
	@"columnName",		@"Column name",		uhuh,
	@"definition",		@"Definition",		nil,
	@"externalType",	@"External Type",	uhuh,
	@"isUsedForLocking",	@"Locking",		uhuh,
	@"name",		@"Name",		uhuh,
	@"precision",		@"Precision", 	 	nil,	
	@"isPrimaryKey",	@"Primary key",		uhuh,
	@"readFormat",		@"Read format", 	nil,
	@"scale",		@"Scale",		nil, 
	@"valueClassName",	@"Value class name",	uhuh,
	@"valueType",		@"Value type",		nil,
	@"width",		@"Width",		uhuh, 
	@"writeFormat",		@"Write format",	nil 
};
  
static id relationship_columns[][3]= {
	@"isClassProperty",		@"Class Property",	uhuh,
	@"definition",			@"Definition",		nil, 
	@"name",			@"Name",		uhuh,
	@"destinationEntity.name",	@"Destination Entity",  uhuh	
	
};

static id entity_columns[][3] = {
	 @"name",		@"Name",		uhuh,
	 @"className",		@"Class name",		uhuh,
	 @"externalName",	@"External name",	uhuh,
	 @"externalQuery",	@"External query",	nil,
	 @"parentEntity.name",	@"Parent",		nil

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
 * or something not sure if id columns[][2] would work as a method so i'll use
 * a function.. it _should_ but iirc buggy somewhere (forwarding?) */
void registerColumnsForClass(id columns[][3], int count, Class aClass,NSMutableArray *defaultColumnsArray)
{
  id *objects;
  id *keys;
  int i,c;
  size_t size;
  NSDictionary *tmp;
  size = (count * sizeof(id));

  objects = (id *)NSZoneMalloc([_sharedDefaultColumnProvider zone], size);
  keys = (id *)NSZoneMalloc([_sharedDefaultColumnProvider zone], size);

  for (i = 0; i < count; i++)
     {
       objects[i] = columns[i][0];
       keys[i] = columns[i][1];
       if (columns[i][2] == uhuh)
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
      [cell setEditable:YES];
      return cell;
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
      [cell setEditable:YES];
      return cell;
    }
  else if ([name isEqual:@"Locking"])
    {
      NSButtonCell *cell = [[NSButtonCell alloc] initImageCell:nil];

      [cell setButtonType:NSSwitchButton];
      [cell setImagePosition:NSImageOnly];
      [cell setBordered:NO];
      [cell setBezeled:NO];
      [cell setAlternateImage:[NSImage imageNamed:@"ClassProperty_On"]];
      [cell setControlSize: NSSmallControlSize];
      [cell setEditable:YES];
      return cell;
    }
  else
    {
      NSTextFieldCell *cell = [[NSTextFieldCell alloc] initTextCell:@""];
      [cell setEnabled:YES];
      [cell setEditable:YES];
      [cell setScrollable: YES];
      return cell;
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
    [[tc headerCell] setStringValue:columnName];
    cell = [self cellForColumnNamed:columnName];
    [tc setEditable:[cell isEditable]];
    [tc setDataCell:cell];
    [association bindAspect:aspect displayGroup:displayGroup key:aspectKey];
    [association establishConnection];
    [association release];
}

@end
