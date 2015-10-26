package header;

sub print {

    my $refresh = shift;

    print '<html>
        <head>
            <title>NASDVR</title>
            <style>
                body { font-family: verdana; font-size: 10px }
                td { font-size: 10px; }
            </style>
            ';

    if (defined($refresh)) {
        print "<meta http-equiv=\"refresh\" content=\"$refresh\">";
    }

    print '</head>
        <body>
        <table cellpadding="5">
        <tr>
        <td><b>NASDVR</b></td>
        <td><a href="listings.cgi">Listings</a></td><td>|</td>
        <td><a href="grid.cgi">Grid</a></td><td>|</td>
        <td><a href="favorites.cgi">Favorites</a></td><td>|</td>
        <td><a href="search.cgi">Search</a></td><td>|</td>
        <td><a href="queue.cgi">Queue</a></td><td>|</td>
        <td><a href="recorded.cgi">Recorded</a></td><td>|</td>
        <td><a href="tuners.cgi">Tuners</a></td><td>|</td>
        <td><a href="configure.cgi">Configure</a></td><td>|</td>
        <td><a href="log.cgi">Log</a></td>
        </tr>
        </table>
        <hr style="height=1px;border-width:0px;background-color:#000000">
        <p>';
}

return 1;
