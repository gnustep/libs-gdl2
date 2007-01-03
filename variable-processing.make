#
# Heres a way to compile/link against a framework/library before the library is
# installed.
#
# It depends upon the source layout of GDL2 where the directories are the same
# name as the framework name, for the -F flag to work.
#
# this is only comparable to the -L flags of a normal library, -I flags
# for this are redundant so just use typical ADDITONAL_INCLUDE_DIRS.
#

ifeq ($(FOUNDATION_LIB), apple)
  ADDITIONAL_LIB_DIRS += $(foreach libdir,$(ADDITIONAL_NATIVE_LIB_DIRS),-F$(libdir))
else
  ADDITIONAL_LIB_DIRS += $(foreach libdir,$(ADDITIONAL_NATIVE_LIB_DIRS),-L$(libdir)/$(GNUSTEP_OBJ_DIR))
endif
