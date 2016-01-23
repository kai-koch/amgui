package AMGui::Constant;
use base qw( Exporter );

#BEGIN { $Exporter::Verbose = 1 }

use strict;
use warnings;

#our @ISA = qw(Exporter);

our @EXPORT = qw(wxID_RUN SHILO);
#our @EXPORT_OK = qw( wxID_RUN SHILO );

use constant wxID_RUN => 1000; # also hardcoded in the base class generated by wxGlade
use constant SHILO => 999; # fake

use constant WIN32 => !!( ( $^O eq 'MSWin32' ) or ( $^O eq 'cygwin' ) );

#1;