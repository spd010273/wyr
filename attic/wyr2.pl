#!/use/bin/perl

use utf8;
use strict;
use warnings;


use Carp;
use Slack::RTM::Bot;
use AI::CleverbotIO;
use Params::Validate qw( :all );
use Perl6::Export::Attrs;
use JSON;
use Readonly;
use Chatbot::Eliza;
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use Data::Dumper;

Readonly my $DEBUG => 1;
Readonly my $SITE  => 'http://either.io';
Readonly my $SLACK_TOKEN => '';
my $bot_handle = {};

sub _get_random_error()
{
    return "Uh ohhhh";
}

sub _get_wyr($)
{
    my( $chat ) = @_;
    my $channel = $chat->{channel};
    my $ua = LWP::UserAgent->new;
       $ua->agent(
        'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
    );

    my $req = HTTP::Request->new( GET => $SITE );

    my $response = $ua->request( $req );
    my $wyr_text;
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
        _bot_say( $wyr_text, $channel );
    }

    return; 
}

sub _parse_command($)
{
    my( $response ) = @_;

    my $command_text    = $response->{text};
    my $command_user    = $response->{user};
    my $command_channel = $response->{channel};
    my $command = $command_text;
    my $command_option = $command_text;

    $command =~ s/^--(\w+)=.*/$1/;
    $command_option =~ s/^--\w+=(.*)$/$1/;

    return unless( $command );
    print "Received command '$command' = '$command_option' from $command_user on $command_channel\n";

    if( $command_user ne 'chris' )
    {
        _bot_say( _get_random_error(), $command_channel );
    }

    if( $command =~ m/channel/i )
    {
        _init_slack( $command_option );
    }
    elsif( $command =~ m/bot/i )
    {
        if( $command_option =~ m/eliza/i )
        {
            _init_e();
        }
        elsif( $command_option =~ m/cleverbot/i )
        {
            _init_cb();
        }
        else
        {
            _bot_say( "I can't allow you do that, Dave.", $command_channel );
        }
    }
    elsif( $command =~ m/say/i )
    {
        _bot_say( $command_option, $bot_handle->{_channel} );
    }
    elsif( $command =~ m/debug/i )
    {
        _bot_say( "Running Chatbot: " . ref( $bot_handle->{_current} ), $command_channel );
        _bot_say( "Running RTM: " . ref( $bot_handle->{_slack} ), $command_channel );
        _bot_say( "Current PID: $$", $command_channel );
        _bot_say( "Current CNC: $command_channel", $command_channel );
    }
    elsif( $command =~ m/switchcnc/i )
    {
        _init_slack( $bot_handle, $command_option );
    }
    elsif( $command =~ m/help/ )
    {
        _bot_say( "Commands:", $command_channel );
        _bot_say( " --debug", $command_channel );
        _bot_say( " --say=<words>", $command_channel );
        _bot_say( " --bot=[eliza,cleverbot]", $command_channel );
        _bot_say( " --switchcnc=<channel>", $command_channel );
        _bot_say( " --channel=<channel>", $command_channel );
    }
    else
    {
        _bot_say( _get_random_error(), $command_channel );
    }

    return;
}

sub getpid()
{
    my $self = shift;
    return $self->{child};
}

*Slack::RTM::Bot::getpid = \&getpid;

sub _init_slack(;$$)
{
    my( $channel, $cnc ) = @_;

    unless( $channel )
    {
        $channel = 'wyr_test';
    }

    unless( $cnc )
    {
        $cnc = 'wyr_test';
    }

    if( defined( $bot_handle->{_slack} ) )
    {
        my $slackbot = $bot_handle->{_slack};
        my $child_pid = $slackbot->getpid();

        if( $child_pid )
        {
            print "Child PPID: $child_pid\n";
            $slackbot->stop_RTM;
        }

        $bot_handle->{_slack} = undef;
    }

    my $bot = Slack::RTM::Bot->new(
        token => $SLACK_TOKEN,
    );

    $bot_handle->{_channel} = $channel;
    $bot->on(
        {
            channel => $channel,
            text    => '<@U3KQV40R0>',
        },
        \&_handle_mention
    ) ;
   
    $bot->on(
        {
            channel => $channel,
            text    => '^\/\/wyr$',
        },
        \&_get_wyr
    );
    print "Slackbot listening on '$channel'\n";
    # Setup CNC callbacks
    $bot->on(
        {
            channel => $cnc,
            text    => '^--',
        },
        \&_parse_command
    );
    
    if( $DEBUG )
    {
        $bot->on(
            {
                text => '.*',
            },
            \&_debug
        );
        
        print "Initializing default bot...\n";
    }
    
    $bot_handle->{_slack} = $bot;

    $bot->start_RTM;

    return;
}

sub _init_cb()
{
    if( defined( $bot_handle->{_current} ) )
    {
        if( ref( $bot_handle->{_current} ) eq 'AI::CleverbotIO' )
        {
            return;
        }

        $bot_handle->{_current} = undef;
    }

    my $bot = AI::CleverbotIO->new(
        key  => 'n8yHP4R5m7cHpmVylzp9tAdg98sBqq2l',
        nick => 'wyr_cb_test',
        user => 'fZUohFX8ivs26aDZ',    
    );
    
    $bot->create();

    print "Switched to Cleverbot\n";
    $bot_handle->{_current} = $bot;
    
    return;
}

sub _init_e()
{
    if( defined( $bot_handle->{_current} ) )
    {
        if( ref( $bot_handle->{_current} ) eq 'Chatbot::Eliza' )
        {
            return;
        }

        $bot_handle->{_current} = undef;
    }

    my $bot = new Chatbot::Eliza;
    $bot->name( 'would_you_rather' );
    $bot->debug( 1 ) if( $DEBUG );
    #$bot->command_interface;
    print "Switched to Eliza\n";
    $bot_handle->{_current} = $bot;

    return;
}

sub _bot_say($$)
{
    my( $reply, $channel ) = @_;
    my $slack_bot = $bot_handle->{_slack};

    $slack_bot->say(
        text    => $reply,
        channel => $channel,
    );

    return;
}

sub _handle_mention($)
{
    my( $response ) = @_;

    print Dumper( $response );

    my $response_text = $response->{text};
    my $response_user = $response->{user};
    my $reply_text    = '';
    $response_text    =~ s/\@wyr//ig;
    my $channel       = $response->{channel};
    my $slack_bot     = $bot_handle->{_slack};

    if( $bot_handle->{_current} )
    {
        my $bot = $bot_handle->{_current};

        if( ref( $bot ) eq 'AI::CleverbotIO' )
        {
            my $reply = $bot->ask( $response_text );
            $reply_text = $reply->{response};
            print "Received $reply_text\n";
        }
        elsif( ref( $bot ) eq 'Chatbot::Eliza' )
        {
            $reply_text = $bot->transform( $response_text );
            print "Received $reply_text\n";
        }
    }
    else
    {
        print "No bot to forward to :(\n";
        print 'AI: ' . ref( $bot_handle->{_current} ) ."\n";
        print 'Slack: '. ref( $bot_handle->{_slack} ) ."\n";
        $slack_bot->say(
            text => "I don't know what to say, \@$response_user",
            channel => $channel
        );

        return;
    }

    $reply_text =~ s/cleverbot/wyr/ig;
    $reply_text .= " \@$response_user";

    _bot_say( $reply_text, $channel );

    return;
}

sub _debug($)
{
    my( $response ) = @_;

    print Dumper( $response );

    return;
}

sub _main()
{
    _init_slack( 'would_you_rather', 'wyr_test' );

    my $slackbot = $bot_handle->{_slack};
    
    _init_e();
    
    while( 1 )
    {
        sleep 1;
        
        if( $DEBUG )
        {
            print "I'm here!\n";
        }
    }
}

_main();

