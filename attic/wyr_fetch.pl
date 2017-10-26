#!/usr/bin/perl

use utf8;
use strict;
use warnings;

use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Readonly;
use Data::Dumper;

Readonly my $SITE => 'http://either.io';
my $ua = LWP::UserAgent->new;
   $ua->agent(
    'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
);

my $req = HTTP::Request->new( GET => $SITE );

my $response = $ua->request( $req );
my $wyr_text = '';
if( $response->is_success )
{
    # look for class 'option-text'
    my $tree = HTML::TreeBuilder::XPath->new_from_content( $response->content );
    my @data = $tree->findvalues( '//span[ @class = "option-text" ]' );
    my $option_one = shift( @data );
    my $option_two = shift( @data );

    $wyr_text =<<"WYR";
Would you rather:

1) $option_one
2) $option_two
WYR
}
else
{
    print "Error.\n";
}

if( $wyr_text )
{
    print "$wyr_text\n";
}
