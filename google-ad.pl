#!/bin/sh
exec ${PERL-perl} -Sx $0 ${1+"$@"}
#!perl

# Copyright (C) 2002 Frank Xavier Ledo

# $Id$

# Author: Frank Xavier Ledo <kermit@perkigoth.com>
# Maintainer: kermit@perkigoth.com
# Keywords: games
# Created: 2002-07-10

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, you can either send email to this
# program's maintainer or write to: The Free Software Foundation,
# Inc.; 59 Temple Place, Suite 330; Boston, MA 02111-1307, USA.

### Commentary:

# "In the future, advertisements will be everywhere"
# "What if irc channels had targeted advertisments?"

# This program will take search terms passed to it and do a Google search
# on those words and return a "sponsored link" ad (if any) at the top
# of the Google search results.

# This program was inspired by the shop.pl program written by
# Faried Nawaz <fn@hungry.org> which was a reimplementation of some great
# elisp written by Noah Friedman, which itself was a reimplementation of
# some C code written by Brian Rice in 1989.

### Code:

use strict;
use IO::Socket;

# Build a char->hex map
# See rfc1945 for a list of characters which must be escaped.
my %qpmap;
sub qpencode ($)
{
  local $_ = shift;

  map { $qpmap{chr $_} = sprintf ("%%%02X", $_) } (0 .. 255) unless %qpmap;
  s/([^\$()*,.\/0-9:A-Z_\`a-z~\-! ])/$qpmap{$1}/g;
  y/ /+/;
  return $_;
}

sub main ()
{
  exit 1 unless @ARGV;
  my $q = qpencode ("@ARGV");

  # build http request string
  my $server = "www.google.com";
  my $port = 80;
  my $get = join ("\n",
                  "GET /search?q=$q HTTP/1.1",
                  "Host: $server",
                  "User-Agent: Mozilla/5.0",
                  "Connection: close",
                  "", "");

  my $sock = IO::Socket::INET->new ( Proto    => "tcp",
                                     PeerAddr => $server,
                                     PeerPort => $port,
                                     Timeout  => 30);
  exit (1) unless $sock;

  $sock->autoflush (1);
  print $sock $get;

  while (<$sock>)
    {
      if (/Sponsored Link/)
        {
          # Try to get one of the left side ads by deleting everything up
          # to the start of the last one on the page
          s/^.*align=left/</;
          # else, just delete up to the start of the last ad on the page
          s/^.*td nowrap bgcolor=/</;

          s/<\/td>.*//;            # drop everything follwing this cell
          s/<[^>]*>/ /g;           # strip all html
          s/Interest://;           # strip Google interest markings
          s/Affiliate.//;          # strip Google affiliate markings
          s/&[^;]*;//g;            # strip &tags;
          s/  / /g;
          s/ \./\./g;
          s/\n//g;
          s/^\s+//;

          print $_, "\n" if $_;
          last;
        }
    }
  $sock->close;
  exit (0);
}

main ();

# local variables:
# mode: perl
# eval: (auto-fill-mode 1)
# end:
