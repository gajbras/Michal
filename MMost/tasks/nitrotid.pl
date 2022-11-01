#!/usr/bin/perl
use Time::Local;
use POSIX qw(strftime);

$min_diff = 2*60*60 ;


%fromt=();
%tot=();
%gap=();
%overlay=();
%status1=();
%status2=();

#open $pipe, '-|', 'NitroTID -d sfx -t alert -4';

#  212) ID - 6584    1,589,420 rec(s) | 08/12/2022 22:42:44.000 to 08/12/2022 23:59:59.999 | A   | NM | 193956454654519 | 08/18/2022 19:41:58 | open
#while( <$pipe> ) {
while( <STDIN> ) {
  #                     month  day    year  hour   min    sec   ms      month  day    year  hour   min    sec  ms           Status1      Status2
  #           1         2      3      4     5      6      7             8      9      10    11     12     13                14           15
  if( /ID \- (\d+).+ \| (\d+)\/(\d+)\/(\d+) (\d+)\:(\d+)\:(\d+)\.\d+ to (\d+)\/(\d+)\/(\d+) (\d+)\:(\d+)\:(\d+)\.\d+\s+\|\s*(\S+)\s*\|\s*(\S+)/ ) {
    $blkid=$1;
    $fromt = timelocal( $7, $6, $5,$3,$2-1, $4);
    $tot   = timelocal($13,$12,$11,$9,$8-1,$10);
    $from{$blkid}=$fromt;
    $to{$blkid}=$tot;
    $status1{$blkid}=$14;
    $status2{$blkid}=$15;
    }

# OVERLAPPING PARTITIONS

#   97) ID - 6700 => 09/07/2022 23:30:48.000 | 09/07/2022 23:59:59.999 | 653,579 rec(s)
  if( /ID \- (\d+) \=\> (\d+)\/(\d+)\/(\d+) (\d+)\:(\d+)\:(\d+)\.\d+ \| (\d+)\/(\d+)\/(\d+) (\d+)\:(\d+)\:(\d+)\.\d+/ ) {
    $overlay{$1}="OVL";
  }
}

#close $pipe;

$first_pass=1;
for $t (sort { $from{$a} <=> $from{$b} } keys %from) {
  if( $first_pass ) {
      $oldest_from=$from{$t};
                $days_back=int((time()-$oldest_from)/(60*60*24));
                if( $days_back < 40 ) {
                  print ":red_circle:";
                } else {
                  print ":white_check_mark:";
                }
                $oldest_from_string = strftime "%a %b %e %Y %H:%M", localtime $oldest_from;
                print " The oldest partition (ID $t) started $days_back days ago: $oldest_from_string - ".strftime "%a %b %e %Y %H:%M", localtime $to{$t};
                print "\n\n";
      $last_to=$from{$t}; # Yes, this is correct.
      $first_pass=0;
      $last_id=$t; # This is necessary to display afterlines properly later
    }

#    print "CHECK THE GAP \tfrom t = ".strftime("%b %e %H:%M", localtime $from{$t})."to t = ".strftime("%b %e %H:%M", localtime $to{$t})."\tlast_to=".strftime("%b %e %H:%M", localtime $last_to)."\n";
    if( ($from{$t}-$last_to) > $min_diff ) {
      $gap{$t}=int(($from{$t}-$last_to)/60)." min";
    }
    $last_to=$to{$t};
}


print "|  | ID | Interval | Gap? | Overlay? | Status1 | Status2 |\n";
print "|--|----|----------|----------|---------|---------|\n";

for $id (sort { $from{$a} <=> $from{$b} } keys %from) {
#    printf "| DEBUG %s | %d |%s | %s | %s | %s | %s |\n", $symbol, $id, strftime("%a %b %e %Y %H:%M", localtime $from{$id})." - ".strftime("%a %b %e %Y %H:%M", localtime $to{$id}), $gap{$id}, $overlay{$id}, $status1{$id}, $status2{$id};
  $symbol=':white_check_mark:';
  if( $gap{$id} ne '' ) { $symbol=':red_circle:'; }
  if( $overlay{$id} ) { $symbol=':warning:'; } # regardless of gap, if there is overlay, we are fine
  if( $status1{$id} ne 'A' ) { $symbol=':red_circle:'; } # regardless of overlays and gaps, if there is not A, it is bad
  #if( $overlay{$id+1} || $gap{$id+1} || $overlay{$id} || $gap{$id} || $overlay{$id-1} || $gap{$id-1} || $symbol ne ':white_check_mark:' ) {
  if( ($overlay{$id} ne '') || ($gap{$id} ne '') || ($symbol ne ':white_check_mark:') ) {
    printf "| %s | %d |%s | %s | %s | %s | %s |\n", $symbol, $id, strftime("%a %b %e %Y %H:%M", localtime $from{$id})." - ".strftime("%a %b %e %Y %H:%M", localtime $to{$id}), $gap{$id}, $overlay{$id}, $status1{$id}, $status2{$id};
  }
  if( ($symbol eq ':white_check_mark:') && (($overlay{$last_id} ne '') || ($gap{$last_id} ne ''))) {
    printf "| %s | %d |%s | %s | %s | %s | %s |\n", $symbol, $id, strftime("%a %b %e %Y %H:%M", localtime $from{$id})." - ".strftime("%a %b %e %Y %H:%M", localtime $to{$id}), $gap{$id}, $overlay{$id}, $status1{$id}, $status2{$id};
  }
  $last_id=$id;
}
