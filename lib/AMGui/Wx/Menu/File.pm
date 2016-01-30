package AMGui::Wx::Menu::File;

use strict;
use warnings;

use Wx::Locale gettext => '_T';

our @ISA = 'Wx::Menu';

sub new {
    my $class = shift;
    my $main  = shift;
    
    my $self = $class->SUPER::new(@_);
    bless $self, $class;

    $self->Append(Wx::wxID_NEW,  _T("&New\tCtrl+N"), "");
    $self->Append(Wx::wxID_OPEN, _T("&Open\tCtrl+O"), "");
    $self->AppendSeparator();
    $self->Append(Wx::wxID_EXIT, _T("&Quit\tCtrl+Q"), "");

    return $self;
}

sub title {
    return _T("&File");
}

1;