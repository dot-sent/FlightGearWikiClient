#!/usr/bin/perl

use strict;
use warnings;

use utf8;

use Data::Dumper;
use lib '../../lib/Perl';
use FGWAPI;

$|++;
binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';

sub main{
    print "\n*** Welcome to FlightGear Wiki editor ***\n";
    print "\nAvailable commands: help login read edit quit\n";
    my $api = FGWAPI->new();
    my $input = "";
    my $logged_in = 0;
    my $prompt = "editor (not logged in)";
    while ($input ne 'quit' && $input ne 'exit') {
        $input = _prompt("\n$prompt", "help");
        if ($input =~ m/^help\s*([^\s]*)$/g) {
            my $topic = $1;
            if ($topic eq '' || $topic eq 'help') {
                print "\nAvailable commands: help login read edit quit\n";
                print "\nSynopsis: help [command]\nPrint help for given command. If no command given, print this help.\n";
            } elsif ($topic eq 'login') {
                print "\nSynopsis: login [username]\nLogin to MediaWiki using provided username. Command will ask for password and for username (if none provided).\n";
            } elsif ($topic eq 'read') {
                print "\nSynopsis: read [article_title]\nGet the text of latest revision of given article and open it with 'less'. Will prompt for title if not specified.\n";
            } elsif ($topic eq 'edit') {
                print "\nSynopsis: edit [article_title]\nGet the text of latest revision of given article and open it for edit with 'vim'. Will prompt for title if not specified. After the editor is closed, content of the file will be checked against the previous version and submitted as a new edit if there are any modifications.\n";
            } elsif ($topic eq 'quit') {
                print "\nSynopsis: quit\nExit the application.\n";
            } else {
                print "\nNo help entry found for '$topic'.\n";
            }
        } elsif ($input =~ m/^login\s*([^\s]*)/g) {
            my ($login) = ($1);
            while ($login eq '') {
                $login = _prompt("Enter login");
            }
            system('stty', '-echo');
            my $password = _prompt("Enter password (won't be displayed)");
            system('stty', 'echo');
            print "\nLogging in...\n";
            my $response = $api->login($login, $password);
            if (exists $response->{login} && exists $response->{login}->{result}) {
                if ($response->{login}->{result} eq 'Success') {
                    $prompt = "editor ($login)";
                    $logged_in = 1;
                    print "Successfully logged in as $login.\n";
                } elsif ($response->{login}->{result} eq 'NotExists') {
                    print "User with login '$login' not found.\n";
                } elsif ($response->{login}->{result} eq 'WrongPass') {
                    print "Incorrect password.\n";
                }
                else {
                    print "Got unexpected response:\n".(Dumper $response)."\n";
                }
            }
            else {
                print "Got unexpected response:\n".(Dumper $response)."\n";
            }
        } elsif ($input =~ m/^edit\s*([^\s]*)$/g) {
            my $title = $1;
            if (!$logged_in) {
                print "Please login before using edit.\n";
            } else {
                while ($title eq '' && $title ne 'abort') {
                    $title = _prompt("Enter title to edit or 'abort' to return to prompt", "abort");
                }
                if ($title ne 'abort') {
                    my $response = $api->get_text($title);

                    if (exists $response->{query}->{pages} && scalar @{$response->{query}->{pages}} > 0){
                        my $new_text = '';
                        my $orig_text = '';
                        if (exists $response->{query}->{pages}->[0]->{missing}) {
                            my $create = '';
                            while ($create ne 'y' && $create ne 'n') {
                                $create = lc _prompt("The page '$title' does not exist. Create new page? y/n", "y");
                            }
                            if ($create eq 'y') {
                                my $original = _prompt("Enter the title of page to copy (blank for empty)", '');
                                $orig_text = '';
                                while ($original ne '' && $orig_text eq '') {
                                    my $response_orig = $api->get_text($original);
                                    if (exists $response_orig->{query}->{pages}->[0]->{missing}){
                                        $original = _prompt("Page '$original' not found or empty on the Wiki!\nEnter the title of page to copy (blank for new file)", '');
                                    } elsif (exists $response_orig->{query}->{pages}->[0]->{revisions}->[0]->{content}) {
                                        $orig_text = $response_orig->{query}->{pages}->[0]->{revisions}->[0]->{content};
                                    } else {
                                        print "Can't parse response from the Wiki:\n".(Dumper $response_orig)."\n";
                                        $original = _prompt("Enter the title of page to copy (blank for empty)", '');
                                    }
                                }
                                $new_text = _edit_temp_file($orig_text);
                            }
                        } elsif (exists $response->{query}->{pages}->[0]->{revisions}->[0]->{content}){
                            $orig_text = $response->{query}->{pages}->[0]->{revisions}->[0]->{content};
                            $new_text = _edit_temp_file($response->{query}->{pages}->[0]->{revisions}->[0]->{content});
                        }
                        if ($new_text eq '') {
                            print "You have not entered any text. No edit will be performed.\n";
                        } else {
                            my $summary = _prompt("Enter summary for your edit", "Edited via FlightGear Wiki editor");
                            $response = $api->edit($title, $summary, $new_text);
                            if (exists $response->{edit}->{result} && $response->{edit}->{result} eq 'Success') {
                                print "Your edit has been saved. Check it out at http://wiki.flightgear.org/$title :)\n";
                            } else {
                                print "Could not parse response from Edit:\n".(Dumper $response)."\n";
                            }
                        }
                    } else {
                        print "Got unexpected response:\n".(Dumper $response)."\n";
                    }
                }
            }
        } elsif ($input =~ m/^read\s*([^\s]*)$/g) {
            my $title = $1;
            while ($title eq '' && $title ne 'abort') {
                $title = _prompt("Enter title to read or 'abort' to return to prompt", "abort");
            }
            if ($title ne 'abort') {
                my $response = $api->get_text($title);
                if (exists $response->{query}->{pages}->[0]->{revisions}->[0]->{content}){
                    open my $fh, '>', 'temp.wiki';
                    binmode $fh, ":utf8";
                    print $fh $response->{query}->{pages}->[0]->{revisions}->[0]->{content};
                    close $fh;

                    system('less temp.wiki');
                } else {
                    print "Article '$title' not found.\n" ;
                }
            }

        } elsif ($input ne 'exit' && $input ne 'quit') {
            print "Unrecognized command: '$input'.\nAvailable commands: help login read edit quit\n";
        }
    }
}

sub _edit_temp_file{
    my ($text) = @_;

    open my $fh, '>', 'temp.wiki';
    binmode $fh, ":utf8";
    print $fh $text;
    close $fh;

    system 'vim temp.wiki';

    open $fh, '<', 'temp.wiki';
    binmode $fh, ":utf8";
    my $tmp = $/;
    $/ = undef;
    my $newtext = <$fh>;
    $/ = $tmp;
    close $fh;
    
    return $newtext;
}

sub _prompt {
  	my($prompt, $default) = @_;
  	my $defaultValue = $default ? "[$default]" : "";
  	print "$prompt $defaultValue> ";
  	my $_input = <STDIN>;
    $_input =~ s/[\n\r\f\t]//g;
  	return $_input ? $_input : $default;
}

main();

exit 0;
