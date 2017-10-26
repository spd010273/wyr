# Would You Rather Bot

slackbot that integrates:
* rather.io - for generating random would you rather questions
* Cleverbot - for programatically sexually harrassing employees
* Eliza Chatbot - fallback for cleverbot failures


By synergizing these services, wyr_bot was able to keep our #would_you_rather slack channel alive with minimal human input.

The bot accepts administrative commands from a separate, private channel.

## Commands

* say <command>: Bot will forward message to main channel
* debug: Bot will print current stats such as RTM status, PID, command and control settings
* help: list commands
* bot <bot_type>: Change chatbot
* channel <channel>: Add a new channel


## Libraries:

wyr_bot relies on the following libraries:

* Slack::RTM::Bot
* AI::CleverbotIO
* Chatbot::Eliza
* HTML::TreeBuilder::XPath
* LWP::UserAgent
* Carp
* JSON
* Readonly
* Data::Dumper
* Params::Validate
* Perl6::Export::Attrs


## Current errata:

Slack RTM lib occasionally hangs after long periods of inactivity
