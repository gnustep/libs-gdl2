dnl AM_PATH_PGSQL([, ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND]])
AC_DEFUN(AM_PATH_PGSQL,[
AC_ARG_WITH(pgsql-include,
  [  --with-pgsql-include=PATH  include path for postgres headers],
  pgsql_incdir="$withval", pgsql_incdir="no")

AC_ARG_WITH(pgsql-library,
  [  --with-pgsql-library=PATH  library path for pgsql libraries],
  pgsql_libdir="$withval", pgsql_libdir="no")

  cppflags_temp="$CPPFLAGS"
  libs_temp=$LIBS

  CPPFLAGS="$CPPFLAGS -I/usr/local/include -I/usr/local/pgsql/include"
  LIBS="$LIBS -L/usr/local/lib -L/usr/local/pgsql/lib"

  if test "$pgsql_incdir" != "no"; then
    CPPFLAGS="$CPPFLAGS -I$pgsql_incdir"
  fi
  if test "$pgsql_libdir" != "no"; then
    LIBS="$LIBS -L$pgsql_libdir"
  fi

  POSTGRES_DATABASE="no"

  AC_MSG_CHECKING(for PostgreSQL database)

  AC_CHECK_HEADERS(libpq-fe.h)
  if test $ac_cv_header_libpq_fe_h = yes; then
    AC_CHECK_LIB(pq, main, pgsql_ok=yes, pgsql_ok=no)

    if test "$pgsql_ok" = yes; then
      POSTGRES_INCLUDES="$CPPFLAGS"
      POSTGRES_LIB_DIRS="$LIBS"
      POSTGRES_LIBS="-lpq"
      POSTGRES_DATABASE="yes"

      AC_MSG_RESULT(yes)
      ifelse([$1], , :, [$1])
    fi
  fi

  if test $POSTGRES_DATABASE = no; then
    AC_MSG_RESULT(no)
    ifelse([$2], , :, [$2])
  fi

  CPPFLAGS="$cppflags_temp"
  LIBS="$libs_temp"

  AC_SUBST(POSTGRES_DATABASE)
  AC_SUBST(POSTGRES_INCLUDES)
  AC_SUBST(POSTGRES_LIB_DIRS)
  AC_SUBST(POSTGRES_LIBS)
])

