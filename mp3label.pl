#!/usr/bin/perl -w
# $Id$

use strict;

package TrackData;

# TODO: need `new' method and settors

my $track_data_template =
  { DEFAULT => { artist  => undef,
                 album   => undef,
                 track   => undef,
                 total   => undef, # total number of tracks in album
                 song    => undef,
                 comment => undef,
                 year    => undef,
                 genre   => undef,
                 ext     => undef, # e.g. 'mp3'

                 # single-artist album
                 filename => '%artist - %album - %(02d)track - %song.%ext',

                 # For a multi-artist album
                 #filename => '%album - %(02d)track - %artist - %song.%ext',
               },
  };

sub field_value
{
  my ($self, $field, $track) = @_;
  my $data = $self->{data}->{$track};

  return $data->{$field} if defined $data && exists $data->{$field};
  return $self->{data}->{DEFAULT}->{$field};
}

sub artist  { my $s = shift; $s->field_value ('artist',  @_) }
sub album   { my $s = shift; $s->field_value ('album',   @_) }
sub song    { my $s = shift; $s->field_value ('song',    @_) }
sub comment { my $s = shift; $s->field_value ('comment', @_) }
sub year    { my $s = shift; $s->field_value ('year',    @_) }
sub genre   { my $s = shift; $s->field_value ('genre',   @_) }
sub total   { my $s = shift; $s->field_value ('total',   @_) }

# Track number is actually the field index anyway, but just in case the
# field data changes the value, return that changed value.
sub track
{
  my $self = shift;
  my $track = $self->field_value ('track', @_);
  return $track if defined $track;
  return $_[1];
}

# TODO: implement filename formatter and renaming functions


package Id3Labeler;

sub program_name { die "must define program name in subclass" }

sub program_global_args {} # none by default

# These are the fields we know about to try to set
sub program_fields { qw(artist album track song comment year genre) }

# Assume program's arg name is same as field name with long option prefix.
sub program_field_arg
{
  my ($self, $field) = @_;
  return "--" . $field;
}

sub label_track
{
  my ($self, $track_data, $track) = @_;

  my @program_args = $self->program_global_args;
  for my $field ($self->program_fields)
    {
      my $arg = $self->program_field_arg ($field);
      next unless defined $arg;

      my $data = $track_data->$field ($track);
      next unless defined $data;

      push @program_args, $arg, $data;
    }
  system ($self->program_name, @program_args);
}

sub label
{
  my ($self, $track_data) = @_;
  map { $self->label_track ($track_data, $_) } $track_data->track_number_list;
}

# TODO: implement timestamp preservation


package Id3Labeler::Id3Tag;

use vars qw(@ISA);
@ISA = qw(Id3Labeler);

use vars qw(%prog_field_arg);

sub program_name { "id3tag" }

sub program_field_arg
{
  my ($self, $field) = @_;

  # Map track data fields to id3tag command line arguments.  Presently this
  # mapping simply prepends `--' to known field names, but this is largely
  # coincidental and could change in the future.
  unless (defined %prog_field_arg)
    {
      %prog_field_arg = map { $_ => '--' . $_ }
        qw(artist album track song comment desc genre year);
    }

  return $prog_field_arg{$field};
}


package Id3Labeler::Mp3Info;

use vars qw(@ISA);
@ISA = qw(Id3Labeler);

sub program_name { "mp3info" }

sub program_field_arg
{
  my ($self, $field) = @_;

  return { artist  => '-a',
           album   => '-l',
           track   => undef,
           song    => '-t',
           comment => '-c',
           desc    => undef,
           genre   => '-g',
           year    => '-y',
         }->{$field};
}
