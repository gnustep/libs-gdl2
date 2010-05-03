/* -*-objc-*-
   EOPrivat.h

   Copyright (C) 2005 Free Software Foundation, Inc.

   Author: Manuel Guesdon <mguesdon@orange-concept.com>
   Date: Jan 2005

   This file is part of the GNUstep Database Library.

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
*/

#ifndef __EOAccess_EOPrivat_h__
#define __EOAccess_EOPrivat_h__

#include "EODefines.h"
#include "../EOControl/EOPrivate.h"

#include "EOSQLQualifier.h"
#include "EORelationship.h"

@class EODatabaseContext;

// ==== Classes ====
GDL2ACCESS_EXPORT Class GDL2_EODatabaseContextClass;
GDL2ACCESS_EXPORT Class GDL2_EOAttributeClass;

// ==== IMPs ====
GDL2ACCESS_EXPORT IMP GDL2_EODatabaseContext_snapshotForGlobalIDIMP;
GDL2ACCESS_EXPORT IMP GDL2_EODatabaseContext__globalIDForObjectIMP;

// ==== Init Method ====
GDL2ACCESS_EXPORT void GDL2_EOAccessPrivateInit();

// ==== EODatabaseContext ====
GDL2ACCESS_EXPORT NSDictionary* EODatabaseContext_snapshotForGlobalIDWithImpPtr(EODatabaseContext* dbContext,IMP* impPtr,EOGlobalID* gid);
GDL2ACCESS_EXPORT EOGlobalID* EODatabaseContext_globalIDForObjectWithImpPtr(EODatabaseContext* dbContext,IMP* impPtr,id object);

/* EOQualifier implements schemaBasedQualifierWithRootEntity:
   but it instead of simply declaring and documenting that EOF
   merely declares the protocol for its subclasses and uses
   EORequestConcreteImplementation for other classes.
*/
@interface EOQualifier (EOQualifierSQLGeneration) <EOQualifierSQLGeneration>
@end


@interface EORelationship (PrivateAPI)

+ (EOJoinSemantic) _joinSemanticForName:(NSString*) semanticName;

+ (NSString*) _nameForJoinSemantic:(EOJoinSemantic) semantic;

@end


#endif /* __EOAccess_EOPrivat_h__ */
