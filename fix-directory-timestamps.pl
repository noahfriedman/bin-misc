#!/usr/bin/env perl

my @ignore      = (qw( CVS RCS {arch} .svn _MTN .git .hg ));
my @ignore_meta = (qw( MD5SUM SHA1SUM SHA256SUM TRANS.TBL fonts.dir fonts.scale ));

sub grind_over_tree
{
  my ($dir, $fn, $fn_on_dirs) = @_;
  my $result = 1;

  return &$fn ($dir) unless (-d $dir);

  # fn_on_dirs can be a simple boolean or it can be a separate function, in
  # which case the procedure is called as a "pre-" hook.  This can be used
  # e.g. to make sure the directory permissions are changed so the
  # directory is readable/traversible before descending into it.
  # Even if this is a code ref, $fn will be called on this entry too.
  if ($fn_on_dirs && ref $fn_on_dirs eq 'CODE')
    {
      $result = 0 unless &$fn_on_dirs ($dir, $fn, $fn_on_dirs);
    }

  my $dfh = xopendir ($dir);
  if ($dfh)
    {
      my @files = sort grep (!/^\.\.?$/o, readdir ($dfh));
      closedir ($dfh);

      for my $ent (@files)
        {
          my $file = join ("/", $dir, $ent);
          $result = 0 unless grind_over_tree ($file, $fn, $fn_on_dirs);
        }
    }
  else
    {
      $result = 0;
    }

  if ($fn_on_dirs)
    {
      $result = 0 unless &$fn ($dir);
    }

  return $result;
}

sub xopendir
{
  my $dir = shift;

  my $dfh = gensym;
  opendir ($dfh, $dir) || return _error ("opendir", $dir, "$!");
  return $dfh;
}

sub xstat
{
  my ($file, $noerrp, $deref_symlinks) = @_;

  my @statinfo = lstat ($file);
  if (@statinfo)
    {
      return @statinfo if wantarray;
      return \@statinfo;
    }
  return if $noerrp; # should be void
  _error ("stat", (ref $file ? fileno ($file) : $file), $!);
}

sub set_mtime
{
  my ($file, $statinfo) = @_;
  utime ($statinfo->[8], $statinfo->[9], $file);
}
