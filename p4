#!/bin/sh
# $Id: p4,v 1.1 1999/12/23 17:25:11 friedman Exp $

case ":${P4CONFIG}:${P4PORT+set}:${P4USER+set}:${P4CLIENT+set}:" in
  *:set:* ) : ;;
  * ) eval `p4-init-env -sh` ;;
esac

exec run-next $0 ${1+"$@"}
