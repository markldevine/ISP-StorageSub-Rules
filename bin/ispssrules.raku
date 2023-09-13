#!/usr/bin/env raku

use ISP::Servers;
use ISP::dsmadmc;
use Term::TablePrint;
use Data::Dump::Tree;

sub MAIN (
        :$isp-server            = '',       #= ISP server name
    Str :$isp-admin             = 'ISPMON', #= ISP admin name
) {
    my $SERVER_NAME             = ISP::Servers.new().isp-server($isp-server);
    my ISP::dsmadmc $dsmadmc   .= new(:isp-server($SERVER_NAME), :$isp-admin);
    ddt $dsmadmc.execute(<SELECT RULENAME,TGTSRV,TYPE,STARTTIME,MAXSESSIONS FROM STGRULES WHERE ACTIVE='YES'>);
    ddt $dsmadmc.execute(<SELECT PARENTRULENAME,SUBRULENAME,NODENAME,TGTSRV,DATATYPE FROM SUBRULES WHERE ACTION_TYPE='REPLICATE'>);
    ddt $dsmadmc.execute(<QUERY NODEGROUP FORMAT=DETAILED>);
}

=finish

my class RULESET {
    has Str $.;
    has Str $.STARTTIME;
    has Str $.TGTSRV;
    has NG  $.nodegroup;
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
