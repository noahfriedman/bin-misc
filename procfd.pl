#!/usr/bin/perl

use strict;
use warnings qw(all);

use lib "$ENV{HOME}/lib/perl";
use NF::FileUtil qw(:all);
use NF::PrintObject qw(:all);

sub main
{
  my $log_unix = file_contents( '/proc/net/unix' );
  my @lines_unix = split( /[\r\n]+/, $log_unix );

  my %inode2path = map { my @field = split( /\s+/, $_, 8 );
                         defined $field[7] ? ($field[6] => $field[7]) : ()
                       } @lines_unix;

  print_object('inode2path', \%inode2path);

}

main( @ARGV );
