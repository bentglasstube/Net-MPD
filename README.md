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
- repeat\*
- random\*
- single\*
- consume\*
- playlist
- playlist\_length
- state
- song
- song\_id
- next\_song
- next\_song\_id
- time
- elapsed
- bitrate
- crossfade\*
- mix\_ramp\_db\*
- mix\_ramp\_delay\*
- audio
- updating\_db
- error
- replay\_gain\_mode\*

# MPD COMMANDS

The commands are mostly the same as the [MPD protocol](http://www.musicpd.org/doc/protocol/index.html) but some have been
renamed slightly.

- clear\_error
- current\_song
- idle
- stats
- next
- pause
- play
- play\_id
- previous
- seek
- seek\_id
- seek\_cur
- stop
- add
- add\_id
- clear
- delete
- delete\_id
- move
- move\_id
- playlist\_find
- playlist\_id
- playlist\_info
- playlist\_search
- playlist\_changes
- playlist\_changes\_pos\_id
- prio
- prio\_id
- shuffle
- swap
- swapid
- list\_playlist
- list\_playlist\_info
- list\_playlists
- load
- playlist\_add
- playlist\_clear
- playlist\_delete
- playlist\_move
- rename
- rm
- save
- count
- find
- find\_add
- list
- list\_all
- list\_all\_info
- ls\_info
- search
- search\_add
- search\_add\_pl
- update
- rescan
- sticker
- close
- kill
- ping
- disable\_output
- enable\_output
- outputs
- config
- commands
- not\_commands
- tag\_types
- url\_handlers
- decoders
- subscribe
- unsubscribe
- channels
- read\_messages
- send\_message

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
