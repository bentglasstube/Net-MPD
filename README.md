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

Net::MPD is designed as a lightweight replacment for [Audio::MPD](https://metacpan.org/pod/Audio::MPD) which
depends on [Moose](https://metacpan.org/pod/Moose) and is no longer maintained.

# METHODS

## connect \[$address\]

Connect to the MPD running at the given address.  Address takes the form of
password@host:port.  Both the password and port are optional.  If no password is
given, none will be used.  If no port is given, the default (6600) will be used.
If no host is given, `localhost` will be used.

If the hostname contains a "/", it will be interpretted as the path to a UNIX
socket try to connect that way instead of using TCP.

Return a Net::MPD object on success and croaks on failure.

## version

Return the API version of the connected MPD server.

## update\_status

Issue a `status` command to MPD and stores the results in the local object.
The results are also returned as a hashref.

# MPD ATTRIBUTES

Most of the "status" attributes have been written as combined getter/setter
methods.  Calling the ["update\_status"](#update_status) method will update these values.  Only
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

The commands are mostly the same as the [MPD
protocol](http://www.musicpd.org/doc/protocol/index.html) but some have been
renamed slightly.

## clear\_error

Clear the current error message in status.  This can also be done by issuing any
command that starts playback.

## current\_song

Return the song info for the current song.

## idle \[@subsystems\]

Block until a noteworth change in one or more of MPD's subsystems.  As soon as
there is one, a list of all changed subsystems will be returned.  If any
subsystems are given as arguments, only those subsystems will be monitored.  The
following subsystems are available:

- database

    The song database has been changed after an update.

- udpate

    A database update has started or finished.

- stored\_playlist

    A stored playlist has been modified.

- playlist

    The current playlist has been modified.

- player

    Playback has been started stopped or seeked.

- mixer

    The volume has been adjusted.

- output

    An audio output has been enabled or disabled.

- sticker

    The sticket database has been modified.

- subscription

    A client has subscribed or unsubscribed from a channel.

- message

    A message was received on a channel this client is watching.

## stats

Return a hashref with some stats about the database.

## next

Play the next song in the playlist.

## pause $state

Set the pause state.  Use 0 for playing and 1 for paused.

## play \[$position\]

Start playback (optionally at the given position).

## play\_id \[$id\]

Start playback (optionally with the given song).

## previous

Play the previous song in the playlist.

## seek $position $time

Seek to $time seconds in the given song position.

## seek\_id $id $time

Seek to $time seconds in the given song.

## seek\_cur $time

Seek to $time seconds in the current song.

## stop

Stop playing.

## add $path

Add the file (or directory, recursively) at $path to the current playlist.

## add\_id $path \[$position\]

Add the file at $path (optionally at $position) to the playlist and return the
id.

## clear

Clear the current playlist.

## delete $position

Remove the song(s) in the given position from the current playlist.

## delete\_id $id

Remove the song with the given id from the current playlist.

## move $from $to

Move the song from position $from to $to.

## move\_id $id $to

Move the song with the given id to position $to.

## playlist\_find $tag $search

Search the current playlist for songs with $tag exactly matching $search.

## playlist\_id $id

Return song information for the song with the given id.

## playlist\_info \[$position\]

Return song information for every song in the current playlist (or optionally
the one at the given position).

## playlist\_search $tag $search

Search the current playlist for songs with $tag partially matching $search.

## playlist\_changes $version

Return song information for songs changed since the given version of the current
playlist.

## playlist\_changes\_pos\_id $version

Return position and id information for songs changed since the given version of
the current playlist.

## prio $priority $position

Set the priority of the song at the given position.

## prio\_id $priority $id

Set the priority of the song with the given id.

## shuffle

Shuffle the current playlist.

## swap $pos1 $pos2

Swap the positions of the songs at the given positions.

## swapid $id1 $id2

Swap the positions of the songs with the given ids.

## list\_playlist $name

Return a list of all the songs in the named playlist.

## list\_playlist\_info $name

Return all the song information for the named playlist.

## list\_playlists

Return a list of the stored playlists.

## load $name

Add the named playlist to the current playlist.

## playlist\_add $name $path

Add the given path to the named playlist.

## playlist\_clear $name

Clear the named playlist.

## playlist\_delete $name $position

Remove the song at the given position from the named playlist.

## playlist\_move $name $id $pos

Move the song with the given id to the given position in the named playlist.

## rename $name $new\_name

Rename the named playlist to $new\_name.

## rm $name

Delete the named playlist.

## save $name

Save the current playlist with the given name.

## count $tag $search ...

Return a count and playtime for all items with $tag exactly matching $search.
Multiple pairs of $tag/$search parameters can be given.

## find $tag $search ...

Return song information for all items with $tag exactly matching $search.  The
special tag 'any' can be used to search all tag.  The special tag 'file' can be
used to search by path.

## find\_add $tag $search

Search as with `find` and add any matches to the current playlist.

## list $tag \[$artist\]

Return all the values for the given tag.  If the tag is 'album', an artist can
optionally be given to further limit the results.

## list\_all \[$path\]

Return a list of all the songs and directories (optionally under $path).

## list\_all\_info \[$path\]

Return a list of all the songs as with `listall` but include metadata.

## search $tag $search ...

As `find` but with partial, case-insensitive searching.

## search\_add $tag $search ...

As `search` but adds the results to the current playlist.

## search\_add\_pl $name $tag $search ...

As `search` but adds the results the named playlist.

## update \[$path\]

Update the database (optionally under $path) and return a job id.

## rescan \[$path\]

As &lt;update> but forces rescan of unmodified files.

## sticker\_value $type $path $name \[$value\]

Return the sticker value for the given item after optionally setting it to
$value.  Use an undefined value to delete the sticker.

## sticker\_list $type $path

Return a hashref of the stickers for the given item.

## sticker\_find $type $name \[$path\]

Return a list of all the items (optionally under $path) with a sticker of the given name.

## close

Close the connection.  This is pretty worthless as the library will just
reconnect for the next command.

## kill

Kill the MPD server.

## ping

Do nothing.  This can be used to keep an idle connection open.  If you want to
wait for noteworthy events, the `idle` command is better suited.

## disable\_output $id

Disable the given output.

## enable\_output $id

Enable the given output.

## outputs

Return a list of the available outputs.

## commands

Return a list of the available commands.

## not\_commands

Return a list of the unavailable commands.

## tag\_types

Return a list of all the avalable song metadata.

## url\_handlers

Return a list of available url handlers.

## decoders

Return a list of available decoder plugins, along with the MIME types and file
extensions associated with them.

## subscribe $channel

Subscribe to the named channel.

## unsubscribe $channel

Unsubscribe from the named channel.

## channels

Return a list of the channels with active clients.

## read\_messages

Return a list of any available messages for this clients subscribed channels.

## send\_message $channel $message

Send a message to the given channel.

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

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

# SEE ALSO

[Audio::MPD](https://metacpan.org/pod/Audio::MPD), [MPD Protocol](http://www.musicpd.org/doc/protocol/index.html)
