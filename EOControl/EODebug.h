/* debug.h - debug
   Copyright (C) 1999, 2002, 2003 Free Software Foundation, Inc.
   
   Written by:	Manuel Guesdon <mguesdon@sbuilders.com>
   Date: 	Jan 1999
   
   This file is part of the GNUstep Web Library.
   
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

// $Id$

#ifndef _EODebug_h__
#define _EODebug_h__

// call with --GNU-Debug=EOFFn

#ifdef DEBUG

#ifdef GNUSTEP
#include <Foundation/NSDebug.h>
#include <Foundation/NSAutoreleasePool.h>
#else
#include <Foundation/Foundation.h>
#endif

#ifndef GNUSTEP
#include <GNUstepBase/GSCategories.h>
#endif

#include <EOControl/EODefines.h>


GDL2CONTROL_EXPORT void EOFLogC_(const char* file,int line,const char* string);
GDL2CONTROL_EXPORT void EOFLogDumpObject_(const char* file,int line,
					  id object,int deep);
GDL2CONTROL_EXPORT void EOFLogAssertGood_(const char* file,int line,
					  id object);

#define EOFLogC(cString);		EOFLogC_(__FILE__,__LINE__,cString);
#define EOFLogDumpObject(object,deep); 	EOFLogDumpObject_(__FILE__,__LINE__,object,deep);
#define EOFLogAssertGood(object); 	EOFLogAssertGood_(__FILE__,__LINE__,object);
#else  // no DEBUG
#define EOFLogC(cString);
#define EOFLogDumpObject(object,deep);
#define EOFLogAssertGood(object);
#endif // DEBUG


#ifdef DEBUG

// call in Class-Methods

#define EOFLOGClassFnStart()  \
  do { if (GSDebugSet(@"EOFFn") == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugFunctionMsg(__PRETTY_FUNCTION__, __FILE__, __LINE__,@"FNSTART"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGObjectFnStartCond(cond)  \
  do { if ((GSDebugSet(@"EOFFn") == YES)  && GSDebugSet(cond) == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg(self, _cmd, __FILE__, __LINE__,@"FNSTART"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGClassFnStartOrCond(cond)  \
  do { if ((GSDebugSet(@"EOFFn") == YES) || (GSDebugSet(cond) == YES)) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugFunctionMsg(__PRETTY_FUNCTION__, __FILE__, __LINE__,@"FNSTART"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGClassFnStartOrCond2(cond1,cond2)  \
  do { if ((GSDebugSet(@"EOFFn") == YES) || (GSDebugSet(cond1) == YES) || (GSDebugSet(cond2) == YES)) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugFunctionMsg(__PRETTY_FUNCTION__, __FILE__, __LINE__,@"FNSTART"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGClassFnStop()  \
  do { if (GSDebugSet(@"EOFFn") == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugFunctionMsg(__PRETTY_FUNCTION__,__FILE__, __LINE__,@"FNSTOP"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGObjectFnStopCond(cond)  \
  do { if ((GSDebugSet(@"EOFFn") == YES) && GSDebugSet(cond) == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg(self, _cmd, __FILE__, __LINE__,@"FNSTOP"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGClassFnStopOrCond(cond)  \
  do { if ((GSDebugSet(@"EOFFn") == YES) || (GSDebugSet(cond) == YES)) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugFunctionMsg(__PRETTY_FUNCTION__,__FILE__, __LINE__,@"FNSTOP"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGClassFnStopOrCond2(cond1,cond2)  \
  do { if ((GSDebugSet(@"EOFFn") == YES) || (GSDebugSet(cond1) == YES) || (GSDebugSet(cond2) == YES)) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugFunctionMsg(__PRETTY_FUNCTION__,__FILE__, __LINE__,@"FNSTOP"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGClassLevel(level,format) \
  do { if (GSDebugSet(level) == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugFunctionMsg( \
        __PRETTY_FUNCTION__, __FILE__, __LINE__, format); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGClassLevelArgs(level, format, args...) \
  do { if (GSDebugSet(level) == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugFunctionMsg( \
        __PRETTY_FUNCTION__, __FILE__, __LINE__, format); \
    NSLog(fmt, ## args); [tmpPool release]; }} while (0)

#define EOFLOGClassFnNotImplemented() 	\
  do { if (GSDebugSet(@"EOFdflt") == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugFunctionMsg(__PRETTY_FUNCTION__, __FILE__, __LINE__,@"NOT IMPLEMENTED"); \
    NSLog(fmt); [tmpPool release]; }} while (0)



// call in Instance-Methods

#define EOFLOGObjectFnStart()  \
  do { if (GSDebugSet(@"EOFFn") == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg(self, _cmd, __FILE__, __LINE__,@"FNSTART"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGObjectFnStartOrCond(cond)  \
  do { if ((GSDebugSet(@"EOFFn") == YES) || (GSDebugSet(cond) == YES)) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg(self, _cmd, __FILE__, __LINE__,@"FNSTART"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGObjectFnStartOrCond2(cond1,cond2)  \
  do { if ((GSDebugSet(@"EOFFn") == YES) || (GSDebugSet(cond1) == YES) || (GSDebugSet(cond2) == YES)) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg(self, _cmd, __FILE__, __LINE__,@"FNSTART"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGObjectFnStop()  \
  do { if (GSDebugSet(@"EOFFn") == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg(self, _cmd, __FILE__, __LINE__,@"FNSTOP"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGObjectFnStopOrCond(cond)  \
  do { if ((GSDebugSet(@"EOFFn") == YES) || (GSDebugSet(cond) == YES)) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg(self, _cmd, __FILE__, __LINE__,@"FNSTOP"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGObjectFnStopOrCond2(cond1,cond2)  \
  do { if ((GSDebugSet(@"EOFFn") == YES) || (GSDebugSet(cond1) == YES) || (GSDebugSet(cond2) == YES)) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg(self, _cmd, __FILE__, __LINE__,@"FNSTOP"); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGObjectFnStopPlain(fmt)  \
  do { if (GSDebugSet(@"EOFFn") == YES) { \
    NSLog(fmt); }} while (0)

#define EOFLOGObjectFnStopOrCondPlain(cond,fmt)  \
  do { if ((GSDebugSet(@"EOFFn") == YES) || (GSDebugSet(cond) == YES)) { \
    NSLog(fmt); }} while (0)

#define EOFLOGObjectFnStopOrCond2Plain(cond1,cond2,fmt)  \
  do { if ((GSDebugSet(@"EOFFn") == YES) || (GSDebugSet(cond1) == YES) || (GSDebugSet(cond2) == YES)) { \
    NSLog(fmt); }} while (0)

#define EOFLOGObjectLevel(level,format) \
  do { if (GSDebugSet(level) == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg( \
        self, _cmd, __FILE__, __LINE__, format); \
    NSLog(fmt); [tmpPool release]; }} while (0)

#define EOFLOGObjectLevelArgs(level, format, args...) \
  do { if (GSDebugSet(level) == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg( \
        self, _cmd, __FILE__, __LINE__, format); \
    NSLog(fmt, ## args); [tmpPool release]; }} while (0)

#define EOFLOGObject(format) \
  do { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg( \
        self, _cmd, __FILE__, __LINE__, format); \
    NSLog(fmt); [tmpPool release]; } while (0)

#define EOFLOGObjectArgs(format, args...) \
  do { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg( \
        self, _cmd, __FILE__, __LINE__, format); \
    NSLog(fmt, ## args); [tmpPool release]; }while (0)

#define EOFLOGObjectFnNotImplemented()	  \
  do { if (GSDebugSet(@"EOFdflt") == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugMethodMsg(self, _cmd, __FILE__, __LINE__,@"NOT IMPLEMENTED"); \
    NSLog(fmt); [tmpPool release]; }} while (0)



// call everywhere

#define EOFLOGException(format) 	\
  do { if (GSDebugSet(@"exception") == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugFunctionMsg(__PRETTY_FUNCTION__, __FILE__, __LINE__,format); \
    NSString *fmt2 = [NSString stringWithFormat:@"*EXCEPTION*: %@",fmt]; \
    NSLog(@"%@",fmt2); [tmpPool release]; }} while (0)

#define EOFLOGExceptionArgs(format, args...) 	\
  do { if (GSDebugSet(@"exception") == YES) { \
    NSAutoreleasePool *tmpPool = [NSAutoreleasePool new]; \
    NSString *fmt = GSDebugFunctionMsg(__PRETTY_FUNCTION__, __FILE__, __LINE__,format); \
    NSString *fmt2 = [NSString stringWithFormat:@"*EXCEPTION*: %@",fmt]; \
    NSLog(fmt2, ## args); [tmpPool release]; }} while (0)

#else // no DEBUG

#define EOFLOGClassFnStart()  	{}
#define EOFLOGClassFnStartCond()  	{}
#define EOFLOGClassFnStartOrCond(cond)  	{}
#define EOFLOGClassFnStartOrCond2(cond1,cond2)  	{}
#define EOFLOGClassFnStop()	{}
#define EOFLOGClassFnStopCond()	{}
#define EOFLOGClassFnStopOrCond(cond)	{}
#define EOFLOGClassFnStopOrCond2(cond1,cond2)	{}
#define EOFLOGClassLevel(level,format) {}
#define EOFLOGClassLevelArgs(level,format,args...) {}
#define EOFLOGClassFnNotImplemented() 	{}

#define EOFLOGObjectFnStart()  	{}
#define EOFLOGObjectFnStartCond(cond) {}
#define EOFLOGObjectFnStartOrCond(cond)  	{}
#define EOFLOGObjectFnStartOrCond2(cond1,cond2)  	{}
#define EOFLOGObjectFnStop()	{}
#define EOFLOGObjectFnStopCond(cond) {} 
#define EOFLOGObjectFnStopOrCond(cond)	{}
#define EOFLOGObjectFnStopOrCond2(cond1,cond2)	{}
#define EOFLOGObjectFnStopPlain(fmt)	{}
#define EOFLOGObjectFnStopOrCondPlain(cond,fmt)	{}
#define EOFLOGObjectFnStopOrCond2Plain(cond1,cond2,fmt)	{}
#define EOFLOGObjectLevel(level,format) {}
#define EOFLOGObjectLevelArgs(level,format,args...) {}
#define EOFLOGObject(format) {}
#define EOFLOGObjectArgs(format,args...) {}
#define EOFLOGObjectFnNotImplemented()	  {}

#define EOFLOGException(format) 	{}
#define EOFLOGExceptionArgs(format, args...) 		{}

#endif

#ifndef NSEmitTODO
#define NSEmitTODO();	NSLog(@"DVLP WARNING %s (%d): TODO",(char*)__FILE__,(int)__LINE__);
#endif

#endif // _EODebug_h__
