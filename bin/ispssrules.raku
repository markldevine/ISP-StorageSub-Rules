#!/usr/bin/env raku

use ISP::Servers;
use ISP::dsmadmc;
use Term::TablePrint;
use Data::Dump::Tree;

my $SERVER_NAME;
my $ADMIN_NAME;
my $NODE;

my %subrule;
my class SUBRULE {
    has Str         $.DATATYPE;
    has Str         $.NODENAME;
    has Str         $.PARENTRULENAME;
    has Str         $.SUBRULENAME;
    has Str         $.TGTSRV;
}

my %stgrule;
my class STGRULE {
    has             $.MAXSESSIONS;
    has Str         $.RULENAME;
    has DateTime    $.STARTTIME;
    has             $.subrules;
    has             $.TGTSRV;
}

my %node-groups-to-members;
my %node-to-node-group;

sub MAIN (
            :$isp-server            = '',       #= ISP server name
    Str     :$isp-admin             = 'ISPMON', #= ISP admin name
    Str     :$node                              #= Show STGRULEs by node
) {
    $SERVER_NAME                    = ISP::Servers.new().isp-server($isp-server).uc;
    $ADMIN_NAME                     = $isp-admin.uc;
    $NODE                           = $node.uc with $node;

    my ISP::dsmadmc $dsmadmc       .= new(:isp-server($SERVER_NAME), :isp-admin($ADMIN_NAME));

    my @NODEGROUPS                  = $dsmadmc.execute(<QUERY NODEGROUP FORMAT=DETAILED>);
    for @NODEGROUPS -> $node-group {
        my @node-group-members      = Nil;
        @node-group-members         = split(/\s/, $node-group{'Node Group Member(s)'});
        %node-groups-to-members{$node-group{'Node Group Name'}} = @node-group-members;
        for @node-group-members -> $member {
            %node-to-node-group{$member}.push: $node-group{'Node Group Name'};
        }
    }
#ddt %node-groups-to-members;
#ddt %node-to-node-group;

    my @SUBRULES                    = $dsmadmc.execute(<SELECT PARENTRULENAME,SUBRULENAME,NODENAME,TGTSRV,DATATYPE FROM SUBRULES WHERE ACTION_TYPE='REPLICATE'>);
    for @SUBRULES -> $subrule {
        my $subrule-name            = $subrule{'SUBRULENAME'};
        %subrule{$subrule-name}     = SUBRULE.new(
                                                    :DATATYPE($subrule{'DATATYPE'}),
                                                    :NODENAME($subrule{'NODENAME'}),
                                                    :PARENTRULENAME($subrule{'PARENTRULENAME'}),
                                                    :SUBRULENAME($subrule-name),
                                                    :TGTSRV($subrule{'TGTSRV'}),
                                      );
    }
#ddt %subrule;

    my @STGRULES                    = $dsmadmc.execute(<SELECT RULENAME,TGTSRV,TYPE,STARTTIME,MAXSESSIONS FROM STGRULES WHERE ACTIVE='YES'>);
    for @STGRULES -> $stgrule {
        my $stgrule-name            = $stgrule{'RULENAME'};
        my %subrules-of-stgrule;
        for %subrule.keys -> $subrule-name {
            %subrules-of-stgrule{$subrule-name} = %subrule{$subrule-name} if %subrule{$subrule-name}.PARENTRULENAME eq $stgrule-name;
        }
        my $hour;
        my $minute;
        my $second;
        ($hour, $minute, $second)   = $stgrule{'STARTTIME'}.split(':');
        my $start-date-time         = DateTime.new(date => Date.today, :$hour, :$minute, :$second, :timezone($dsmadmc.seconds-offset-UTC));
        %stgrule{$stgrule-name}     = STGRULE.new(
                                                    :MAXSESSIONS($stgrule<MAXSESSIONS>),
                                                    :RULENAME($stgrule-name),
                                                    :STARTTIME($start-date-time),
                                                    :subrules(%subrules-of-stgrule),
                                                    :TGTSRV($stgrule<TGTSRV>),
                                      );
    }
#ddt %stgrule;

    if $node {
        stgrule-by-node();
    }
    else {
        stgrule-by-time();    
    }
}

sub stgrule-by-time {
    my $table                       = Term::TablePrint.new(:footer('ISP Server: ' ~ $SERVER_NAME ~ '  ISP Admin: ' ~ $ADMIN_NAME), :save-screen);
    my @rows.push:                  [ 'Storage Rule', 'Sub Rule', 'Start Time', 'Sessions', 'Target Server', 'Data Type', 'Nodegroup/Node(s)' ];
    my %stgrule-by-time;
    my $i                           = 0;
    for %stgrule.keys -> $stgrule-name {
        my $key                     = %stgrule{$stgrule-name}.STARTTIME ~ '_' ~ $i++;
        %stgrule-by-time{$key}      = $stgrule-name;
    }
    for %stgrule-by-time.keys.sort -> $key {
        my $stgrule-name            = %stgrule-by-time{$key};
        for %stgrule{$stgrule-name}.subrules.keys.sort -> $subrule-name {
            @rows.push:             [
                                        $stgrule-name,
                                        $subrule-name,
                                        sprintf("%02d:%02d:%02d", %stgrule{$stgrule-name}.STARTTIME.hour, %stgrule{$stgrule-name}.STARTTIME.minute, %stgrule{$stgrule-name}.STARTTIME.second),
                                        %stgrule{$stgrule-name}.MAXSESSIONS,
                                        %stgrule{$stgrule-name}.subrules{$subrule-name}.TGTSRV,
                                        %stgrule{$stgrule-name}.subrules{$subrule-name}.DATATYPE,
                                        %stgrule{$stgrule-name}.subrules{$subrule-name}.NODENAME,
                                    ];
        }
    }
    $table.print-table(@rows, :mouse(0));
}

sub stgrule-by-node {
    die 'Unknown node: ' ~ $NODE unless %node-to-node-group{$NODE}:exists;
    my $table                       = Term::TablePrint.new(:footer('ISP Server: ' ~ $SERVER_NAME ~ '  ISP Admin: ' ~ $ADMIN_NAME ~ '  NODE: ' ~ $NODE), :save-screen);
    my @rows.push:                  [ 'Storage Rule', 'Sub Rule', 'Start Time', 'Sessions', 'Target Server', 'Data Type', 'Nodegroup/Node(s)' ];
    my @node-specifications         = $NODE;
    for %node-to-node-group{$NODE}.list -> $node-group {
        @node-specifications.push: $node-group;
    }
    for %subrule.keys.sort -> $subrule-name {
        my @nodes                   = %subrule{$subrule-name}.NODENAME.split(/\s+/);
        my $stgrule-name            = %subrule{$subrule-name}.PARENTRULENAME;
        for @nodes -> $node {
            next                    unless $node eq %node-to-node-group{$NODE}.any;
            @rows.push:             [
                                        $stgrule-name,
                                        $subrule-name,
                                        sprintf("%02d:%02d:%02d", %stgrule{$stgrule-name}.STARTTIME.hour, %stgrule{$stgrule-name}.STARTTIME.minute, %stgrule{$stgrule-name}.STARTTIME.second),
                                        %stgrule{$stgrule-name}.MAXSESSIONS,
#                                       %stgrule{$stgrule-name}.subrules{$subrule-name}.TGTSRV,
#                                       %stgrule{$stgrule-name}.subrules{$subrule-name}.DATATYPE,
#                                       %stgrule{$stgrule-name}.subrules{$subrule-name}.NODENAME,
                                        %subrule{$subrule-name}.TGTSRV,
                                        %subrule{$subrule-name}.DATATYPE,
                                        %subrule{$subrule-name}.NODENAME,
                                    ];
        }
    }
    $table.print-table(@rows, :mouse(0));
}

=finish
