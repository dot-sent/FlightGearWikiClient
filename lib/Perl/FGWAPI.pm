package FGWAPI;
use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use Data::Dumper;
use JSON qw(encode_json decode_json);
use URL::Encode qw(url_encode_utf8 url_decode_utf8 url_encode url_decode);

use constant BASE => 'http://wiki.flightgear.org/api.php?format=json';

my $cookie_jar = HTTP::Cookies->new(file => 'cookies.txt', autosave => 1);
if (-e 'cookies.txt') {
	$cookie_jar->load('cookies.txt');
}
my $ua;

sub new{
    my ($self) = @_;
    $ua = LWP::UserAgent->new;
    $ua->cookie_jar($cookie_jar);
    return $self;
}

sub login{
    my ($self, $login, $password) = @_;
    my $response = $ua->post(BASE,
    {
        action      => 'login',
        lgname      => $login,
        lgpassword  => $password,
    });
    my $res_obj = decode_json($response->content);
    _dropdead("Can't parse response format.", $response) unless exists $res_obj->{login} && exists $res_obj->{login}->{result};
    return $res_obj if $res_obj->{login}->{result} eq 'Success';
    _dropdead("Unexpected login status: $res_obj->{login}->{result}.", $response) unless $res_obj->{login}->{result} eq 'NeedToken';
    _dropdead("Missing login token.", $response) unless exists $res_obj->{login}->{token};
    $response = $ua->post(BASE,
    {
        action      => 'login',
        lgname      => $login,
        lgpassword  => $password,
        lgtoken     => $res_obj->{login}->{token}
    });
    $res_obj = decode_json($response->content);
    return $res_obj;
}

sub edit{
    my ($self, $title, $summary, $text) = @_;
    #We need to get CSRF token first
    my $response = $ua->post(BASE, {
        action  => 'query',
        meta    => 'tokens',
    });
    my $res_obj = decode_json($response->content);
    _dropdead("Can't parse response format.", $response) unless exists $res_obj->{query} && exists $res_obj->{query}->{tokens} && exists $res_obj->{query}->{tokens}->{csrftoken};
    my $token = $res_obj->{query}->{tokens}->{csrftoken};
    $response = $ua->post(BASE, {
        action  => 'edit',
        title   => $title,
        summary => $summary,
        text    => $text,
        token   => $token,
    });
    $res_obj = decode_json($response->content);
    _dropdead("Can't parse response format.", $response) unless exists $res_obj->{edit}->{result};
    return $res_obj if $res_obj->{edit}->{result} eq "Success";
    _dropdead("Don't know what to do with this response.", $response) unless $res_obj->{edit}->{result} eq "Failure" && exists $res_obj->{edit}->{captcha};
    $response = $ua->post(BASE, {
        action          => 'edit',
        title           => $title,
        summary         => $summary,
        text            => $text,
        token           => $token,
        wpCaptchaId     => $res_obj->{edit}->{captcha}->{id},
        wpCaptchaWord   => 'FlightGear', #There is some nice anti-spam protection here
    });
    $res_obj = decode_json($response->content);
    return $res_obj;
}

sub get_text{
    my ($self, $title) = @_;
    my $response = $ua->post(BASE,{
        action          => 'query',
        titles          => $title,
        prop            => 'revisions',
        rvprop          => 'content',
        formatversion   => 2,
        utf8            => 1,
        ascii           => 0,
    });

    my $res_obj = decode_json($response->content);
    return $res_obj;
}

sub _dropdead{
    my ($message, $response) = @_;
    die "$message\nRaw Response: ".Dumper($response)."\n";
}

1;
