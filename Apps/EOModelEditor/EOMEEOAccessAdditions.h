/**
 EOMEEOAccessAdditions.h <title>EOMEDocument Class</title>
 
 Copyright (C) Free Software Foundation, Inc.
 
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
 This file is part of DBModeler.
 
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

#ifndef __EOMEEOAccessAdditions_h
#define __EOMEEOAccessAdditions_h

#import <EOAccess/EOAccess.h>

@interface EOMEEOAccessAdditions:NSObject
{
}

+ (void)initialize;
@end

@interface EOAttribute (EOMEEOAccessAdditions)

+ (NSDictionary*) defaultColumnNames;

+ (NSDictionary*) allColumnNames;

- (NSArray*) observerKeys;

@end

@interface EORelationship (EOMEEOAccessAdditions)
+ (NSDictionary*) allColumnNames;

- (NSArray*) defaultColumnNames;

- (NSArray*) observerKeys;

- (NSArray*) sourceAttributeNames;

- (NSString*) humanReadableSourceAttributes;

- (NSArray*) destinationAttributeNames;

- (NSString*) humanReadableDestinationAttributes;

- (EOJoin*) joinFromAttributeNamed:(NSString*) atrName;

- (EOJoin*) joinToAttributeNamed:(NSString*) atrName;


@end

@interface EOEntity (EOMEEOAccessAdditions)

- (NSArray*) attributeNames;
- (NSArray*) observerKeys;

@end

@interface EOStoredProcedure (EOMEEOAccessAdditions)

+ (NSDictionary*) allColumnNames;

- (NSArray*) observerKeys;

@end

@interface EOModel (EOMEEOAccessAdditions)

- (NSArray*) observerKeys;

@end


#endif
