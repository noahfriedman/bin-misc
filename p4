#!/bin/sh
# $Id$

case ":${P4PORT+set}:${P4USER+set}:${P4CLIENT+set}:" in
  *:set:* ) : ;;
  * ) eval `p4-init-env -sh` ;;
esac

exec run-next $0 ${1+"$@"}
