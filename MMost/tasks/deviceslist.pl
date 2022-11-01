#!/usr/bin/env perl

use HTTP::Request;
use LWP::UserAgent;
use JSON;
use Data::Dumper;

$|=1;

# GET ZONE NAMES
%zone_names={};
$zone_names{0}='';
foreach (qx{/usr/local/bin/nquery -d esm -q "select * from zone" --noblob 2>/dev/null}) {
  if( /^(\d+)\|([^|]+)/ ) {
    $zone_names{$1}=$2;
    print STDERR "$1 ... $2\n";
  }
}

# GET CREDENTIALS
eval {
  local $SIG{ALRM} = sub { die "**ERROR - Custodian timed out.**\n" };
  alarm 5;
  $result = open($crehandle,'+</root/MMost/tmp/custodian');
  $cred=readline($crehandle);
  close($crehandle);
  alarm 0;
};

if( ($result == undef) || ($@)) {
  if( $cred eq "" ) {
    die "**ERROR - Missing credentials, custodian not working.**";
  }
  die "**ERROR - Custodian not working.**";
}

# LOGIN
$url=q{https://127.0.0.1/rs/esm/login};
$rq = HTTP::Request->new('POST', $url , ['Content-Type' => 'application/json; charset=UTF-8'] , $cred);
$ua = new LWP::UserAgent;
$ua->ssl_opts(verify_hostname => 0);
$rs = $ua->request($rq);

if( $rs->header('Xsrf-Token') eq "" ) {
  die "**ERROR No Xsrf-Token. Somebody fed custodian with invalid credentials.**"
}

# Take "Set-Cookie" and add it to all following requests as "Cookie". Take "Xsrf-Token" and add it to all following requests as "X-Xsrf-Token".
$header_Cookie=$rs->header('Set-Cookie');
$header_X_Xsrf_Token=$rs->header('Xsrf-Token');
$json_auth_header=['Content-Type' => 'application/json; charset=UTF-8', 'Cookie' => $header_Cookie, 'X-Xsrf-Token' => $header_X_Xsrf_Token ];
#print("Special headers:\n$header_Cookie\n$header_X_Xsrf_Token\n");

# STUPID DEVICE LIST
# https://confluence.shared.int.tds.tieto.com/display/SOC/McAffee+SIEM+API#McAffeeSIEMAPI-devGetDeviceListfromPublicAPI
$url=q{https://127.0.0.1/rs/esm/devGetDeviceList?filterByRights=false};
#$rq = HTTP::Request->new('POST', $url, $json_auth_header, '{"types": [ "IPS", "RECEIVER", "THIRD_PARTY", "DBM", "DBM_DB", "DBM_AGENT", "VA", "IPSVIPS", "ESM", "APM", "APMVIPS", "ELM", "ELMREC", "LOCALESM", "RISK", "ASSET", "EPO", "EPO_APP", "NSM", "NSM_SENSOR", "MVM", "SEARCH_ELASTIC", "BUCKET", "UNKNOWN" ]}');
#$rq = HTTP::Request->new('POST', $url, $json_auth_header, '{"types": [ "THIRD_PARTY", "RISK", "ASSET", "EPO", "EPO_APP", "BUCKET", "UNKNOWN" ]}');
$rq = HTTP::Request->new('POST', $url, $json_auth_header, '{"types": [ "THIRD_PARTY" ]}');
$rs = $ua->request($rq);
$rs_body=$rs->content;

print STDERR "DUMB DEVICES TO ITERATE\n$rs_body\n\n\n\n";

$devices_dumb = JSON->new->utf8->decode($rs_body)->{'return'};

foreach $dd (@{$devices_dumb}) {
  $dd_name=$dd->{'name'};
  $dd_id=$dd->{'id'}->{'id'};
  print STDERR "\n\nTO ITERATE: $dd_name     $dd_id\n";

  # GET DATA SOURCE DETAILS
  $url=q{https://127.0.0.1/rs/esm/dsGetDataSourceDetail};
  $rq_body='{"datasourceId":{"value":"'.$dd_id.'"}}';
  print STDERR "Request for dsGetDataSourceDetail: $rq_body\n";
  $rq = HTTP::Request->new('POST', $url, $json_auth_header, $rq_body);
  $rs = $ua->request($rq);
  $rs_headers=$rs->headers_as_string;
  $rs_body=$rs->content;
  print STDERR "Response from dsGetDataSourceDetail: $rs_body\n";

  if( $rs_body !~ /ERROR/ ) {
    $device_details = JSON->new->utf8->decode($rs_body)->{'return'};


    $details_name=$device_details->{'name'};
    $details_zone_id=$device_details->{'zoneId'};

    #print("name=\"$details_name\" zoneName=\"$zone_names{$details_zone_id}\" parentId=\"$device_details->{'name'}->{'value'}\" " );
    print("name=\"$device_details->{'name'}\" zoneId=\"$details_zone_id\" zoneName=\"$zone_names{$details_zone_id}\" parentId=\"$device_details->{'name'}->{'value'}\" " );

    for $dd ("enabled", "childEnabled", "childCount", "childType", "url", "collector", "parser" ) {
      $dd_value=$device_details->{$dd};
      print("$dd=\"$dd_value\" ");
    }

    $details_parameters=$device_details->{'parameters'};
    for $dp (@{$details_parameters}) {
         $dp_key=$dp->{'key'};
         $dp_value=$dp->{'value'};
         if( ($dp_key ne "filters") && ($dp_key ne "FILTERS") ) {
            print(" $dp_key=\"$dp_value\"");
         }
    }
    print("\n");

    print STDERR "\n";
  }

}
