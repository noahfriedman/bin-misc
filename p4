#!/bin/sh
# $Id: p4,v 1.3 2000/01/07 19:06:13 friedman Exp $

case ":${P4CONFIG+set}:${P4PORT+set}:${P4USER+set}:${P4CLIENT+set}:" in
  :set:* | ::set:set:set: ) : ;;
  * ) eval `p4-init-env -sh` ;;
esac

# Make sure that symlinks are resolved; if this variable is exported, p4
# will use it.  But note that we don't attempt to export it here if it
# wasn't already exported.
PWD=`/bin/pwd`

exec run-next $0 ${1+"$@"}
