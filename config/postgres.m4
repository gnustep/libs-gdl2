dnl AM_PATH_PGSQL([, ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND]])
AC_DEFUN(AM_PATH_PGSQL,[
  AC_ARG_WITH(pgsql-include,
    [  --with-pgsql-include=PATH  include path for postgres headers],
    pgsql_incdir="$withval", pgsql_incdir=)

  AC_ARG_WITH(pgsql-library,
    [  --with-pgsql-library=PATH  library path for pgsql libraries],
    pgsql_libdir="$withval", pgsql_libdir=)

  cppflags_temp="$CPPFLAGS"
  libs_temp=$LIBS

  AC_CHECK_PROG(PG_CONFIG, pg_config, yes, no)

  if test $PG_CONFIG = "yes" ; then
    if test -z "$pgsql_incdir" ; then
      pgsql_incdir=`pg_config --includedir`
    fi
    if test -z "$pgsql_libdir" ; then
      pgsql_libdir=`pg_config --libdir`
    fi
  fi

  CPPFLAGS="-I$pgsql_incdir $CPPFLAGS"
  LIBS="-L$pgsql_libdir $LIBS"

  POSTGRES_DATABASE="no"

  AC_CHECK_HEADERS(libpq-fe.h)
  if test $ac_cv_header_libpq_fe_h = yes; then
    AC_CHECK_LIB(pq, main, pgsql_ok=yes, pgsql_ok=no)

    if test "$pgsql_ok" = yes; then
      POSTGRES_INCLUDES="$CPPFLAGS"
      POSTGRES_LIB_DIRS="$LIBS"
      POSTGRES_LIBS="-lpq"
      POSTGRES_DATABASE="yes"
    fi
  fi

  AC_MSG_CHECKING(for PostgreSQL database)
  if test $POSTGRES_DATABASE = yes; then
    AC_MSG_RESULT(yes)
    ifelse([$1], , :, [$1])
  else
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

