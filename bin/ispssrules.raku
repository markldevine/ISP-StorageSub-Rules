#!/usr/bin/env raku

use ISP::Servers;
use ISP::dsmadmc;
use Term::TablePrint;
use Data::Dump::Tree;

my %node-groups-to-members;
my %node-to-node-group;

sub MAIN (
        :$isp-server            = '',       #= ISP server name
    Str :$isp-admin             = 'ISPMON', #= ISP admin name
) {
    my $SERVER_NAME             = ISP::Servers.new().isp-server($isp-server);
    my ISP::dsmadmc $dsmadmc   .= new(:isp-server($SERVER_NAME), :$isp-admin);

    my @STGRULES                = $dsmadmc.execute(<SELECT RULENAME,TGTSRV,TYPE,STARTTIME,MAXSESSIONS FROM STGRULES WHERE ACTIVE='YES'>);
    for @STGRULES -> $stgrule {
        my $hour;
        my $minute;
        my $second;
        ($hour, $minute, $second) = $stgrule{'STARTTIME'}.split(':');
        my $date-time           = DateTime.new(date => Date.today, :$hour, :$minute, :$second, :timezone($dsmadmc.seconds-offset-UTC));
        put $stgrule{'RULENAME'} ~ ' ' ~ $date-time;
    }
#   my @SUBRULES                = $dsmadmc.execute(<SELECT PARENTRULENAME,SUBRULENAME,NODENAME,TGTSRV,DATATYPE FROM SUBRULES WHERE ACTION_TYPE='REPLICATE'>);

#   my @NODEGROUPS              = $dsmadmc.execute(<QUERY NODEGROUP FORMAT=DETAILED>);
#   for @NODEGROUPS -> $node-group {
#       my @node-group-members  = Nil;
#       @node-group-members     = split(/\s/, $node-group{'Node Group Member(s)'});
#       %node-groups-to-members{$node-group{'Node Group Name'}} = @node-group-members;
#       for @node-group-members -> $member {
#           %node-to-node-group{$member} = $node-group{'Node Group Name'};
#       }
#   }
#ddt %node-groups-to-members;
#ddt %node-to-node-group;
}

=finish

my class STGRULE {
    has Int         $.MAXSESSIONS;
    has Str         $.RULENAME;
    has DateTime    $.STARTTIME;
    has             %.subrules;
    has Str         $.TGTSRV;
    has Str         $.nodes;
}

[24] @0
├ 0 = {5} @1
│ ├ MAXSESSIONS => 10.Str
│ ├ RULENAME => REPL_0030_ISPLC02.Str
│ ├ STARTTIME => 00:30:00.Str
│ ├ TGTSRV => ISPLC02.Str
│ └ TYPE => NOREPLICATING.Str

[36] @0
├ 0 = {5} @1
│ ├ DATATYPE => ALL.Str
│ ├ NODENAME => DFS.Str
│ ├ PARENTRULENAME => REPL_0030_ISPLC02.Str
│ ├ SUBRULENAME => REPL_DFS_0030_ISPLC02.Str
│ └ TGTSRV => ISPLC02.Str

[6] @0
├ 1 = {5} @2
│ ├ Last Update Date/Time => 06/29/23   17:58:28.Str
│ ├ Last Update by (administrator) => A028441.Str
│ ├ Node Group Description => .Str
│ ├ Node Group Member(s) => DFS2K16-12 DFS2K16-13 DFS2K16-14 DFS2K16-15 DFS2K16-16 DFS2K16-17 DFS2K16-18 DFS2K16-19 JGDFS2K12-27PV JGDFS2K12-25PV JGDFS2K12-22 JGDFS2K12-24PV JGDFS2K12-21 DFS2K16-20 DFS2K16-23 JGDFS2K12-26PV DFS2K16-11.Str
│ └ Node Group Name => DFS.Str
