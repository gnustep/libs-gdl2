dnl AM_PATH_SQLITE3([, ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND]])
AC_DEFUN(AM_PATH_SQLITE3,[
  AC_ARG_WITH(sqlite3-include,
    [  --with-sqlite3-include=-I{PATH}  include path for sqlite3 headers],
    sqlite3_incdir="$withval", sqlite3_incdir=)

  AC_ARG_WITH(sqlite3-library,
    [  --with-sqlite3-library=-L{PATH}  library path for sqlite3 libraries],
    sqlite3_libdir="$withval", sqlite3_libdir=)

  cppflags_temp="$CPPFLAGS"
  libs_temp=$LIBS

  AC_CHECK_PROG(PKGCONFIG, pkg-config, yes, no)

  if test $PKGCONFIG = "yes" ; then
    if test -z "$sqlite3_incdir" ; then
      sqlite3_incdir=`pkg-config sqlite3 --cflags`
    fi
    if test -z "$sqlite3_libdir" ; then
      sqlite3_libdir=`pkg-config sqlite3 --libs-only-L`
    fi
  fi

  CPPFLAGS="$sqlite3_incdir $CPPFLAGS"
  LIBS="$sqlite3_libdir $LIBS"

  SQLITE3_DATABASE="no"

  AC_CHECK_HEADERS(sqlite3.h)
  if test $ac_cv_header_sqlite3_h = yes; then
    AC_CHECK_LIB(sqlite3, main, sqlite3_ok=yes, sqlite3_ok=no)

    if test "$sqlite3_ok" = yes; then
      SQLITE3_INCLUDES="$CPPFLAGS"
      SQLITE3_LIB_DIRS="$LIBS"
      SQLITE3_LIBS="-lsqlite3"
      SQLITE3_DATABASE="yes"
    fi
  fi

  AC_MSG_CHECKING(for SQLite3 database)
  if test $SQLITE3_DATABASE = yes; then
    AC_MSG_RESULT(yes)
    ifelse([$1], , :, [$1])
  else
    AC_MSG_RESULT(no)
    ifelse([$2], , :, [$2])
  fi

  CPPFLAGS="$cppflags_temp"
  LIBS="$libs_temp"

  AC_SUBST(SQLITE3_DATABASE)
  AC_SUBST(SQLITE3_INCLUDES)
  AC_SUBST(SQLITE3_LIB_DIRS)
  AC_SUBST(SQLITE3_LIBS)
])

