#!/usr/bin/env perl
# mkpem --- generate rsa keys, self-signed certificates, and certificate requests

# Author: Noah Friedman <friedman@splode.com>
# Created: 2009-01-01
# Public domain

# $Id$

# Commentary:

# Example config.dn for an SSL server certificate:
#
#     C              = US
#     ST             = California
#     L              = San Francisco
#     O              = Nocturnal Aviation, Inc.
#     OU             = Shipping and Receiving
#     CN             = foo.bar.com
#
#     [ v3_ca ]
#     subjectAltName = @alt_names
#
#     [ alt_names ]
#     DNS.01         = cname.bar.com
#     DNS.02         = othercname.bar.com
#     IP.01          = 127.0.0.1
#     IP.02          = ::1
#     email.01       = foo@bar.com
#
# Order is least significant to most significant!
# Usually you want to list C first and CN last.
#
# The v3_ca and alt_names sections are optional.

# To import a web cert into a NSS database:
#
#	certutil -d [sql|dbm]:[/dir] -A -n [nickname] -t P -i [file.crt]
#
# Use -t CT,C,C for CA certificates.

# Code:

use strict;
use warnings qw(all);

use Scalar::Util qw(reftype);
use POSIX qw(strftime modf);
use Getopt::Long;
use Pod::Usage;

eval { require Time::HiRes };
my $have_hires = $@ ? 0 : 1;


use FindBin;
use lib "$FindBin::Bin/../lib/perl";
use lib "$ENV{HOME}/lib/perl";

use NF::FileUtil    qw(:all);
use NF::PrintObject qw(:all);

my $tmpdir = $ENV{TMPDIR} || "/tmp";
my $tmpfile = "$tmpdir/mkpem.$$";
END { unlink ($tmpfile) }

our %opt_default = ( asn1kludge => 0,
                     desc       => 1,
                     extensions => 1,
                     newkey     => 0,
                     task       => 'pem',
                   );
our %opt;

sub parse_options
{
  local *ARGV = \@{$_[0]}; # modify our local arglist, not real ARGV.
  my $help = -1;

  my $parser = Getopt::Long::Parser->new;
  $parser->configure (qw(bundling autoabbrev no_ignore_case));

  my $succ = $parser->getoptions
    ("h|help|usage+"     => \$help,

     "c|csr"             => sub { $opt{task} = 'csr' },
     "p|pem"             => sub { $opt{task} = 'pem' },

     "a|asn1-kludge!"    => \$opt{asn1kludge},
     "d|description!"    => \$opt{desc},
     "e|extensions!"     => \$opt{extensions},
     "n|newkey|new-key!" => \$opt{newkey},

     "v|verbose+"        => \$opt{verbose},
    );

  pod2usage (-exitstatus => 1, -verbose => 0) unless $succ;
  pod2usage (-exitstatus => 0, -verbose => $help) if $help >= 0;
}


sub read_file
{
  open (my $fh, $_[0]) || die "$_[0]: $!";
  local $/ = undef;
  scalar <$fh>;
}

sub write_file
{
  my $file = shift;

  my $old_umask = umask (077);
  open (my $fh, "> $file") || die "open rw: $file: $!\n";
  umask ($old_umask);

  print $fh @_;
  close ($fh);
  return 1;
}

sub bt # Like `foo` in bourne shell.
{
  local $SIG{__WARN__} = sub { 0 };
  open (my $fh, "-|", @_) || die "exec: $_[0]: $!\n";

  local $/ = undef;
  chomp (local $_ = <$fh>);
  return $_;
}

sub timestamp
{
  my $fmt = '%Y%m%d%H%M%S';
  return strftime ($fmt, localtime (time)) unless $have_hires;

  my $hi = &Time::HiRes::clock_gettime (&Time::HiRes::CLOCK_REALTIME);
  my ($nano, $sec) = modf ($hi);
  sprintf ("%s%09.9s",
           strftime ($fmt, localtime ($sec)),
           int ($nano * 1_000_000_000));
}

sub openssl
{
  my $cmd = $ENV{MKPEM_OPENSSL} || 'openssl';
  bt ($cmd, @_);
}

sub main
{
  parse_options (\@_);

  #unless (@_) { &usage() }

  my $config = shift;
  #fill_options_from_config();

  #my $t = timestamp;
  #printf "%s (%d)\n", $t, length($t);
}

main (@ARGV);

# eof
