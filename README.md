# NAME

Net::MPD - Communicate with an MPD server

# SYNOPSIS

    use Net::MPD;

    my $mpd = Net::MPD->connect();

    $mpd->stop();
    $mpd->clear();
    $mpd->search_add(Artist => 'David Bowie');
    $mpd->shuffle();
    $mpd->play();
    $mpd->next();

    while (1) {
      my @changes = $mpd->idle();
      print 'Changed: ' . join(', ', @changes) . "\n";
    }

# DESCRIPTION

Net::MPD is designed as a lightweight replacment for [Audio::MPD](http://search.cpan.org/perldoc?Audio::MPD) which
depends on [Moose](http://search.cpan.org/perldoc?Moose) and is no longer maintained.

# METHODS

## connect

- Arguments: \[$address\]

Connects to the MPD running at the given address.  Address takes the form of
password@host:port.  Both the password and port are optional.  If no password
is given, none will be used.  If no port is given, the default (6600) will be
used.  If no host is given, `localhost` will be used.

Returns a Net::MPD object on success and croaks on failure.

## version

Returns the API version of the connected MPD server.

## update\_status

Issues a `status` command to MPD and stores the results in the local object.
The results are also returned as a hashref.

# MPD ATTRIBUTES

Most of the "status" attributes have been written as combined getter/setter
methods.  Calling the ["update\_status"](#update\_status) method will update these values.  Only
the items marked with an asterisk are writable.

- volume\*
=item repeat\*
=item random\*
=item single\*
=item consume\*
=item playlist
=item playlist\_length
=item state
=item song
=item song\_id
=item next\_song
=item next\_song\_id
=item time
=item elapsed
=item bitrate
=item crossfade\*
=item mix\_ramp\_db\*
=item mix\_ramp\_delay\*
=item audio
=item updating\_db
=item error
=item replay\_gain\_mode\*

# MPD COMMANDS

The commands are mostly the same as the [MPD protocol](http://www.musicpd.org/doc/protocol/index.html) but some have been
renamed slightly.

- clear\_error
=item current\_song
=item idle
=item stats
=item next
=item pause
=item play
=item play\_id
=item previous
=item seek
=item seek\_id
=item seek\_cur
=item stop
=item add
=item add\_id
=item clear
=item delete
=item delete\_id
=item move
=item move\_id
=item playlist\_find
=item playlist\_id
=item playlist\_info
=item playlist\_search
=item plchanges
=item plchangesposid
=item prio
=item prio\_id
=item shuffle
=item swap
=item swapid
=item list\_playlist
=item list\_playlist\_info
=item list\_playlists
=item load
=item playlist\_add
=item playlist\_clear
=item playlist\_delete
=item playlist\_move
=item rename
=item rm
=item save
=item count
=item find
=item find\_add
=item list
=item list\_all
=item list\_all\_info
=item ls\_info
=item search
=item search\_add
=item search\_add\_pl
=item update
=item rescan
=item sticker
=item close
=item kill
=item ping
=item disable\_output
=item enable\_output
=item outputs
=item config
=item commands
=item not\_commands
=item tag\_types
=item url\_handlers
=item decoders
=item subscribe
=item unsubscribe
=item channels
=item read\_messages
=item send\_message

# TODO

## Command Lists

MPD supports sending batches of commands but that is not yet available with this API.

## Asynchronous IO

Event-based handling of the idle command would make this module more robust.

# BUGS

## Idle connections

MPD will close the connection if left idle for too long.  This module will
reconnect if it senses that this has occurred, but the first call after a
disconnect will fail and have to be retried.  Calling the `ping` command
periodically will keep the connection open if you do not have any real commands
to issue.  Calling the `idle` command will block until something interesting
happens.

## Reporting

Report any issues on [GitHub](https://github.com/bentglasstube/Net-MPD/issues)

# AUTHOR

Alan Berndt <alan@eatabrick.org>

# COPYRIGHT

Copyright 2013 Alan Berndt

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Audio::MPD](http://search.cpan.org/perldoc?Audio::MPD), [MPD Protocol](http://www.musicpd.org/doc/protocol/index.html)
