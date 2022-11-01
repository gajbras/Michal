#!/usr/bin/perl
#
#
# The aim of this tool is to send beautifully decorated messages.
#
# INPUT
#   - standard input contains the message itself
#   - command line argument can contain many parameters, see example
#
# OUTPUT
#   - script sends data to Mattermost based on parameters below (unless --dry-run is used)
#
# SYNOPSIS
# echo -e "May had a little lamb\nits fleece was white as snow\n" | ./mmost-sender.pl --mmost-webhook https://mattermost.soc.tieto.com/hooks/6heokhrapjfwzdbosw1gggfc5e --web-proxy "-x 10.241.118.232:9090" --use-template YELLOW --username "Very Smart Script" --title "Mail Queue" --dry-run
#
use JSON;
#use Data::Dumper;
use Getopt::Long qw(GetOptions);
use 5.01; # important for "say"

$mmost_webhook='https://mattermost.soc.tieto.com/hooks/6heokhrapjfwzdbosw1gggfc5e'; # vixieali-test
$mmost_channel='1dx8jsuq878cd871b339bqc9xw';
$web_proxy='-x 10.241.118.232:9090';
$curl='/usr/bin/curl';
$mmost_sender_templates='/root/MMost/mmost-sender/mmost-sender-templates.json';
$username_value="Alice";
$title_value="SWE Shared";
$use_template="PLAIN";
# for magic values search _MAGIC_VALUE

GetOptions(
        'use-template=s' => \$use_template,
   'channel=s' => \$mmost_channel,
        'dry-run' => \$dry_run,
        'username=s'  => \$username_value,
        'title=s'  => \$title_value,
        'mmost-sender-templates=s' => \$mmost_sender_templates,
        'mmost-webhook=s' => \$mmost_webhook,
        'web-proxy=s' => \$web_proxy, ## TRICKY! YOU HAVE TO ADD "-x" !!!
        'curl=s' => \$curl
);


open(TH, '<', $mmost_sender_templates);
@l=<TH>; $templates_data=join("",@l);
close(TH);
$templates=from_json($templates_data);


@l=<>;
$input_message=join("",@l);

if( length($input_message) > 100000 )
{
  $input_message=q{:scissors: **MESSAGE TRUNCATED** }.substr($input_message,0,100000);
}


%t = %{$templates->{"templates"}}; #{$use_template};
%t = %{$t{$use_template}};
delete $t{'templateComment'};

#if( $dry_run ) {
#       say "Dumper(%t)";
#       say Dumper( %t );
#}

if( $t{'text'} eq 'TEXT_MAGIC_VALUE' ) {
        $t{'text'}=$input_message;
}

if( $t{'username'} eq 'USERNAME_MAGIC_VALUE' ) {
        $t{'username'}=$username_value;
}

if( $t{'channel'} eq 'CHANNEL_MAGIC_VALUE' ) {
        $t{'channel'}=$mmost_channel;
}


for $i (0 .. $#{$t{'attachments'}}) {
  %att = %{$t{'attachments'}[$i]};

#  if( $dry_run ) {
#       say "  Dumper( %{$t{'attachments'}[$i]} )";
#       say Dumper( %{$t{'attachments'}[$i]} );
#       say "\$att{'text'} = ".$att{'text'};
#  }

  if( $att{'text'} eq 'TEXT_MAGIC_VALUE' ) {
        ${$t{'attachments'}[$i]}{'text'}=$input_message;
  }

  if( $att{'title'} eq 'TITLE_MAGIC_VALUE' ) {
        ${$t{'attachments'}[$i]}{'title'}=$title_value;
  }
}

$encoded_output=encode_json(\%t);
$system_command="$curl --silent --request POST --header 'Content-Type: application/json' $web_proxy --insecure --data '$encoded_output' $mmost_webhook 2>&1 | logger";

if ( $dry_run ) {
  say $system_command;
}
else {
  system $system_command;
}
