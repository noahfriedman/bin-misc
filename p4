#!/bin/sh

# p4 wrapper --- search for p4 env variables
# Author: Noah Friedman <friedman@splode.com>
# Public domain.

# $Id: p4,v 1.9 2005/06/07 23:42:29 friedman Exp $

case ":${P4PORT+set}:${P4USER+set}:${P4CLIENT+set}:" in
  :set:set:set: ) : ;;
  * ) eval `{ p4-init-env -sh; } 2> /dev/null` ;;
esac

case "${P4CONFIG+set}" in
  set )
    # Allow .p4config file in the current or any parent directory to
    # override default parameters
    dir=`/bin/pwd`
    while [ "$dir" != "NULL" ]; do
      if [ -f "$dir/$P4CONFIG" ]; then
        . "$dir/$P4CONFIG"
        # Export all P4* variables
        export `set | sed -e '/^P4/!d' -e 's/=.*//'`
        break
      fi
      dir=`echo "$dir" | sed -e 's/^$/NULL/' -e 's/\/[^\/]*$//'`
    done
esac

# Make sure that symlinks are resolved; if this variable is exported, p4
# will use it.  But note that we don't attempt to export it here if it
# wasn't already exported.
#PWD=`/bin/pwd`

if { p4client -V; } > /dev/null 2>&1 ; then
  exec p4client "$@"
else
  exec run-next "$0" "$@"
fi

# eof
