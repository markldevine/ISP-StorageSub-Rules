#!/usr/bin/env raku

use ISP::Servers;
use ISP::dsmadmc;
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

      RULENAME: REPL_0200_ISPLC01
       TGTPOOL: 
        TGTSRV: ISPLC01
          TYPE: NOREPLICATING
         DELAY: 
    MAXPROCESS: 
       TGTTYPE: 
      DURATION: No Limit
     STARTTIME: 02:00:00
   DESCRIPTION: 
        ACTIVE: YES
       SRCPOOL: 
      NODELIST: 
        FSLIST: 
      NAMETYPE: 
      CODETYPE: 
   LASTEXETIME: 
     PCTUNUSED: 
     AUDITTYPE: 
    AUDITLEVEL: 
   MAXSESSIONS: 10
TRANSFERMETHOD: TCPIP

PARENTRULENAME: REPL_0000_ISPLC01
 PARENTRULE_ID: 11
   SUBRULENAME: REPL_DFS_0000_ISPLC01
    SUBRULE_ID: 1
   ACTION_TYPE: REPLICATE
         DELAY: 
    MAXPROCESS: 
      NODENAME: DFS
        NODEID: 
       PATTERN: 
          FSID: 
    IS_PATTERN: NO
       TGTPOOL: 
        TGTSRV: ISPLC01
      DATATYPE: ALL
