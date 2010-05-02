
/*
    AttributesInspector.h
 
    Author: Matt Rice <ratmice@gmail.com>
    Date: 2005, 2006

    This file is part of DBModeler.

    DBModeler is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    DBModeler is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with DBModeler; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/ 

#include <EOAccess/EOAttribute.h>
#include <EOModeler/EOMInspector.h>

#ifdef NeXT_GUI_LIBRARY
#include <AppKit/AppKit.h>
#else
#include <AppKit/NSBox.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSNibDeclarations.h>
#endif

#ifdef NeXT_Foundation_LIBRARY
#include <Foundation/Foundation.h>
#else
#include <Foundation/NSDictionary.h>
#endif


@interface AttributeInspector : EOMInspector
{
  IBOutlet NSTextField          *_extNameField;
  IBOutlet NSTextField          *_extTypeField;
  IBOutlet NSPopUpButton        *_derivedPopUp; // or column
  IBOutlet NSPopUpButton        *_valueClassSelect;
  IBOutlet NSPopUpButton        *_valueTypePopUp; // int, float, ...
  IBOutlet NSPopUpButton        *_flipSelect;// select which valueClassName/flip
  IBOutlet NSBox                *_flipView; // gets replaced with a *Flip...
  IBOutlet NSBox                *_internalData;
  IBOutlet NSBox                *_numberFlip;   // to edit number properties
  IBOutlet NSTextField          *_nameField;  
  IBOutlet NSBox                *_customFlip; // default
  IBOutlet NSBox                *_dataFlip;
  IBOutlet NSBox                *_dateFlip;
  IBOutlet NSBox                *_decimalFlip;
  IBOutlet NSBox                *_stringFlip;

  IBOutlet NSTextField          *_custom_width;
  IBOutlet NSTextField          *_custom_class;
  IBOutlet NSTextField          *_custom_factory;
  IBOutlet NSTextField          *_custom_conversion;
  IBOutlet NSPopUpButton        *_custom_arg;

  IBOutlet NSTextField          *_string_width;
  
  IBOutlet NSTextField          *_decimal_precision;
  IBOutlet NSTextField          *_decimal_scale;

  IBOutlet NSTextField          *_data_width;

  IBOutlet NSButton             *_date_tz;

  NSDictionary                  *_flipDict;
  NSDictionary                  *_classTitleDict;
  NSDictionary                  *_valueTypeDict;
  
}
/* generic */
- (IBAction) selectInternalDataType:(id)sender;
- (IBAction) setName:(id)sender;
- (IBAction) setExternalName:(id)sender;
- (IBAction) setExternalType:(id)sender;

/* dependent on value class name */
- (IBAction) setWidth:(id)sender;
- (IBAction) setPrecision:(id)sender;
- (IBAction) setClassName:(id)sender;
- (IBAction) setFactoryMethod:(id)sender;
- (IBAction) setConversionMethod:(id)sender;
- (IBAction) setValueType:(id)sender;
- (IBAction) setTimeZone:(id)sender;
@end

