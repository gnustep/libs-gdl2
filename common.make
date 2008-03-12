
GDL2_AGSDOC_FLAGS = \
	-WordMap '{ \
	RCS_ID = "//"; \
	GDL2CONTROL_EXPORT = extern; \
	GDL2ACCESS_EXPORT = extern; \
	GDL2INTERFACE_EXPORT = extern; \
	}'

ifeq ($(gcov),yes)
TEST_CFLAGS +=-ftest-coverage -fprofile-arcs
TEST_LDFLAGS +=-ftest-coverage -fprofile-arcs -lgcov
TEST_COVERAGE_LIBS+=-lgcov
endif

