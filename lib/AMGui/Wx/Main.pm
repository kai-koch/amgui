package AMGui::Wx::Main;

use strict;
use warnings;

use Cwd ();
use File::Slurp;
use File::Spec;

use Wx qw[:everything];
use Wx::Locale gettext => '_T';

use AMGui::AM;
use AMGui::Constant;
use AMGui::DataSet;

use AMGui::Wx::AuiManager;
use AMGui::Wx::DatasetViewer;
use AMGui::Wx::ResultViewer;
use AMGui::Wx::Menubar;
use AMGui::Wx::Notebook;
use AMGui::Wx::StatusBar;

our @ISA = 'Wx::Frame';

use Class::XSAccessor {
    getters => {
        notebook  => 'notebook',
        menubar   => 'menubar',
        statusbar => 'statusbar',
        cwd       => 'cwd',
        aui       => 'aui'
    },
};

sub new {
    my ($class, $parent, $id, $title, $pos, $size, $style, $name) = @_;
    $parent = undef              unless defined $parent;
    $id     = -1                 unless defined $id;
    $title  = ""                 unless defined $title;
    $pos    = wxDefaultPosition  unless defined $pos;
    $size   = wxDefaultSize      unless defined $size;
    $name   = ""                 unless defined $name;
    $style  = wxDEFAULT_FRAME_STYLE 
        unless defined $style;

    my $self = $class->SUPER::new($parent, $id, $title, $pos, $size, $style, $name);

    #$self->{window_1} = Wx::SplitterWindow->new($self, wxID_ANY);
    #$self->{grid_1} = Wx::Grid->new($self->{window_1}, wxID_ANY);

    $self->SetTitle(_T("AM Gui"));
    $self->SetSize(Wx::Size->new(900, 700));
    
    #$self->{grid_1}->CreateGrid(10, 3);
    #$self->{grid_1}->SetSelectionMode(wxGridSelectCells);
   
    $self->{aui} = AMGui::Wx::AuiManager->new($self);

    $self->{cwd} = Cwd::cwd();

    $self->{menubar} = AMGui::Wx::Menubar->new($self);
    $self->SetMenuBar($self->{menubar}->menubar);
    
    $self->{statusbar} = AMGui::Wx::StatusBar->new($self);
    $self->SetStatusBar($self->{statusbar});

    $self->{notebook} = AMGui::Wx::Notebook->new($self);

    Wx::Event::EVT_MENU($self, wxID_NEW,           \&on_file_new);
    Wx::Event::EVT_MENU($self, wxID_OPEN,          \&on_file_open);
    Wx::Event::EVT_MENU($self, wxID_OPEN_PROJECT,  \&on_file_open_project);
    Wx::Event::EVT_MENU($self, wxID_CLOSE,         \&on_file_close);
    Wx::Event::EVT_MENU($self, wxID_EXIT,          \&on_file_quit);
    Wx::Event::EVT_MENU($self, wxID_RUN_BATCH,     \&on_run_batch);
    Wx::Event::EVT_MENU($self, wxID_NEXT_TAB,      \&on_next_tab);
    Wx::Event::EVT_MENU($self, wxID_PREV_TAB,      \&on_previous_tab);
    Wx::Event::EVT_MENU($self, wxID_HELP_CONTENTS, \&on_help_contents);
    Wx::Event::EVT_MENU($self, wxID_ABOUT,         \&on_help_about);

    # Set up the pane close event
    #TODO#Wx::Event::EVT_AUI_PANE_CLOSE($self, sub { shift->on_aui_pane_close(@_); }, );

    return $self;
}

# old wxGlade code
#sub __set_properties {
#    my $self = shift;
#    $self->SetTitle(_T("Main Frame"));
#    $self->SetSize(Wx::Size->new(900, 525));
#
#    $self->{grid_1}->CreateGrid(10, 3);
#    $self->{grid_1}->SetSelectionMode(wxGridSelectCells);
#}

# old wxGlade code
#sub __do_layout {
#    my $self = shift;
#    $self->{sizer_1} = Wx::BoxSizer->new(wxHORIZONTAL);
#    #$self->{window_1}->SplitVertically($self->{grid_1}, $self->{notebook}, );
#    $self->{sizer_1}->Add($self->{window_1}, 1, wxEXPAND, 0);
#    $self->SetSizer($self->{sizer_1});
#    $self->Layout();
#}

######################################################################
# Menu event handlers

sub on_file_new {
    my ($self, $event) = @_;
    warn "Event handler (onFileNew) not implemented";
    $event->Skip;
}

sub on_file_open {
    my ($self, $event) = @_;
    
    my $wildcard = join(
        '|',
        _T('All Files'),  ( AMGui::Constant::WIN32 ? '*.*' : '*' ),
        _T('CSV Files'),  '*.csv;*.CSV',
        _T('Text Files'), '*.txt;*.TXT'
    );
    
    my $fileDlg = Wx::FileDialog->new( 
        $self,
        _T('Open Files'),
        $self->cwd,    # Default directory
        '',            # Default file
        $wildcard,
        wxOPEN|wxFILE_MUST_EXIST
    );

    # If the user really selected a file
    if ($fileDlg->ShowModal == wxID_OK)
    {
        my @filenames = $fileDlg->GetFilenames;
        $self->{cwd} = $fileDlg->GetDirectory;
        
        my @files;
        foreach my $filename (@filenames) {

            # Construct full paths, correctly for each platform
            my $fname = File::Spec->catfile($self->cwd, $filename);

            unless ( -e $fname ) {
                my $ret = Wx::MessageBox(
                    sprintf(_T('File name %s does not exist on disk. Skip it?'), $fname),
                    _T("Open File Warning"),
                    Wx::wxYES_NO|Wx::wxCENTRE,
                    $self,
                );

                next if $ret == Wx::wxYES;
            }

            push @files, $fname
        }
        
        $self->setup_data_viewers(\@files) if scalar(@files) > 0;
    }
    
    return 1;
}

# open 'data' and 'test' files
sub on_file_open_project {
    my ($self, $event) = @_;

    my $wildcard = join(
        '|',
        _T('Project Files'), 'data;Data;DATA;test;Test;TEST',
        _T('All Files'),     ( AMGui::Constant::WIN32 ? '*.*' : '*' )
     );

    my $file_dlg = Wx::FileDialog->new( 
        $self,
        _T('Open Training and Testing datasets at once'),
        $self->cwd,    # Default directory
        '',            # Default file
        $wildcard,
        wxOPEN|wxFILE_MUST_EXIST|wxFD_MULTIPLE
    );

    # If the user really selected a file
    if ($file_dlg->ShowModal == wxID_OK)
    {
        my @filenames = $file_dlg->GetFilenames;
        $self->{cwd} = $file_dlg->GetDirectory;

        # TODO: check that there are exactly two files
        # and swear otherwise
        
        my (@files, @data_types);
        foreach my $filename (@filenames) {
            # Construct full paths, correctly for each platform
            my $fname = File::Spec->catfile($self->cwd, $filename);

            unless ( -e $fname ) {
                my $ret = Wx::MessageBox(
                    sprintf(_T('File name %s does not exist on disk. Skip it?'), $fname),
                    _T("Open File Warning"),
                    Wx::wxYES_NO|Wx::wxCENTRE,
                    $self,
                );

                next if $ret == Wx::wxYES;
            }

            push @files, $fname;
            
            if ( lc $filename eq 'data' ) {
                push @data_types, AMGui::DataSet::TRAINING;
            } elsif (lc $filename eq 'test') {
                push @data_types, AMGui::DataSet::TESTING;
            } else {
                #TODO: react meaningfully
            }
        }
        
        if ( scalar(@files) == 2 ) {
            $self->setup_data_viewers(\@files, \@data_types);
        } else {
            #TODO: throw a warning: invalid number of files
            # TODO: in theory, 2+ files can be opened, it is importants that there are
            # at least one 'train' and at least one 'test' file.
        }
    }

    #$event->Skip;
    return 1;
}


# TODO: check if has unsaved modifications and do something about it
sub on_file_close {
    my ($self, $event) = @_;
    return $self->notebook->close_current_page;
}

sub on_file_quit {
    my ($self, $event) = @_;
    $self->Close(1);
}

sub on_run_batch {
    my ($self, $event) = @_;
    
    my $testing;
    my $training;
    my $curr_page = $self->notebook->get_current_page;
    
    if ( $curr_page and $curr_page->can('purpose') ) {
        #warn "Purpose:" . $curr_page->purpose;
        
        if ( $curr_page->purpose eq 'results' ) {
            # TODO: reach associated training dataset and use reuse it entirely?
            # TODO: warn that current tab will be creared?
            $self->inform("NOT IMPLEMENTED:\n This is the result tab. Switch to a dataset tab");
            #$curr_page->classifier
           
        } elsif ( $curr_page->dataset->is_testing ) {
            # given a testing dataset, use associated training dataset
            $testing  = $curr_page->dataset;
            $training = $testing->training;
            
        } elsif ( $curr_page->dataset->is_training ) {
            $self->inform("NOT IMPLEMENTED.\nPlease switch to a tab with a testing dataset");
            
        } else {
            $training = $curr_page->dataset;
            $testing  = $training;
        }
    } else {
        $self->inform("NOT IMPLEMENTED.\nPlease switch to a tab with a testing dataset");
    }

    if ( defined $testing ) {
        # TODO: recycle existing result viewer
        my $result_viewer = AMGui::Wx::ResultViewer->new($self);

        my $am = AMGui::AM->new;
        $am->set_training($training)->set_testing($testing);
        $am->set_result_viewer($result_viewer);
        $am->classify_all; 
    }

    return 1;
}

sub classify_item {
    my ($self, $dataset_viewer) = @_;
    
    # get data item highlighted in the current DatasetViewer
    my $test_item = $dataset_viewer->current_item;  #=> AM::DataSet::Item
    # reach training dataset associated with the dataset loaded in the current DatasetViewer
    my $training  = $dataset_viewer->training_data; #=> AM::DataSet

    # we want any new item from the current DatasetViewer to be outputted into
    # the same ResultViewer upon classification. If DatasetViewer already has
    # a ResultViewer associated with it, the latter will be reused. Otherwise
    # we create one and associate it with DatasetViewer.
    unless (defined $dataset_viewer->result_viewer) {
        $dataset_viewer->set_result_viewer( AMGui::Wx::ResultViewer->new($self) );
    }
    
    # finally, create a classifier and run it
    my $am = AMGui::AM->new;
    $am->set_training($training); #TODO: ->set_testing($test_item);
    $am->set_result_viewer($dataset_viewer->result_viewer);
    $am->classify($test_item);
    
    return 1;
}

sub on_next_tab {
    my ($self, $event) = @_;
    $self->notebook->select_next_tab;
    return 1;
}

sub on_previous_tab {
    my ($self, $event) = @_;
    $self->notebook->select_previous_tab;
    return 1;  
}

sub on_help_contents {
    my ($self, $event) = @_;
    $self->inform("Help::Contents not yet implemented");
    $event->Skip;
}


sub on_help_about {
    my ($self, $event) = @_;
    $self->inform("Help::About implemented yet");
    $event->Skip;
}

######################################################################

=pod

=head3 C<setup_data_viewers>

    $main->setup_data_viewers( \@files [, \@dataset_types] );

Setup (new) tabs for C<@files>, and update the GUI.

=cut

sub setup_data_viewers {
    my ($self, $files, $dataset_types) = @_;
    $#$dataset_types = $#$files  unless defined $dataset_types;

    my @data_viewers = ();
    my $training;

    for (my $idx=0; $idx <= $#$files; $idx++) {
        my $dv = $self->setup_data_viewer($files->[$idx], $dataset_types->[$idx]);
        push @data_viewers, $dv;
        $training = $dv->dataset  if $dv->dataset->is_training;
    }
    
    # each test dataset must be linked to corresponding training dataset
    if ( $training ) {
        foreach my $dv (@data_viewers) {
            if ( $dv->dataset->is_testing ) {
                $dv->dataset->set_training($training);
            }
        }
    }
    
    return scalar @data_viewers;
}

=pod

=head3 C<setup_data_viewer>

    $main->setup_data_viewer( $file, $dataset_purpose );

Setup a new tab / buffer and open C<$file>, then update the GUI.
dataset_purpose is either 'training' or 'testing'

=cut

# TODO:
#Recycle current buffer if there's only one empty tab currently opened.
#If C<$file> is already opened, focus on the tab displaying it.
#Finally, if C<$file> does not exist, create an empty file before opening it.

sub setup_data_viewer {
    my ($self, $file, $dataset_purpose) = @_;
    
    # load exemplars from file
    my %args = (
        path   => $file,
        format => 'commas'  # TODO: set it from GUI control or from file extension?
    );
    my $dataset = AMGui::DataSet->new(%args);
    $dataset->set_purpose($dataset_purpose) if defined $dataset_purpose;
    
    # GUI component for showing exemplars
    my $dataset_viewer = AMGui::Wx::DatasetViewer->new($self, $dataset);
   
    return $dataset_viewer;
}

######################################################################

sub update_aui {
    my $self = shift;
    #return if $self->locked('refresh_aui');
    $self->aui->Update;
    return;    
}

######################################################################

sub inform {
    my ($self, $msg) = @_;
    Wx::MessageBox($msg, "Informing that", Wx::wxOK);
    return 1;
}


1;
