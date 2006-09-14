/** 
   Postgres95Compatibility.h

   Copyright (C) 2004,2005 Free Software Foundation, Inc.

   Adapted: David Ayers  <ayers@fsfe.org>
   Date: September 2004

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
   </license>
**/

#if !HAVE_DECL_PQFREEMEM
#define PQfreemem free
#endif

#if !HAVE_DECL_PQUNESCAPEBYTEA
#include <stdlib.h>
#include <string.h>

/*
 *  PQunescapeBytea - converts the null terminated string representation
 *  of a bytea, strtext, into binary, filling a buffer. It returns a
 *  pointer to the buffer which is NULL on error, and the size of the
 *  buffer in retbuflen. The pointer may subsequently be used as an
 *  argument to the function free(3). It is the reverse of PQescapeBytea.
 *
 *  The following transformations are reversed:
 *              '\0' == ASCII  0 == \000
 *              '\'' == ASCII 39 == \'
 *              '\\' == ASCII 92 == \\
 *
 *              States:
 *              0       normal          0->1->2->3->4
 *              1       \                          1->5
 *              2       \0                         1->6
 *              3       \00
 *              4       \000
 *              5       \'
 *              6       \\
 */

#define PSQL_ATTRIB_UNUSED __attribute__ ((unused))

static unsigned char *
PQunescapeBytea(unsigned char *strtext, size_t *retbuflen) PSQL_ATTRIB_UNUSED;

static unsigned char *
PQunescapeBytea(unsigned char *strtext, size_t *retbuflen)
{
  size_t         buflen;
  unsigned char *buffer, *sp,*bp;
  unsigned int state = 0;

  if (strtext == NULL)
    return NULL;
  buflen = strlen(strtext);       /* will shrink, also we discover if
				   * strtext */
  buffer = (unsigned char *) malloc(buflen);      /* isn't NULL terminated */
  if (buffer == NULL)
    return NULL;
  for (bp = buffer, sp = strtext; *sp != '\0'; bp++, sp++)
    {
      switch (state)
	{
	    case 0:
	      if (*sp == '\\')
		state = 1;
	      *bp = *sp;
	      break;
	    case 1:
	      if (*sp == '\'')        /* state=5 */
		{                               /* replace \' with 39 */
		  bp--;
		  *bp = '\'';
		  buflen--;
		  state = 0;
		}
	      else if (*sp == '\\')   /* state=6 */
		{                               /* replace \\ with 92 */
		  bp--;
		  *bp = '\\';
		  buflen--;
		  state = 0;
		}
	      else
		{
		  if (isdigit(*sp))
		    state = 2;
		  else
		    state = 0;
		  *bp = *sp;
		}
	      break;
	    case 2:
	      if (isdigit(*sp))
		state = 3;
	      else
		state = 0;
	      *bp = *sp;
	      break;
	    case 3:
	      if (isdigit(*sp))               /* state=4 */
		{
		  int v;

		  bp -= 3;
		  sscanf(sp - 2, "%03o", &v);
		  *bp = v;
		  buflen -= 3;
		  state = 0;
		}
	      else
		{
		  *bp = *sp;
		  state = 0;
		}
	      break;
	}
    }
  buffer = realloc(buffer, buflen);
  if (buffer == NULL)
    return NULL;

  *retbuflen = buflen;
  return buffer;
}
#endif

