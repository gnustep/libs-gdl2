/* 
   PostgresAdaptor.h

   Copyright (C) 2000,2002,2003,2005 Free Software Foundation, Inc.

   Author: Mirko Viviani <mirko.viviani@gmail.com
   Date: February 2000

   based on the Postgres adaptor written by
         Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   This file is part of the GNUstep Database Library.

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#ifndef __PostgresAdaptor_h__
#define __PostgresAdaptor_h__

#include <EOAccess/EOAdaptor.h>


/* Include Postgres Headers */

#undef Assert
#include <stdio.h>
#include <libpq-fe.h>
#include <libpq/libpq-fs.h>
#include <pg_config.h>
#undef Assert

@class NSMutableArray;
@class NSMutableSet;

/* The following keys are meaningful in the connectionDictionary in a model:

    databaseServer or hostName - the name of the server 
	(default getenv(PGHOST) or localhost)
    databaseName - the name of the database to use 
	(default getenv(PGDATABASE))
    databaseVersion - the Version of the database
	(default parsed from #define PG_VERSION)
    options - additional options sent to the POSTGRES backend
	(default getenv(PGOPTIONS))
    port - port to communicate with POSTGRES backend
	(default getenv(PGPORT))
    debugTTY - filename (file/device) used for debugging output
	(default getenv(PGTTY))
    primaryKeySequenceNameFormat - Format for pk sequence name;
         like @"%@_SEQ" or @"EOSEQ_%@", "%@" is replaced by external table name
         (default: @"%@_SEQ")
    NOTE: user name is not given explicitly - the library uses the 
          real user id of the user running the program and that user id
	  is interpreted by the server (AFAIK)
*/

extern int
postgresClientVersion();

@interface PostgresAdaptor : EOAdaptor
{
  NSMutableArray *_pgConnPool;
  int _pgConnPoolLimit;
  NSString* _primaryKeySequenceNameFormat;
  struct {
    BOOL cachePGconn:1;
  } _flags;
}

/* Reporting errors */
- (void)privateReportError: (PGconn *)pgConn;

/* Configure the adaptor to share the PGconn or not. The default is not to
   share PGconn. */ 
- (void)setCachePGconn: (BOOL)flag;
- (BOOL)cachePGconn;
- (void)setPGconnPoolLimit: (int)newLimit;
- (int)pgConnPoolLimit;

/* Inherited methods */

// Private methods

/* Obtaining and releasing a PGconn from pool */
- (PGconn *)createPGconn;
- (PGconn *)newPGconn;
- (void)releasePGconn: (PGconn *)pgConn force: (BOOL)flag;

// format is something like @"%@_SEQ" or @"EOSEQ_%@", "%@" is replaced by external table name
- (void)setPrimaryKeySequenceNameFormat: (NSString*)format;
- (NSString*)primaryKeySequenceNameFormat;

extern NSString *PostgresException;

@end

#endif /* __PostgresAdaptor_h__ */
