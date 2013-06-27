package Net::MPD;

use strict;
use warnings;
use version 0.77;

use Carp;
use IO::Socket::INET;
use Net::MPD::Response;
use Scalar::Util qw'looks_like_number';

use 5.010;

our $VERSION = '0.01';

=encoding utf-8

=head1 NAME

Net::MPD - Communicate with an MPD server

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Net::MPD is designed as a lightweight replacment for L<Audio::MPD> which
depends on L<Moose> and is no longer maintained.

=cut

sub _connect {
  my ($self) = @_;

  my $socket = IO::Socket::INET->new(
    PeerHost => $self->{hostname},
    PeerPort => $self->{port},
    Proto    => 'tcp',
  ) or croak "Unable to connect to $self->{hostname}:$self->{port}";
  binmode $socket, ':utf8';

  my $versionline = $socket->getline;
  my ($version) = ($versionline =~ /^OK MPD (\d+\.\d+\.\d+)$/);

  croak "Connection not to MPD" unless $version;

  $self->{socket} = $socket;
  $self->{version} = qv($version);

  if ($self->{password}) {
    my $result = $self->_send('password', $self->{password});
    croak $result->message if $result->is_error;
  }

  $self->update_status();
}

sub _send {
  my ($self, $command, @args) = @_;

  my $string = "$command";
  foreach my $arg (@args) {
    if ($arg =~ /[\s"]/) {
      $arg =~ s/"/\\"/g;
      $string .= qq{ "$arg"};
    } else {
      $string .= qq{ $arg};
    }
  }
  $string .= "\n";

  # auto reconnect
  $self->_connect() if not $self->{socket}->connected;

  $self->{socket}->print($string);

  my @lines = ();

  while (1) {
    my $line = $self->{socket}->getline;
    croak "Error reading line from socket" if not defined $line;
    chomp $line;

    if ($line =~ /^OK$|^ACK /) {
      return Net::MPD::Response->new($line, @lines);
    } else {
      push @lines, $line;
    }
  }
}

sub _require {
  my ($self, $version) = @_;
  $version = qv($version);
  croak "Requires MPD version $version" if $version > $self->version;
}

sub _inject {
  my ($class, $name, $sub) = @_;
  no strict 'refs';
  *{"${class}::$name"} = $sub;
}

sub _attribute {
  my ($class, $name, %options) = @_;

  (my $normal_name = $name) =~ s/_//g;

  $options{key}       //= $normal_name;
  $options{command}   //= $normal_name;
  $options{version}   //= 0;

  my $getter = sub {
    my ($self) = @_;
    $self->_require($options{version});
    return $self->{status}{$options{key}};
  };

  my $setter = sub {
    my ($self, $value) = @_;

    $self->_require($options{version});

    my $result = $self->_send($options{command}, $value);
    if ($result->is_error) {
      carp $result->message;
    } else {
      $self->{status}{$options{key}} = $value;
    }

    return $getter->(@_);
  };

  $class->_inject($name => sub {
    if ($options{readonly} or @_ == 1) {
      return $getter->(@_);
    } else {
      return $setter->(@_);
    }
  });
}

sub _command {
  my ($class, $name, %options) = @_;

  (my $normal_name = $name) =~ s/_//g;

  $options{command} //= $normal_name;
  $options{args}    //= [];

  $class->_inject($name => sub {
    my $self = shift;
    my $result = $self->_send($options{command}, @_);
    if ($result->is_error) {
      carp $result->message;
      return undef;
    } else {
      my @items = ();
      my $item = {};
      foreach my $line ($result->lines) {
        my ($key, $value) = split /: /, $line, 2;
        if (exists $item->{$key}) {
          push @items, 2 > keys %$item ? values %$item : $item;
          $item = {};
        }
        $item->{$key} = $value;
      }

      push @items, 2 > keys %$item ? values %$item : $item;

      return 2 > @items ? $items[0] : @items;
    }
  });
}

=head1 METHODS

=head2 connect

=over 4

=item Arguments: [$address]

=back

Connects to the MPD running at the given address.  Address takes the form of
password@host:port.  Both the password and port are optional.  If no password
is given, none will be used.  If no port is given, the default (6600) will be
used.  If no host is given, C<localhost> will be used.

Returns a Net::MPD object on success and croaks on failure.

=cut

sub connect {
  my ($class, $address) = @_;

  $address ||= 'localhost';

  my ($pass, $host, $port) = ($address =~ /(?:([^@]+)@)?([^:]+)(?::(\d+))?/);

  $port ||= 6600;

  my $self = bless {
    hostname => $host,
    port     => $port,
    password => $pass,
  }, $class;

  $self->_connect;

  return $self;
}

=head2 version

Returns the API version of the connected MPD server.

=cut

sub version {
  my $self = shift;
  return $self->{version};
}

=head2 update_status

Issues a C<status> command to MPD and stores the results in the local object.
The results are also returned as a hashref.

=cut

sub update_status {
  my ($self) = @_;
  my $result = $self->_send('status');
  if ($result->is_error) {
    warn $result->message;
  } else {
    $self->{status} = $result->make_hash;
  }
}

=head1 MPD ATTRIBUTES

Most of the "status" attributes have been written as combined getter/setter
methods.  Calling the L</update_status> method will update these values.  Only
the items marked with an asterisk are writable.

=over 4

=item volume*

=item repeat*

=item random*

=item single*

=item consume*

=item playlist

=item playlist_length

=item state

=item song

=item song_id

=item next_song

=item next_song_id

=item time

=item elapsed

=item bitrate

=item crossfade*

=item mix_ramp_db*

=item mix_ramp_delay*

=item audio

=item updating_db

=item error

=item replay_gain_mode*

=back

=cut

__PACKAGE__->_attribute('volume', command => 'setvol');
__PACKAGE__->_attribute('repeat');
__PACKAGE__->_attribute('random');
__PACKAGE__->_attribute('single', version => 0.15);
__PACKAGE__->_attribute('consume', version => 0.15);
__PACKAGE__->_attribute('playlist', readonly => 1);
__PACKAGE__->_attribute('playlist_length', readonly => 1);
__PACKAGE__->_attribute('state', readonly => 1);
__PACKAGE__->_attribute('song', readonly => 1);
__PACKAGE__->_attribute('song_id', readonly => 1);
__PACKAGE__->_attribute('next_song', readonly => 1);
__PACKAGE__->_attribute('next_song_id', readonly => 1);
__PACKAGE__->_attribute('time', readonly => 1);
__PACKAGE__->_attribute('elapsed', readonly => 1, version => 0.16);
__PACKAGE__->_attribute('bitrate', readonly => 1);
__PACKAGE__->_attribute('crossfade', key => 'xfade');
__PACKAGE__->_attribute('mix_ramp_db');
__PACKAGE__->_attribute('mix_ramp_delay');
__PACKAGE__->_attribute('audio', readonly => 1);
__PACKAGE__->_attribute('updating_db', key => 'updating_db', readonly => 1);
__PACKAGE__->_attribute('error', readonly => 1);

sub replay_gain_mode {
  my $self = shift;

  if (@_) {
    my $result = $self->_send('replay_gain_mode', @_);
    carp $result->message if $result->is_error;
  }

  my $result = $self->_send('replay_gain_status');
  if ($result->is_error) {
    carp $result->message;
    return undef;
  } else {
    return $result->make_hash->{replay_gain_mode};
  }
}

=head1 MPD COMMANDS

The commands are mostly the same as the L<MPD
protocol|http://www.musicpd.org/doc/protocol/index.html> but some have been
renamed slightly.

=over 4

=item clear_error

=item current_song

=item idle

=item stats

=item next

=item pause

=item play

=item play_id

=item previous

=item seek

=item seek_id

=item seek_cur

=item stop

=item add

=item add_id

=item clear

=item delete

=item delete_id

=item move

=item move_id

=item playlist_find

=item playlist_id

=item playlist_info

=item playlist_search

=item playlist_changes

=item playlist_changes_pos_id

=item prio

=item prio_id

=item shuffle

=item swap

=item swapid

=item list_playlist

=item list_playlist_info

=item list_playlists

=item load

=item playlist_add

=item playlist_clear

=item playlist_delete

=item playlist_move

=item rename

=item rm

=item save

=item count

=item find

=item find_add

=item list

=item list_all

=item list_all_info

=item ls_info

=item search

=item search_add

=item search_add_pl

=item update

=item rescan

=item sticker

=item close

=item kill

=item ping

=item disable_output

=item enable_output

=item outputs

=item config

=item commands

=item not_commands

=item tag_types

=item url_handlers

=item decoders

=item subscribe

=item unsubscribe

=item channels

=item read_messages

=item send_message

=back

=cut

__PACKAGE__->_command('clear_error');
__PACKAGE__->_command('current_song');
__PACKAGE__->_command('idle');
__PACKAGE__->_command('stats');
__PACKAGE__->_command('next');
__PACKAGE__->_command('pause');
__PACKAGE__->_command('play');
__PACKAGE__->_command('play_id');
__PACKAGE__->_command('previous');
__PACKAGE__->_command('seek');
__PACKAGE__->_command('seek_id');
__PACKAGE__->_command('seek_cur');
__PACKAGE__->_command('stop');
__PACKAGE__->_command('add');
__PACKAGE__->_command('add_id');
__PACKAGE__->_command('clear');
__PACKAGE__->_command('delete');
__PACKAGE__->_command('delete_id');
__PACKAGE__->_command('move');
__PACKAGE__->_command('move_id');
__PACKAGE__->_command('playlist_find');
__PACKAGE__->_command('playlist_id');
__PACKAGE__->_command('playlist_info');
__PACKAGE__->_command('playlist_search');
__PACKAGE__->_command('playlist_changes', command => 'plchanges');
__PACKAGE__->_command('playlist_changes_pos_id', command => 'plchangesposid');
__PACKAGE__->_command('prio');
__PACKAGE__->_command('prio_id');
__PACKAGE__->_command('shuffle');
__PACKAGE__->_command('swap');
__PACKAGE__->_command('swapid');
__PACKAGE__->_command('list_playlist');
__PACKAGE__->_command('list_playlist_info');
__PACKAGE__->_command('list_playlists');
__PACKAGE__->_command('load');
__PACKAGE__->_command('playlist_add');
__PACKAGE__->_command('playlist_clear');
__PACKAGE__->_command('playlist_delete');
__PACKAGE__->_command('playlist_move');
__PACKAGE__->_command('rename');
__PACKAGE__->_command('rm');
__PACKAGE__->_command('save');
__PACKAGE__->_command('count');
__PACKAGE__->_command('find');
__PACKAGE__->_command('find_add');
__PACKAGE__->_command('list');
__PACKAGE__->_command('list_all');
__PACKAGE__->_command('list_all_info');
__PACKAGE__->_command('ls_info');
__PACKAGE__->_command('search');
__PACKAGE__->_command('search_add');
__PACKAGE__->_command('search_add_pl');
__PACKAGE__->_command('update');
__PACKAGE__->_command('rescan');
__PACKAGE__->_command('sticker');
__PACKAGE__->_command('close');
__PACKAGE__->_command('kill');
__PACKAGE__->_command('ping');
__PACKAGE__->_command('disable_output');
__PACKAGE__->_command('enable_output');
__PACKAGE__->_command('outputs');
__PACKAGE__->_command('config');
__PACKAGE__->_command('commands');
__PACKAGE__->_command('not_commands');
__PACKAGE__->_command('tag_types');
__PACKAGE__->_command('url_handlers');
__PACKAGE__->_command('decoders');
__PACKAGE__->_command('subscribe');
__PACKAGE__->_command('unsubscribe');
__PACKAGE__->_command('channels');
__PACKAGE__->_command('read_messages');
__PACKAGE__->_command('send_message');

1;

=head1 TODO

=head2 Command Lists

MPD supports sending batches of commands but that is not yet available with this API.

=head2 Asynchronous IO

Event-based handling of the idle command would make this module more robust.

=head1 BUGS

=head2 Idle connections

MPD will close the connection if left idle for too long.  This module will
reconnect if it senses that this has occurred, but the first call after a
disconnect will fail and have to be retried.  Calling the C<ping> command
periodically will keep the connection open if you do not have any real commands
to issue.  Calling the C<idle> command will block until something interesting
happens.

=head2 Reporting

Report any issues on L<GitHub|https://github.com/bentglasstube/Net-MPD/issues>

=head1 AUTHOR

Alan Berndt E<lt>alan@eatabrick.orgE<gt>

=head1 COPYRIGHT

Copyright 2013 Alan Berndt

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Audio::MPD>, L<MPD Protocol|http://www.musicpd.org/doc/protocol/index.html>

=cut
