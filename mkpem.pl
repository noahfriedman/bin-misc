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

(my $progname = $0) =~ s=.*//==;

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


sub _fatal
{
  if (@_ && $_[0] =~ /%/)
    {
      my $fmt = shift;
      my $s = sprintf ($fmt, @_);
      @_ = ($s);
    }
  print STDERR join(": ", $progname, @_), "\n";
  exit (1);
}

sub xopen
{
  return $fh
    if open (my $fh, $_[0], @_[1 .. $#_]); # filename arg must be expicit
  return _fatal ("open", $_[0], $!);
}

sub read_file
{
  my $fh = xopen ($_[0]);
  local $/ = undef;
  scalar <$fh>;
}

sub write_file
{
  my $file = shift;

  my $old_umask = umask (077);
  my $fh = xopen (">", $file);
  umask ($old_umask);

  print $fh @_;
  return $fh;
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
           strftime ($fmt, gmtime ($sec)),
           int ($nano * 1_000_000_000));
}

sub openssl
{
  my $cmd = $ENV{MKPEM_OPENSSL} || 'openssl';
  bt ($cmd, @_);
}

sub mkpem
{
  my ($config, $base) = (shift, shift);

  my $pem  = "$base.pem";
  my $crt  = "$base.crt";
  my $key  = "$base.key";

  my $sn   = $ENV{MKPEM_SERIAL} || timestamp();
  my $yrs  = $ENV{MKPEM_YEARS} || 10;
  my $days = 365 * yrs;

  #backup_and_set_keyopts "$key" "$crt" "$pem"
  #write_config;
  # This cannot be specified for CSRs, so add it here:
  #echo "[ v3_ca ]"
  #echo "authorityKeyIdentifier = keyid:always, issuer:always"
  openssl(qw(req -config     /dev/stdin
                 -batch
                 -x509
                 "${keyopts[@]}"
                 -set_serial $sn
                 -days       $days
                 -out        "$crt"),
                 @_));

    if [ -f "$crt" ]; then
        if [ ${opt[desc]} != f ]; then
            {   echo
                $openssl x509 -in "$crt" -noout -text \
                         -nameopt RFC2253
                         -certopt ext_parse
            } >> "$crt"
        fi
        cat "$key" "$crt" > "$pem"
    else
        return 1
    fi
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

__DATA__

[ req ]
RANDFILE                = /dev/urandom
prompt                  = no

if [ ${opt[extensions]} != f ]; then
    echo x509_extensions     = v3_ca
    echo req_extensions      = v3_ca
fi

distinguished_name      = req_dn
default_bits            = ${MKPEM_KEYSIZE:-4096}
default_md              = sha256
utf8                    = yes
string_mask             = utf8only


[ v3_ca ]
subjectKeyIdentifier   = hash

# Critical means cert should be rejected when used for purposes other
# than those indicated in this extension.
#
# Settings for CA cert
#basicConstraints       = critical, CA:true, pathlen:0
#keyUsage               = critical, digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement, keyCertSign, cRLSign, encipherOnly, decipherOnly
#extendedKeyUsage       = critical, serverAuth, clientAuth, codeSigning, emailProtection, timeStamping, msSGC, nsSGC

# Settings for basic self-signed web server cert
basicConstraints        = CA:false
keyUsage                = digitalSignature, keyEncipherment, keyCertSign
extendedKeyUsage        = serverAuth

# Don't use nsCertType; deprecated.
#nsCertType             = critical, sslCA, emailCA, client, server, email, objsign
#nsCertType             = critical, server

[ req_dn ]

while read l; do
    # Do not include any [mkpem_options] section because later versions
    # of openssl do not allow non-assignment lines.
    case $l in
        *\[*mkpem_options*\]* )
            while read l; do case $l in *\[*\]* ) break ;; esac; done ;;
    esac
    echo "$l"
done < "$1"

# eof
