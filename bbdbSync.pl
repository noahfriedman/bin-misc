#!/opt/lude/bin/perl

###############################################################################
# bbdbSync.pl                                                                 #
#                                                                             #
# This program is used to sync the database maintained by BBDB with the       #
# Address book database maintained on the Palm Pilot family of devices.       #
# WARNING !!! This is still a very rough version. Save your information b4    #
# using this program.                                                         #
#                                                                             #
# Features:                                                                   #
#   o Updates both databases (Address DB & BBDB) with information contained   #
#     only in either one or both. So entries only in the Address DB are added #
#     to BBDB on sync'ing and vice-versa.                                     #
#   o Merges common records assuming the information in Address DB is always  #
#     more up-to-date except for undefined fields.                            #
#   o Deletes records from the BBDB that have been deleted on the Address DB  #
#     (after the initial sync.)                                               #
#   o Handles archived records in Address DB.                                 #
#   o Can capture and store information in Notes and custom fields in the     #
#     address book.                                                           #
#   o Can correctly label the phone numbers with the label used in Address DB #
#   o Ability to not sync a category or sync only a category.                 #
#                                                                             #
# Constraints:                                                                #
#   o Tested on BBDB file version 2/3.                                        #
#   o Can't create new categories in BBDB if not defined in Palm already.     #
#   o Don't handle sortByCompany                                              #
#   o Don't handle '"' in address field. Use "'" instead.                     #
#   o US Tel numbers without area code can end up with an extra 0 at the end  #
#                                                                             #
# Usage:                                                                      #
#   -s <category> - Sync only category specified                              #
#   -d <category> - Default category to assign to entries in BBDB, but not in #
#                   Address DB.                                               #
#   -n <category> - Don't sync entries belonging to specified category.       #
#   -o <output file> - Name of output BBDB file (Default is ~/.bbdb.sync).    #
#   -f <input file> - Name of BBDB file to read from (Default is ~/.bbdb).    #
#   -v              - Verbose mode (display some processing information).     #
#                                                                             #
# Requirements:                                                               #
#    Perl 5 (tested with both 5.003 and 5.004)                                #
#    Perl module PDA::Pilot (available with pilot-link program).              #
#                                                                             #
# Credits:                                                                    #
#    Borrowed GetFields, MatchString & MatchParen routines from Seth Golub    #
#    <seth@cs.wustl.edu>.                                                     #
#    Borrowed and used the ideas in PilotManager program.                     #
#    http://www.moshpit.org/pilotmgr/                                         #
#                                                                             #
# Todo:                                                                       #
#   o Add support to not delete Palm/BBDB records                             #
#   o Add support to restore data into pilot from BBDB & vice-versa.          #
#                                                                             #
# Licensing Information:                                                      #
#                                                                             #
#  This program is free software; you can redistribute it and/or modify       #
#  it under the terms of the GNU General Public License as published by       #
#  the Free Software Foundation; either version 1, or (at your option)        #
#  any later version.                                                         #
#                                                                             #
#  This program is distributed in the hope that it will be useful,            #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#  GNU General Public License for more details.                               #
#                                                                             #
#  A copy of the GNU General Public License can be obtained from this         #
#  program's author (send electronic mail to the above address) or from       #
#  Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.    #
#                                                                             #
#  Author: Dinesh G Dutt (ddutt@cisco.com)                                    #
###############################################################################

use PDA::Pilot;
use Getopt::Std;
use Data::Dumper;

getopts ("vhf:gi:d:n:o:s:");
###############################################################################
# Initializing global variables
###############################################################################
my $Version = "1.3";
my $Debug = $opt_g || 0;
my $Verbose = $opt_v || $Debug;
my $BbdbFile   = $opt_f || $ENV{BBDB} || "$ENV{HOME}/.bbdb"; # database file
my $DefaultCategory = $opt_d || "Unfiled";
my $DontSyncCategory = $opt_n || "";
my $OnlySyncCategory = $opt_s if (defined ($opt_s));
my $OutputFile = $opt_o || "$ENV{HOME}/.bbdb.sync";
#$InstallToPalm = $opt_i if (defined ($opt_i));
my $DefaultPhoneLabelNo = 0;
my $BbdbFileVersion = 3;           # Assume BBDB's file version is 3 by default.
my $BbdbMasterFile = "$ENV{HOME}/.bbdbMaster";
my @PhoneLabels = ("work", "home", "fax", "other", "email", "main", "pager",
		"mobile", "nil");
my $PhoneInvLabels = {
                      'work'    => 0,
                      'home'    => 1,
                      'fax'     => 2,
                      'other'   => 3,
                      'email'   => 4,
                      'main'    => 5,
                      'pager'   => 6,
                      'mobile'  => 7
                     };
my $ShowPhoneUndef = 8;		# Undefined value
my $DefaultShowPhone = 0;

my @userFields = ("custom1", "custom2", "custom3", "custom4", "category",
                  "recordID", "showPhone", "work", "home", "fax", "other",
                  "main", "pager", "mobile", "creation-date", "timestamp");

###############################################################################
# MAIN routine starts
###############################################################################

if ($opt_h) {
    &Usage;
    exit (0);
}

if (defined ($OnlySyncCategory) && ($DontSyncCategory ne "")) {
    print "Cannot specify both -n and -s options\n";
    &Usage;
    exit (1);
}

print "Reading Master Database....." if ($Verbose);
$master_db = &ReadMaster($BbdbMasterFile);
print "Done\n" if ($Verbose);

print "Reading BBDB....." if ($Verbose);
&ReadBbdb();
print "Done\n" if ($Verbose);

# Connect with the Palm and open the relevant databases
($db, $dlp) = &OpenPilotDb ("AddressDB");
die "Unable to open AddressDB\n" if (!defined ($db) || !defined ($dlp));

if (defined ($InstallToPalm)) {
  $dlp->delete ("AddressDB");
}
else {
  print "Reading Address Book....." if ($Verbose);
  &ReadAb ($db, $dlp);
  print "Done\n" if ($Verbose);
}

print "Syncing only category $OnlySyncCategory....." if (defined ($OnlySyncCategory) && $Debug);
&SyncDb ();
print "Done\n" if ($Verbose);

# Write the Palm pilot first so that we can get the record Id for the records
# to store along with the record database.

print "Writing the Palm Address Book....." if ($Verbose);
&WriteAb ($db, $dlp);
print "Done\n" if ($Verbose);

$dlp->tickle;

print "Writing to BBDB File....." if ($Verbose);
&WriteBbdb ();
print "Done\n" if ($Verbose);

# Write the master file
print "Writing the Master Database....." if ($Verbose);
&WriteMaster ($master_db, $BbdbMasterFile);
print "Done\n" if ($Verbose);

&ClosePilotDb ($db, $dlp);

exit 0;

###############################################################################
# This routine connects with the Palm device and opens the AddressDB database
###############################################################################
sub OpenPilotDb {
    my ($db, $dlp);

    if ($ARGV[0]) {
        $port = $ARGV[0];
    } else {
        $port = "/dev/pilot";
    }

print "port=$port\n";
    $socket = PDA::Pilot::openPort ($port);
    print "Now press the HotSync button\n";

    $dlp = PDA::Pilot::accept($socket);

    $db = $dlp->open("AddressDB");

    return ($db, $dlp);
}

sub ClosePilotDb {
    my ($db, $dlp) = @_;

    undef $db;
    undef $dlp;
}

###############################################################################
# Reads the master database created at the time of last sync and returns it
###############################################################################
sub ReadMaster {
    my ($masterFile) = @_;
    return {} unless (-r $masterFile);

    use vars qw ($masterdb);
    do "$masterFile";
    return ($masterdb);
}

###############################################################################
# Adds to the database of records by reading the address book on the Pilot. It
# simulataneously updates matching records and marks deleted and archived
# records. It updates the BbdbData array.
###############################################################################
sub ReadAb {
    my ($db, $dlp) = @_;
    my ($isMatch, $alias, $key, $name, $email, $i, $recId, $mrecId);

    #    print "Labels are: ";
    #    foreach $label (@{$appblock->{"label"}}) {
    #	print $label;
    #    }
    #    print "\n";

    # Retrieve categories
    $app = $db->getAppBlock;
    $k = 0;
    foreach $cat  (@{$app->{categoryName}}) {
        $categoryList{$k} = $cat;
        $categoryInvList{$cat} = $k++;
    }

    $i = 0;
    $alias = "nil";
    %AddrDbData = ();

    if (defined ($InstallToPalm)) {
        return;
    }

  PALMRECORD:
    foreach $id ($db->getRecordIDs()) {

        undef @entry;
        undef @phoneLabel;
        undef $recId;
        $isMatch = 0;
        $email = "";
        $dlp->tickle;

        $r = $db->getRecordByID($id);
        last if ($dlp->getStatus() < 0);
        last if (!defined($r));

        @entry = @{$r->{"entry"}};
        @phoneLabel = @{$r->{'phoneLabel'}};
        $showPhone = $r->{'showPhone'};
        $showPhone = 0 if (!defined ($showPhone));
        $recId = $r->{'id'};

        foreach $i (0 .. 18) {
            $entry[$i] = "nil" if (!defined ($entry[$i]) ||
                                   ($entry[$i] eq ""));
            # Strip off newlines before storing
            $entry[$i] =~ s/\n/ /g;
            $entry[$i] =~ s/\r/ /g;
        }

        # Init phone entries. 8 is the index of "nil" in the @PhoneLabels array.
        foreach $i (0 .. 4) {
            if ($entry[$i+3] eq "nil") {$entry[$i+3] = "0"; }
        }

        $address = "nil";

        # Construct the address field in the format of BBDB
        if (($entry[8] ne "nil") && ($entry[9] ne "nil")) {
            if ($entry[10] ne "nil") {
                $address = "\"$entry[9], $entry[10]\" \"$entry[8]\" \"\" \"\" \"$entry[9]\" \"$entry[10]\"";
            }
            else {
                $address = "\"$entry[9]\" \"$entry[8]\" \"\" \"\" \"$entry[9]\" \"\"";
            }
            if ($entry[11] ne "nil") {
                $address .= " $entry[11]";
            }
        }

        # Construct the email field
        $email = "";
        foreach $i (0 .. 4) {
            if (($phoneLabel[$i] == 4) && ($entry[$i+3] ne "0")) {
                $temp = $entry[$i+3];
                $temp =~ s/, /" "/g;
                $email .= "\"".$temp."\" ";
            }
        }

        # Strip off ", " and the final '""' from the email field
        if ($email ne "") {
            $email =~ s/, /\" \"/g;
            $email =~ s/\"\" $//;
            print "ReadAb: The email address is $email for $entry[0]/$entry[2]\n" if ($Verbose);
        }

        $addrDbRec = {
                      LNAME            => $entry[0],
                      NAME             => $entry[1],
                      ALIAS            => $alias,
                      ORG              => $entry[2],
                      PHONE1           => $entry[3],
                      PHLABEL1         => $PhoneLabels[$phoneLabel[0]],
                      PHONE2           => $entry[4],
                      PHLABEL2         => $PhoneLabels[$phoneLabel[1]],
                      PHONE3           => $entry[5],
                      PHLABEL3         => $PhoneLabels[$phoneLabel[2]],
                      PHONE4           => $entry[6],
                      PHLABEL4         => $PhoneLabels[$phoneLabel[3]],
                      PHONE5           => $entry[7],
                      PHLABEL5         => $PhoneLabels[$phoneLabel[4]],
                      EMAIL            => $email,
                      ADDRESS          => $address,
                      STREET           => $entry[8], # Street address
                      CITY             => $entry[9],
                      STATE            => $entry[10],
                      ZIPCODE          => $entry[11],
                      COUNTRY          => $entry[12],
                      TITLE            => $entry[13],
                      CUSTOM1          => $entry[14],
                      CUSTOM2          => $entry[15],
                      CUSTOM3          => $entry[16],
                      CUSTOM4          => $entry[17],
                      NOTES            => $entry[18],
                      CATEGORY         => $categoryList{$r->{"category"}},
                      SHOWPHONE        => $showPhone,
                      PILOTID          => $recId,
                      INPILOT          => 1,
                      SECRET           => $r->{'secret'},
                      ARCHIVEDINAB     => 0,
                      DELETEDINAB      => $r->{'deleted'},
                      ISNEWINAB        => 0,
                      ISMODIFIEDINAB   => 0,
                      ARCHIVEDINBBDB   => $r->{'archived'},
                      DELETEDINBBDB    => 0,
                      ISNEWINBBDB      => 0,
                      ISMODIFIEDINBBDB => 0,
                      CREATIONDATE     => "nil",
                      TIMESTAMP        => "nil",
                     };

        # Add this record to the master database as well if it is not already
        # present
        $mrecId = &FindMatchingRecord ($master_db, $addrDbRec->{'LNAME'},
                                       $addrDbRec->{'NAME'}, $addrDbRec->{'ORG'},
                                       $addrDbRec->{'EMAIL'}, $recId);
        if ($mrecId == -1) {
            $addrDbRec->{ISNEWINAB} = 1;
            $$master_db{$recId} = $addrDbRec;
            print "ReadAb: New record $addrDbRec->{LNAME}/$addrDbRec->{ORG}\n";
        }
        else {
            if ($recId != $mrecId) {
                # Something has happened. Most likely the old record was deleted,
                # purged and a new one created before this sync was attempted.
                $$master_db{$mrecId}->{PILOTID} = $recId;
                print "Record with key $mrecId and lastname $$master_db{mrecId}->{LNAME} resurfaced with different key $recId\n" if ($Debug);
            }
            $$master_db{$mrecId}->{INPILOT} = 1;
            $$master_db{$mrecId}->{ARCHIVEDINBBDB} = $addrDbRec->{ARCHIVEDINBBDB};
            $$master_db{$mrecId}->{DELETEDINAB} = $addrDbRec->{DELETEDINAB};
            $$master_db{$mrecId}->{SECRET} = $addrDbRec->{SECRET};
        }

        $AddrDbData {$recId} = $addrDbRec;
    }
}

###############################################################################
# Builds the database of local records by reading the .bbdb file.
###############################################################################
sub ReadBbdb {
    my ($phoneNo, $ext, $customField, $category, $field);
    my ($lname, $name, $alias, $org, $phone, $address, $email, $notes);
    my ($street, $city, $zipcode, $state, $country, $deleted, $archived);
    my ($recId, $localId, $showphone, $creationDate, $timeStamp);
    my ($k, $line, $phField);
    my (@custom, @phones, @phoneLabel, @bbdb, @record, @fieldList);

    %BbdbData = ();

    # Open bbdb file or STDIN and build the database
    unless (open(BBDB, $BbdbFile)) {
        if (-f $BbdbMasterFile) {
            die "Unable to open BBDB file, but Master file exists. Aborting!!\n";
        }
        else {
            return;
        }
    }

    # Grab user field list
    while(<BBDB>) {
        last if !/^;;; /;
        last if /^;;; user-fields: \(.*\)/;
        if (/^;;; file-version: (.*)$/) {
            if (($1 ne "2") && ($1 ne "3")) {
                print "ERROR: Can currently only work with version 2 & 3 files\n";
                close BBDB;
                exit (1);
            }
            else {
                $BbdbFileVersion = $1;
            }
        }
    }

    @bbdb = <BBDB>;             # Read in the rest of the database
    @bbdb = grep(!/^;/, @bbdb); # Filter out the comments now;
    $localId = 1;

    for ($i=0; $i <= $#bbdb; $i++) {
        $recId = $localId++;
        $category = $DefaultCategory;

        foreach $k (0 .. 4) {
            $phones[$k] = "0";
            $phoneLabel[$k] = $k;
        }

        foreach $k (0 .. 3) {
            $custom[$k] = "nil";
        }

        $phField = 0;
        $deleted = 0;
        $archived = 0;
        $showphone = $ShowPhoneUndef;
        $creationDate = "nil";
        $timestamp = "nil";

        @record = &GetFields($bbdb[$i]);
        ($name, $lname, $alias, $org, $phone, $address, $email, $notes, undef)
          = @record;

        $name =~ s/\["*(.*)"*/$1/g;
        $name =~ s/\"//g;

        $lname =~ s/\"//g;

        # Extract telephone number in xxx-xxx-xxxxX<extension> format
        if ($phone ne "nil") {
            ($phoneNo, $ext) = &GetNumberFromPhoneFieldBbdb ($phone);
            if (!defined ($phoneNo)) {
                $phones[0] = "0";
                $ext = "0";
            }
            else {
                $phones[$phField] = $phoneNo;
                $phoneLabel = $DefaultPhoneLabelNo;

                if (defined ($ext) && ($ext != 0)) {
                  $phones[$phField] = $phoneNo."-".$ext;
                  $phoneLabel[$phField] = $DefaultPhoneLabelNo;
                }
                $phField++;
            }
        }
        else {
            $phones[0] = "0";
            $phField++;
        }

        # BBDB's address stores everything from street address to zipcode in
        # one string. Split it up for merging with Palm Pilot's format
        if ($address ne "nil") {
            ($street, $city, $state, $zipcode) = GetAddressFieldsBbdb ($address);
            $street = "nil" if (!defined ($street));
            $city = "nil" if (!defined ($city));
            $state = "nil" if (!defined ($state));
            $zipcode = "0" if (!defined ($zipcode));

            # Strip the leading & trailing "["
            $address =~ s/^\[//;
            $address =~ s/\]$//;
        }
        else {
            $street = $state = $city = "nil";
            $zipcode = "0";
        }

        # The Notes field can consist of not just not notes, but also names
        # and values for user-defined fields. Extract these.

        if ($notes ne "nil") {
            $userNotes = &GetNotesBbdb ($notes);
            $userNotes = "nil" if (!defined ($userNotes));

            # Extract user-configured fields
            if ($notes =~ m/^\(/) {
                foreach $userFieldKey (@userFields) {
                    $customField = &GetCustomFieldBbdb ($notes, $userFieldKey);
                    next if (!defined ($customField));

                    if ($userFieldKey eq "category") {
                        $category = $customField;
                    }
                    elsif ((($userFieldKey eq "home") ||
                            ($userFieldKey eq "fax") ||
                            ($userFieldKey eq "pager") ||
                            ($userFieldKey eq "main") ||
                            ($userFieldKey eq "other") ||
                            ($userFieldKey eq "mobile")) &&
                           (defined ($customField))) {
                        ($phoneNo, $ext) =
                          &GetNumberFromPhoneFieldBbdb ($customField);

                        $phField = &GetPhoneLabelIdx ($PhoneInvLabels->{$userFieldKey},
                                                      \@phones, \@phoneLabel);
                        if ($phField == -1) {
                            print "Too many phones specified. Skipping record $name/$lname/$org\n";
                            next;
                        }

                        if (!defined ($phoneNo)) {
                            $phones[$phField] = $customField;
                            $phones[$phField] =~ s/\"//g;
                        }
                        else {
                            $phones[$phField] = $phoneNo;
                            if (defined ($ext) && ($ext != 0)) {
                                $phones[$phField] = $phoneNo."-".$ext;
                            }
                        }
                        $phoneLabel[$phField] = $PhoneInvLabels->{$userFieldKey};
                    }
                    elsif (($userFieldKey eq "showphone") &&
                           (defined ($customField))) {
                        $showphone = $customField;
                    }
                    elsif (($userFieldKey eq "custom1") &&
                           (defined ($customField))) {
                        $custom[0] = $customField;
                    }
                    elsif (($userFieldKey eq "custom2") &&
                           (defined ($customField))) {
                        $custom[1] = $customField;
                    }
                    elsif (($userFieldKey eq "custom3") &&
                           (defined ($customField))) {
                        $custom[2] = $customField;
                    }
                    elsif (($userFieldKey eq "custom4") &&
                           (defined ($customField))) {
                        $custom[3] = $customField;
                    }
                    elsif (($userFieldKey eq "recordID") &&
                           (defined ($customField))) {
                        $recId = $customField;
                    }
                    elsif (($userFieldKey eq "creation-date") &&
                           (defined ($customField))) {
                        $creationDate = $customField;
                    }
                    elsif (($userFieldKey eq "timestamp") &&
                           (defined ($customField))) {
                        $timestamp = $customField;
                    }
                }
            }
        }
        else {
            $userNotes = "nil";
            $category = $DefaultCategory;
        }

        if ($showphone == $ShowPhoneUndef) {
            $showphone = $PhoneInvLabels->{email};
        }

        $bbdbRecord = {
                       LNAME            => $lname,
                       NAME             => $name,
                       ALIAS            => $alias,
                       ORG              => $org,
                       PHONE1           => $phones[0],
                       PHLABEL1         => $PhoneLabels[$phoneLabel[0]],
                       PHONE2           => $phones[1],
                       PHLABEL2         => $PhoneLabels[$phoneLabel[1]],
                       PHONE3           => $phones[2],
                       PHLABEL3         => $PhoneLabels[$phoneLabel[2]],
                       PHONE4           => $phones[3],
                       PHLABEL4         => $PhoneLabels[$phoneLabel[3]],
                       PHONE5           => $phones[4],
                       PHLABEL5         => $PhoneLabels[$phoneLabel[4]],
                       EMAIL            => $email,
                       ADDRESS          => $address,
                       STREET           => $street, #  extracted from $address
                       CITY             => $city, #  extracted from $address
                       STATE            => $state, #  extracted from $address
                       ZIPCODE          => $zipcode, #  extracted from $address
                       COUNTRY          => "nil",
                       TITLE            => "nil",
                       CUSTOM1          => $custom[0],
                       CUSTOM2          => $custom[1],
                       CUSTOM3          => $custom[2],
                       CUSTOM4          => $custom[3],
                       NOTES            => $userNotes,
                       CATEGORY         => $category,
                       SHOWPHONE        => $showphone,
                       PILOTID          => $recId,
                       INPILOT          => 0,
                       SECRET           => 0,
                       ARCHIVEDINAB     => 0,
                       DELETEDINAB      => 0,
                       ISNEWINAB        => 0,
                       ISMODIFIEDINAB   => 0,
                       ARCHIVEDINBBDB   => $archived,
                       DELETEDINBBDB    => $deleted,
                       ISNEWINBBDB      => 0,
                       ISMODIFIEDINBBDB => 0,
                       CREATIONDATE     => $creationDate,
                       TIMESTAMP        => $timestamp,
                      };

        # Add this record to the master database as well if it is not already
        # present
        if (&FindMatchingRecord ($master_db, $bbdbRecord->{'LNAME'},
                                 $bbdbRecord->{'NAME'}, $bbdbRecord->{'ORG'},
                                 $bbdbRecord->{'EMAIL'}, $recId) == -1) {
            $bbdbRecord->{ISNEWINBBDB} = 1;
            $$master_db{$recId} = $bbdbRecord;
        }
        else {
            $$master_db{$recId}->{CREATIONDATE} = $bbdbRecord->{CREATIONDATE};
            $$master_db{$recId}->{TIMESTAMP} = $bbdbRecord->{TIMESTAMP};
        }

        $BbdbData {$recId} = $bbdbRecord;
    }

    close (BBDB);
}

###############################################################################
# Uses the read pilot and BBDB database with the master database to decide how
# to treat each record finally i.e. a) either update just the Palm b) update
# just the BBDB c) update both Palm and BBDB d) delete Palm record e) delete
# BBDB record f) delete both Palm and BBDB records.  The master database at the
# end of this session contains all valid records (non-deleted records)
###############################################################################
sub SyncDb {

    my ($key, $precId, $brecId);

    if (defined $InstallToPalm) {
        return;
    }

    # Iterate through all records in master database and compare with Palm and BBDB
    # state
    foreach $key (keys %$master_db) {
        # Find matching record in BBDB. If ISNEWINAB is set, then there will be
        # no matching record in BBDB and this was new to the master database as
        # well. So, nothing is to be done. Just write the record to the databases.
        if ($$master_db{$key}->{ISNEWINAB} == 1) {
            if (!$$master_db{$key}->{DELETEDINAB}) {
                $$master_db{$key}->{ISNEWINAB} = 0; # Turn off the bit so the master_db
                # is not written with this bit.
                next;
            }
            else {
                $db->deleteRecord ($key);
                delete $$master_db{$key};
                next;
            }
        }

        $brecId = &FindMatchingRecord (\%BbdbData, $$master_db{$key}->{LNAME},
                                       $$master_db{$key}->{NAME},
                                       $$master_db{$key}->{ORG},
                                       $$master_db{$key}->{EMAIL},
                                       $$master_db{$key}->{PILOTID});

        $precId = &FindMatchingRecord (\%AddrDbData, $$master_db{$key}->{LNAME},
                                       $$master_db{$key}->{NAME},
                                       $$master_db{$key}->{ORG},
                                       $$master_db{$key}->{EMAIL},
                                       $$master_db{$key}->{PILOTID});

        # Sync the Category field first. Use this as the basis for proceeding or not.
        if ($brecId != -1) {
            if (($$master_db{$key}->{CATEGORY} eq $BbdbData{$brecId}->{CATEGORY}) &&
                !$$master_db{$key}->{ISNEWINBBDB}) {
                if (($precId != -1) &&
                    ($$master_db{$key}->{CATEGORY} ne $AddrDbData{$precId}->{CATEGORY})) {
                    # Only the pilot record has been changed.
                    $$master_db{$key}->{CATEGORY} = $AddrDbData{$precId}->{CATEGORY};
                    $$master_db{$key}->{ISMODIFIEDINAB} = 1; # Write updated rec into BBDB
                    print "Only Pilot changed for CATEGORY for record $key \n" if ($Debug);
                }
            }
            elsif ($precId != -1) {
                if ($$master_db{$key}->{CATEGORY} eq $AddrDbData{$precId}->{CATEGORY}) {
                    # Only the BBDB has changed
                    $$master_db{$key}->{CATEGORY} = $BbdbData{$brecId}->{CATEGORY};
                    $$master_db{$key}->{ISMODIFIEDINBBDB} = 1;
                    print "Only BBDB changed for CATEGORY for record $key \n" if ($Debug);
                }
                else {
                    # Both Pilot & BBDB have changed. Pilot takes precedence
                    $$master_db{$key}->{CATEGORY} = $AddrDbData{$precId}->{CATEGORY};
                    $$master_db{$key}->{ISMODIFIEDINAB} = 1; # Write updated rec into BBDB
                    print "Both Pilot & BBDB changed for CATEGORY, using Pilot's value for record $key \n"
                      if ($Debug);
                }
            }
        }
        elsif ($precId != -1) {
            if ($$master_db{$key}->{ARCHIVEDINBBDB} == 1) {
                # This record has been deleted from the Pilot database, but marked for archive
                $$master_db{$key}->{DELETEDINAB} = 1;
                $precId = -1;
            }
            else {
                $$master_db{$key}->{CATEGORY} = $AddrDbData{$precId}->{CATEGORY};
                $$master_db{$key}->{ISMODIFIEDINAB} = 1; # Write updated rec into BBDB
            }
        }

        next if ($$master_db{$key}->{CATEGORY} eq $DontSyncCategory);
        next if (defined ($OnlySyncCategory) &&
                 ($OnlySyncCategory ne $$master_db{$key}->{CATEGORY}));

        if (($brecId == -1) || ($precId == -1)) {
            if (($precId == -1) && ($brecId == -1)) {
                # Record has been deleted on both the Pilot and in the BBDB. Just
                # remove the master record and move on to the next record in master_db.
                print "Removing record for key $key with lastname $$master_db{$key}->{LNAME} from master database (#1)\n";
                delete $$master_db{$key};
                next;
            }

            # We take the stand that if the record is deleted on either the Pilot or
            # in BBDB, the record is deleted in both places unless either the
            # archived bit is set in the Pilot or the delete-on-sync bit is set in
            # the BBDB. In either case, the delete is not sync'd to the other side.
            if ($brecId == -1) {
                if ($$master_db{$key}->{ARCHIVEDINAB} != 1) {
                    # If no matching record in BBDB and bit in master record does not
                    # list this as a record to be archived in the Pilot, delete the
                    # record from the Pilot and remove record from master db as well.
                    $db->deleteRecord ($precId);
                    print "Removing record for key $key with lastname $$master_db{$key}->{LNAME} from Pilot & master database\n(#2)";
                    delete $$master_db{$key};
                }
            }
            elsif ($precId == -1) {
                # Don't assume that precId == -1 means the record was deleted on the
                # Pilot. It could be because this is a new record in BBDB.
                if ($$master_db{$key}->{ISNEWINBBDB} != 1) {
                    if ($$master_db{$key}->{ARCHIVEDINBBDB} != 1) {
                        # If no matching record found in Pilot and master database does not
                        # list this as an archived entry, remove it from master database.
                        print "Removing record for key $key with lastname $$master_db{$key}->{LNAME} from master database(#3)\n";
                        delete $$master_db{$key};
                    }
                }
            }
        }

        # If this record is marked for delete on sync, do not attempt to merge the
        # data from BBBD.
        if ($BbdbData{$brecId}->{DELETEDINBBDB}) {
            $brecId = -1;
            if (!$BbdbData{$brecId}->{ARCHIVEDINAB}) {
                if ($precId != -1) {
                    print "Removing record for key $key with lastname $$master_db{$key}->{LNAME} from Pilot & master database(#4)\n";
                    $db->deleteRecord ($precId);
                    delete $$master_db{$key};
                    next;
                }
            }
            else {
                $$master_db{$key}->{ARCHIVEDINAB} = 1;
                $$master_db{$key}->{DELETEDINBBDB} = 0;
            }
        }

        # If this record is marked for delete & not archived, do not attempt to
        # merge the data from AddressDB. Else, if set for delete and archived,
        # merge the data before deleting the record.
        if ($AddrDbData{$precId}->{DELETEDINAB}) {
            print "Removing record for key $key with lastname $$master_db{$key}->{LNAME} from Pilot & master database(#5)\n";
            $db->deleteRecord ($precId);
            if (!$AddrDbData{$precId}->{ARCHIVEDINAB}) {
                delete $$master_db{$key};
                next;
            }
            else {
                $$master_db{$key}->{ARCHIVEDINBBDB} = 1;
                $$master_db{$key}->{DELETEDINAB} = 0;
            }
        }

        # When merging, we take the stand that the Pilot database takes precedence
        # over the BBDB database except for the Email where BBDB takes precedence
        # over the Pilot database.
        &MergeRecord ($$master_db{$key},
                      ($brecId != -1) ? $BbdbData{$brecId} : undef,
                      ($precId != -1) ? $AddrDbData{$precId} : undef
                     );
    }
}

###############################################################################
# This routine merges the records provided. The merged record is written into
# the first argument which is assumed to belong to the master database.
###############################################################################
sub MergeRecord {
    my ($masterRec, $bbdbRec, $addrDbRec, $fieldName) = @_;

    foreach $fieldName ("LNAME", "NAME", "ORG", "PHONE1",
                        "PHONE2", "PHONE3", "PHONE4", "PHONE5", "EMAIL",
                        "PHLABEL1", "PHLABEL2", "PHLABEL3", "PHLABEL4", "PHLABEL5",
                        "STREET", "CITY", "STATE", "ZIPCODE",
                        "COUNTRY", "TITLE", "CUSTOM1", "CUSTOM2",
                        "CUSTOM3", "CUSTOM4", "NOTES") {
        if (defined ($bbdbRec)) {
            if (($masterRec->{$fieldName} eq $bbdbRec->{$fieldName})) {
                #          !$masterRec->{ISNEWINBBDB}) {
                if (defined ($addrDbRec) &&
                    ($masterRec->{$fieldName} ne $addrDbRec->{$fieldName})) {
                    # Only the pilot record has been changed.
                    $masterRec->{$fieldName} = $addrDbRec->{$fieldName};
                    $masterRec->{ISMODIFIEDINAB} = 1; # Write updated rec into BBDB
                    print "Only Pilot changed for field $fieldName \n" if ($Debug);
                }
            }
            elsif (defined ($addrDbRec)) {
                if ($masterRec->{$fieldName} eq $addrDbRec->{$fieldName}) {
                    # Only the BBDB record has been changed.
                    $masterRec->{$fieldName} = $bbdbRec->{$fieldName};
                    $masterRec->{ISMODIFIEDINBBDB} = 1; # Write updated rec into Pilot
                    print "Only BBDB changed for field $fieldName \n" if ($Debug);
                }
                else {
                    # Both BBDB & Pilot have changed and Pilot takes precedence except
                    # for EMAIL. If the new field is nil in either of the records, that
                    # is overruled
                    if (($fieldName eq "EMAIL") || ($addrDbRec->{$fieldName} eq "nil") ||
                        ($addrDbRec->{$fieldName} eq "0")) {
                        $masterRec->{$fieldName} = $bbdbRec->{$fieldName};
                        $masterRec->{ISMODIFIEDINBBDB} = 1; # Write updated rec into Pilot
                    }
                    else {
                        # Both BBDB & Pilot are different.
                        $masterRec->{$fieldName} = $addrDbRec->{$fieldName};
                        $masterRec->{ISMODIFIEDINAB} = 1; # Write updated rec into BBDB
                    }
                }
            }
        }
        else {
            # No record in BBDB. Use the Address book value.
            $masterRec->{$fieldName} = $addrDbRec->{$fieldName};
            $masterRec->{ISMODIFIEDINAB} = 1; # Write updated rec into BBDB
        }
    }

    # Merge showphone & secret from Pilot unless record is not defined in the Pilot.
    $masterRec->{SHOWPHONE} = $addrDbRec->{SHOWPHONE}   if (defined ($addrDbRec));
    $masterRec->{SECRET} = $addrDbRec->{SECRET} if (defined ($addrDbRec));
}

###############################################################################
# Updates the .bbdb file with the sync'd up data. Archived records have the
# category archive and deleted records are not copied to the new file.
###############################################################################
sub WriteBbdb {
  my ($firstBrace, $notes, $address, $k, $fieldName, $labelName);

  if ($InstallToPalm) {
    return;
  }

  open (BBDBW, ">$OutputFile") ||
    die "Could not open BBDB output file \"$OutputFile\" for updating";

  print BBDBW ";;; file-version: $BbdbFileVersion\n";
  print BBDBW ";;; user-fields: (";
  foreach $field (sort @userFields) {
    print BBDBW "$field ";
  }
  print BBDBW ")\n";

  # Sort entries by last name, organization or email
  foreach $key (sort SortBbdb keys %$master_db) {
    $firstBrace = 0;

    next if ($$master_db{$key}->{ARCHIVEDINAB});
    next if (defined ($DontSyncCategory) && ($$master_db{$key}->{CATEGORY} eq $DontSyncCategory));
    next if (defined ($OnlySyncCategory) &&
             ($OnlySyncCategory ne $$master_db{$key}->{CATEGORY}));

    print BBDBW "[";

    BbdbPrintField ($$master_db{$key}->{NAME}, "\"", "\" ");
    BbdbPrintField ($$master_db{$key}->{LNAME}, "\"", "\" ");
    BbdbPrintField ($$master_db{$key}->{ALIAS}, "(", ") ");
    BbdbPrintField ($$master_db{$key}->{ORG}, "\"", "\" ");

    if ($$master_db{$key}->{PHONE1} ne "0") {
      ($areacode, $no1, $no2, $ext) =
        split (/[-x]/, $$master_db{$key}->{PHONE1});
      $ext = 0 if (!defined ($ext));
      $areacode = 0 if (!defined ($areacode));
      $no1 = 0 if (!defined ($no1));
      $no2 = 0 if (!defined ($no2));

      print BBDBW "([";
      if ($$master_db{$key}->{CITY} ne "nil") {
        BbdbPrintField ("\"$$master_db{$key}->{CITY}\" ", "", "");
      }
      else {
        BbdbPrintField (" ", "\"", "\" ");
      }
      BbdbPrintField ($areacode." ".$no1." ".$no2." ".$ext, "", "]) ");
    }
    else {
      BbdbPrintField ("nil", "", " ");
    }

    $address = $$master_db{$key}->{ADDRESS};

    BbdbPrintField ($address, "([", "]) ");
    BbdbPrintField ($$master_db{$key}->{EMAIL}, '(', ') ');

    # BBDB cannot handle newlines in the notes field. Replace newlines with
    # spaces.
    if ($$master_db{$key}->{NOTES} ne "nil") {
      $notes = $$master_db{$key}->{NOTES};
      $notes =~ s/\n/ /g;
      BbdbPrintField ("\"$notes\"",
                      "((notes . ", ")");
      $firstBrace = 1;
    }

    # Remaining fields are user-defined fields
    foreach $k (2 .. 5) {
      $fieldName = "PHONE".$k;
      $labelName = "PHLABEL".$k;
      if (($$master_db{$key}->{$labelName} ne "email") &&
          ($$master_db{$key}->{$labelName} ne "nil") &&
          ($$master_db{$key}->{$fieldName} ne "0") &&
          ($$master_db{$key}->{$fieldName} ne "nil")) {
        print "Fieldname is $fieldName, labelName is $labelName\n" if ($Debug);
        if ($$master_db{$key}->{$fieldName} =~ m/^\d+/) {
          ($areacode, $no1, $no2, $ext) =
            split (/[-x]/, $$master_db{$key}->{$fieldName});
          $ext = 0 if (!defined ($ext));
          $areacode = 0 if (!defined ($areacode));
          $no1 = 0 if (!defined ($no1));
          $no2 = 0 if (!defined ($no2));
          $value = $areacode." ".$no1." ".$no2." ".$ext;
        }
        else {
          $value = $$master_db{$key}->{$fieldName};
        }
        if ($firstBrace) {
          BbdbPrintField ($value,
                          " ($$master_db{$key}->{$labelName} . \"", "\") ");
        }
        else {
          BbdbPrintField ($value,
                          " (($$master_db{$key}->{$labelName} . \"", "\") ");
          $firstBrace = 1;
        }
      }
    }

    # Add the Custom fields
    foreach $k (1 .. 4) {
      $fieldName = "CUSTOM".$k;
      $labelName = "custom".$k;

      if ($$master_db{$key}->{$fieldName} ne "nil") {
        if ($firstBrace) {
          BbdbPrintField ($$master_db{$key}->{$fieldName},
                          " ($labelName . \"", "\") ");
        }
        else {
          BbdbPrintField ($$master_db{$key}->{$fieldName},
                          " (($labelName . \"", "\")");
          $firstBrace = 1;
        }
      }
    }

    # Add the category as a user-defined field
    if (defined ($$master_db{$key}->{CATEGORY}) &&
        ($$master_db{$key}->{CATEGORY} ne "nil")) {
      if ($firstBrace) {
        BbdbPrintField ($$master_db{$key}->{CATEGORY},
                        " (category . \"", "\") ");
      }
      else {
        BbdbPrintField ($$master_db{$key}->{CATEGORY},
                        " ((category . \"", "\")");
        $firstBrace = 1;
      }
    }

    # Add the record ID as a user-defined field
    if ($firstBrace) {
      BbdbPrintField ($$master_db{$key}->{PILOTID},
                      " (recordID . \"", "\") ");
    }
    else {
      BbdbPrintField ($$master_db{$key}->{PILOTID},
                      " ((recordID . \"", "\")");
      $firstBrace = 1;
    }

    # Add the showphone field
    if ($firstBrace) {
      BbdbPrintField ($$master_db{$key}->{SHOWPHONE},
                      " (showphone . \"", "\") ");
    }
    else {
      BbdbPrintField ($$master_db{$key}->{SHOWPHONE},
                      " ((showphone . \"", "\")");
      $firstBrace = 1;
    }

    # Add the creation-date and timestamp fields
    if ($$master_db{$key}->{CREATIONDATE} ne "nil") {
        if ($firstBrace) {
            BbdbPrintField ($$master_db{$key}->{CREATIONDATE},
                            " (creation-date . \"", "\") ");
        }
        else {
            BbdbPrintField ($$master_db{$key}->{CREATIONDATE},
                            " ((creation-date . \"", "\")");
            $firstBrace = 1;
        }
    }

    if ($$master_db{$key}->{TIMESTAMP} ne "nil") {
        if ($firstBrace) {
            BbdbPrintField ($$master_db{$key}->{TIMESTAMP},
                            " (timestamp . \"", "\") ");
        }
        else {
            BbdbPrintField ($$master_db{$key}->{TIMESTAMP},
                            " ((timestamp . \"", "\")");
            $firstBrace = 1;
        }
    }

    if ($firstBrace) {
      print BBDBW ") ";
    }
    else {
      # nil Notes field and so print nil.
      print BBDBW "nil ";
    }

    print BBDBW "nil]\n";

    # Turn off the new flag bit for this entry.
    $$master_db{$key}->{ISNEWINBBDB} = 0;
  }
}

sub BbdbPrintField {
    my ($field, $prefix, $suffix) = @_;

    if (!defined ($field) || $field eq "nil") {
	print BBDBW "nil ";
    }
    else {
	print BBDBW $prefix, $field, $suffix;
    }
}

###############################################################################
# Updates the address book database on the PalmPilot
###############################################################################

sub WriteAb {
  my (@entry, @phoneLabel, $r, $key);
  my ($db, $dlp) = @_;

  foreach $key (sort SortBbdb keys %$master_db) {
    @entry = ();
    @phoneLabel = ();
    $recId = 0;

    next if ($$master_db{$key}->{CATEGORY} eq $DontSyncCategory);
    next if (defined ($OnlySyncCategory) &&
             ($OnlySyncCategory ne $$master_db{$key}->{CATEGORY}));

    if (!defined ($InstallToPalm)) {
      next if ($$master_db{$key}->{ARCHIVEDINBBDB});
      if (($$master_db{$key}->{ISMODIFIEDINBBDB} != 1) &&
          ($$master_db{$key}->{ISNEWINBBDB} != 1)) {
          next;
      }
    }

    $$master_db{$key}->{ISMODIFIEDINBBDB} = 0;
    $r = $db->newRecord();

    if ($$master_db{$key}->{INPILOT} == 1) {
      $r->{'id'} = $$master_db{$key}->{PILOTID};
    }

    $r->{'id'} ||= 0;

    $recId = &WriteSingleRecAb ($r, $key);

    if ($key != $recId) {
      # The records are indexed by the Pilot record. So, if we're adding a new
      # Pilot record, we obtain the recordId after writing the record to the
      # Pilot and use this as the new key and delete the record with the old key.
      $$master_db{$key}->{PILOTID} = $recId;
      $$master_db{$recId} = $$master_db{$key};
      $$master_db{$recId}->{INPILOT} = 1;
      delete $$master_db{$key};
    }

    # Turn off the INPILOT field before storing the master database
    $$master_db{$key}->{INPILOT} = 0;
  }
}

###############################################################################
# Writes a single record to the address book database. Uses the BbdbData array
# to extract the fields.
# Inputs : record to be written (PalmPilot record)
#        : key of the record to be written in BbdbData array
# Assumes that $db is the database handle to which the record is written to.
###############################################################################
sub WriteSingleRecAb {
    my ($r, $key) = @_;
    my ($k, $emailSet, $emailField, $email, $fieldName, $labelName, $label);

    $k = 0;
    foreach $fieldName ("LNAME", "NAME", "ORG", "PHONE1",
                        "PHONE2", "PHONE3", "PHONE4", "PHONE5",
                        "STREET", "CITY", "STATE", "ZIPCODE",
                        "COUNTRY", "TITLE", "CUSTOM1", "CUSTOM2",
                        "CUSTOM3", "CUSTOM4", "NOTES") {
        if (($$master_db{$key}->{$fieldName} ne "nil") &&
            ($$master_db{$key}->{$fieldName} ne "0") ) {
            $entry[$k++] = $$master_db{$key}->{$fieldName};
            if ($fieldName eq "ZIPCODE") {
                # Strip off the quotes from the Zipcode field
                $entry[$k-1] =~ s/\"//g;
            }
        }
        else {
            $entry[$k++] = "";
        }
    }

    $email = $$master_db{$key}->{EMAIL};
    $email =~ s/\"//g;
    $email =~ s/ /, /g;

    # Determine where the email field needs to go
    $emailSet = 0;
    $emailField = 0;
    if ($email ne "") {
        print "WriteSingleRecAb: Email is $email for record $$master_db{$key}->{LNAME}/$$master_db{$key}->{ORG}\n" if ($Verbose);
        foreach $k (1 .. 5) {
            $labelName = "PHLABEL".$k;
            if ($$master_db{$key}->{$labelName} eq "email") {
                if (!$emailSet) {
                    $entry[$k+2] = $email;
                    $emailSet = 1;
                    $emailField = $k;
                    print "Found existing email field $k for email $email\n" if ($Debug);
                    last;
                }
                else {
                    $entry[$k+2] = "";
                    $$master_db{$key}->{$labelName} = "nil";
                }
            }
            else {
                $fieldName = "PHONE".$k;
                if ($$master_db{$key}->{$fieldName} eq "0") {
                    $emailField = $k;
                }
            }
        }

        # Email is not one of the defined fields in the Pilot. Add email to the
        # picked one.
        if (!$emailSet && emailField) {
            $entry[$emailField+2] = $email;
            $labelName = "PHLABEL".$emailField;
            print "Using new field $emailField as email field for email $email\n" if ($Debug);
        }
    }

    @{$r->{'entry'}} = @entry;

    $r->{"category"} = $categoryInvList{$$master_db{$key}->{CATEGORY}};

    # Build Phone Labels
    $k = 0;
    foreach $label ("PHLABEL1", "PHLABEL2", "PHLABEL3", "PHLABEL4",
                    "PHLABEL5") {
        if ($$master_db {$key}->{$label} ne "nil") {
            $phoneLabel[$k] =
              $PhoneInvLabels->{$$master_db{$key}->{$label}};
        }
        ++$k;
    }

    if ($emailField != 0) {
        $phoneLabel[$emailField] = $PhoneInvLabels->{email};
    }

    @{$r->{'phoneLabel'}} = @phoneLabel;
    $r->{'archived'} = 0;
    $r->{'deleted'} = 0;
    $r->{'secret'} = $$master_db{$key}->{SECRET};
    $r->{'showPhone'} = $$master_db{$key}->{SHOWPHONE};

    print "Updating record for $key on Palm\n" if ($Debug);
    $recId = $db->setRecord ($r);
    $recId;
}

sub WriteMaster {
    my ($masterdb, $masterFile) = @_;

    $Data::Dumper::Purity = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Indent = 0;

    unless (open (MASTERFILE, ">$masterFile")) {
        print "Unable to write to $masterFile  Help!\n";
        return;
    }

    print MASTERFILE Data::Dumper->Dumpxs ([$masterdb], ['$masterdb']), "1;\n";
    close (MASTERFILE);
}

###############################################################################
# Sorting function for the records. The sequence is :
#     if lastname, sort by lastname
#     elsif organization, sort by organization
#     else sort by email (even if nil)
# The PalmPilot and BBDB both follow this order.
###############################################################################
sub SortBbdb {
    $$master_db{$a}->{LNAME} cmp $$master_db{$b}->{LNAME};
}

sub FindMatchingRecord {
  my ($match, $id);
  my ($dbh, $lname, $name, $org, $email, $recId) = @_;

  $match = -1;

  if (defined $$dbh{$recId}) {
      $match = $recId;
  }

  if ($match == -1) {
      foreach $id (keys %$dbh) {
          if ($$dbh{$id}->{LNAME} ne "nil") {
              if (($$dbh{$id}->{NAME} eq $name) &&
                  ($$dbh{$id}->{LNAME} eq $lname)) {
                  $match = $id;
                  last;
              }
          }
          elsif (($$dbh{$id}->{ORG} ne "nil") &&
                 ($$dbh{$id}->{ORG} eq $org)) {
              $match = $id;
              last;
          }
          elsif (($$dbh{$id}->{EMAIL} ne "") &&
                 ($$dbh{$id}->{EMAIL} eq $email)) {
              $match = $id;
              last;
          }
      }
  }

  return ($match);
}

sub GetFields {
    my ($i) = 0;
    my (@field);
    my ($j) = 0;


    $j = 0;
    while ($j < length($_[0])) {
        if (substr($_[0], $j, 1) eq '"') { # ;"
            ($j, $field[$i++]) = &MatchString($_[0], $j);
        }
        elsif (substr($_[0], $j, 1) eq '(') {
            ($j, $field[$i++]) = &MatchParent($_[0], $j);
        }
        elsif (substr($_[0], $j, 1) ne ' ') {
            ($j, $field[$i++]) = &MatchWord($_[0], $j);
        }
        else {
            $j ++;
        }
    }
    return @field;
}

sub MatchString {
  my ($i) = $_[1];

  $i++;
  for (; $i < length($_[0]); $i++) {
    if (substr($_[0], $i, 1) eq '"') { # ;"
      $i++;
      return ($i, substr($_[0], $_[1]+1, $i - $_[1] - 2));
    }
  }

  return ($i, substr($_[0], $_[1]+1));
}

sub MatchWord {
  my ($i) = $_[1];
  my ($startQuote) = 0;

  for (; $i < length($_[0]); $i++) {
    if (substr($_[0], $i, 1) eq ' ' && !$startQuote) {
      return ($i, substr($_[0], $_[1], $i - $_[1]));
    }
    elsif (substr($_[0], $i, 1) eq '"') {
      $startQuote = !$startQuote;
    }
  }
  return ($i, substr($_[0], $_[1]));
}

sub MatchParent {
  my ($i) = $_[1];
  my ($skip) ;
  $stack = 1;
  $i++;

  for (; $i < length($_[0]); $i++) {
    if (substr($_[0], $i, 1) eq '"') { # ;"
      ($i, $skip) = &MatchString($_[0], $i);
      $i --;
    }
    elsif (index("([", substr($_[0], $i, 1)) >= 0) {
      $stack++;
    }
    elsif (index("])", substr($_[0], $i, 1)) >= 0) {
      $stack--;
      if ($stack == 0) {
        $i++;
        return ($i, substr($_[0], $_[1]+1, $i - $_[1] - 2));
      }
    }
  }

  return ($i, substr($_[0], $_[1]+1));
}

###############################################################################
# The BBDB representation of phone is not the way we like it to be. Convert it
# into the format xxx-xxx-xxxx add in case of an extension, add the trailing
# x<extension #>.
###############################################################################
sub GetNumberFromPhoneFieldBbdb {
  my ($phoneNo, $extension);

  ($phoneNo, $extension) =
    ($_[0] =~ m/[^0-9]*(\d+ \d+ \d+) (\d+).*$/);

  if (!defined ($phoneNo)) {
    # The phone was not in a North American number format.
    ($phoneNo) = ($_[0] =~ m/[^0-9]*([0-9 -]+).*$/);
  }
  # BBDB converts numbers such as 0400 to 400. Fix this - TBD
  if (defined ($phoneNo)) {
    $phoneNo =~ s/ /-/g;
  }

  return ($phoneNo, $extension);
}

###############################################################################
# The BBDB address is stored with the street address, city, state and zipcode
# all clumped together. Split them apart into a format similar to the way the
# PalmPilot stores it.
###############################################################################
sub GetAddressFieldsBbdb {
  my ($address) = @_;
  my ($streetAddr, $st1, $st2, $st3, $city, $state, $zipcode, $zip);

  #    BBDB's address format is as follows:
  #    ["location" "street addr 1" "street addr 2" "street addr 3" "city" "state"
  #     zipcode]
  #    Our regexp below assumes that there are no " within the individual fields

  ($st1, $st2, $st3, $city, $state, $zip) = ($address =~ m/\[\"[^"]*\" \"([^"]*)\" \"([^"]*)\" \"([^"]*)\" \"([^"]*)\" \"([^"]*)\" (\d+)/);


    $st1 = "" if (!defined ($st1));
    $st2 = "" if (!defined ($st2));
    $st3 = "" if (!defined ($st3));
    $streetAddr = $st1." ".$st2." ".$st3;
    $zipcode = "\"$zip\"";
    return ($streetAddr, $city, $state, $zipcode);
}

###############################################################################
# The BBDB field extraction routine clumps the notes field and the user-defined
# fields under a single variable. This routine xtracts just the notes part
# from this variable.
###############################################################################
sub GetNotesBbdb {
  my ($notes) = @_;
  my ($justNotes);

  if ($notes =~ m/^\(/) {
    if ($notes =~ m/^\(notes . /) {
      (undef, $justNotes) = &MatchParent ($_[0], 0);
      if (!defined ($justNotes)) {
        $justNotes = "nil";
      }
    }
    else {
      $justNotes = "nil";
    }
  }
  else {
    $justNotes = $notes;
  }
  $justNotes =~ s/^\"//;
  $justNotes =~ s/\"$//;
  $justNotes =~ s/^notes . "//;
    return $justNotes;
}

###############################################################################
# This routine extracts the value for a specified custom field from the generic
# notes variable created by the BBDB field extraction routine.
###############################################################################
sub GetCustomFieldBbdb {
  my ($notes, $fieldName) = @_;
  my ($customField);

  if ($notes =~ m/^\(/) {
    ($customField) = ($notes =~ m/\($fieldName . "([^)]*)"\)/);
  }
  return (defined ($customField) ? $customField : undef);
}

sub GetPhoneLabelIdx {
    my ($phoneLabelIdx, $phones, $phoneLabels) = @_;
    my ($k, $labelSet, $labelIdx);

    $labelIdx = -1;
    $labelSet = -1;

    foreach $k (0..4) {
        if ($phoneLabels->[$k] == $phoneLabelIdx) {
            $labelSet = 1;
            $labelIdx = $k;
            last;
        }
        elsif ($phones->[$k] eq "0") {
            $labelIdx = $k;
        }
    }

    return ($labelIdx);
}

sub Usage {
  print "  Usage: bbdbSync [-f <Input BBDB file>] [-o <output BBDB file>] [-i(nstall BBDB onto Palm)]\n";
  print "                  [-d <default category name>] [-n <don't sync category>] [-s <sync category>]\n\n";
  print "  Default Input BBDB file = ~/.bbdb\n";
  print "  Default Category Name = Unfiled\n";
  print "  Default Don't Sync Category =\n";
  print "  Default Only Sync Category =\n";
  print "  Default Output BBDB file = ~/.bbdb.sync\n\n";
  print "  bbdbSync[$Version] is a program used to sync the Address Book on the\n";
  print "  PalmPilot with the BBDB database used with (X)Emacs.\n";
}
