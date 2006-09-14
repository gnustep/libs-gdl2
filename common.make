ifeq ($(FOUNDATION_LIB), apple)
  ADDITIONAL_LIB_DIRS += $(foreach libdir,$(ADDITIONAL_NATIVE_LIB_DIRS),-F$(libdir))
else
  ADDITIONAL_LIB_DIRS += $(foreach libdir,$(ADDITIONAL_NATIVE_LIB_DIRS),-L$(libdir)/$(GNUSTEP_OBJ_DIR))
endif

