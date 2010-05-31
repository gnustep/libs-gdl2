
/*
 EntityStoredProcedureInspector.h
 
 Author: David Wetzel <dave@turbocat.de>
 Date: 2010
 
 This file is part of EOModelEditor.
 
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
 */

#include <EOModeler/EOMInspector.h>

#include <AppKit/AppKit.h>

@class EOEntity;

@interface EntityStoredProcedureInspector : EOMInspector
{
  IBOutlet NSTextField          *_insertField;
  IBOutlet NSTextField          *_deleteField;
  IBOutlet NSTextField          *_fetchAllField;
  IBOutlet NSTextField          *_fetchWithPKField;
  IBOutlet NSTextField          *_pkGetField;
  EOEntity                      *_currentEntity;
}

@end

