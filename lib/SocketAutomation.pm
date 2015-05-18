package SocketAutomation;
BEGIN
{
	use Exporter();
	use Socket;
	use IO::Select;
	use IO::Socket::INET;
	@ISA = qw(Exporter);
	@EXPORT_OK = qw(&new &send_to_socket &wait_from_socket &recieve_from_socket);
}


sub new {
	my $class = $_[0];
	my $self = {};

	$self->{socket} = undef;
	$self->{socket_handled} = undef;
	$self->{remote_host} = undef;
	$self->{remote_port} = undef;
	$self->{debug_function} = undef;
	$self->{use_internal_debug} = undef;
	$self->{time_to_wait} = 3;

	bless($self, $class);		

	if (defined $_[1]) {
		$self->{remote_host} = $_[1];
	} else {
		$self->{remote_host} = 'localhost';
	};

	if (defined $_[2]) {
		$self->{remote_port} = $_[2];
	} else {
		$self->{remote_port} = 23;
	};
	
	if (defined $_[3]) {
		$self->{debug_function} = $_[3];
		$self->{use_internal_debug} = 0;
	} else {
		$self->{use_internal_debug} = 1;
	};

	$self->_connect();

	return $self;
}


sub _debug {
	my $self = $_[0];
	my $dbg_ref;
	if (defined $_[1]) {
		if ($self->{use_internal_debug} == 1) {
			print $_[1]. "\n";			
		} else {
			$dbg_ref = $self->{debug_function};
			&$dbg_ref($_[1], $_[2]);
		};
	};
};

sub _connect {
	my $self = $_[0];
	$self->_debug('SocketAutomation::_connect: Trying to connect to '
						 . $self->{remote_host} 
						 . ':' 
						 . $self->{remote_port}, 7);

	$self->{socket} = IO::Socket::INET->new(PeerAddr=>$self->{remote_host}, 
								PeerPort => $self->{remote_port},
								Proto => 'tcp',
								Timeout => 50,
								Type => SOCK_STREAM,
								Blocking => 0) 
	or die($self->_debug('SocketAutomation::_connect: Couldn\'t connect to '
						 . $self->{remote_host} 
						 . ':' 
						 . $self->{remote_port} 
						 . " beacause\n".$!, 3));

	$self->_debug('SocketAutomation::_connect: Connected to '
						 . $self->{remote_host} 
						 . ':' 
						 . $self->{remote_port}, 7);

	$self->{socket}->autoflush(1);
	$self->{socket_handled} = IO::Select->new($self->{socket});
}

sub send_to_socket {
	# Send string to remote host 
	my $self = $_[0];
	my $message = '';
	my $sock = $self->{socket};

	if (defined $_[1]) {
		$message = $_[1];
	};

	if ($self->{socket}) {
		print $sock $message;
	};
}

sub wait_from_socket {
	# Wait given string from remote host.
	# arg 1 - pattern to wait
	# arg 2 - waiting time

	my $self = $_[0];
	my $pattern = '';
	my $start_time = time();
	my $char;
	my $message ='';
	my $is_succes = 1;
	my $readable_sockets;

	if (defined $_[1]) {
		$pattern =  $_[1];
	};
	
	if (defined $_[2]) {
		$self->{time_to_wait} =  $_[2];
	};

	while (($message !~ /$pattern/) ) {
		
		$readable_sockets = $self->{socket_handled}->can_read(0);
		if (scalar ($readable_sockets)) {
			while (defined read( $self->{socket}, $char, 1)  ) {
				if ($char) {
					$message = $message . $char;
				};
			};
		};
			
		if ( (time()-$start_time) > $self->{time_to_wait} ) {
			$is_succes = 0;
			$self->_debug("SocketAutomation::telnet_wait: Couldn't find pattern $pattern for " .
				      $self->{time_to_wait} .' sec.', 7);
			last;
		};
		
	};
	
	if ($is_succes == 1) {
		return $message; 
	};
}

sub recieve_from_socket {
	# Recieving data from remote host in the course of given time
	my $self = $_[0];
	my $start_time = time();
	my $char = '';
	my $message ='';
	my $readable_sockets;
	if (defined $_[1]) {
		$self->{time_to_wait} =  $_[1];
	};

	while ( (time() - $start_time) <= $self->{time_to_wait} ) {
		
		$readable_sockets = $self->{socket_handled}->can_read(0);
		if (scalar ($readable_sockets)) {
			while (defined read( $self->{socket}, $char, 1)  ) {
				if ($char) {
					$message = $message . $char;
				};
			};
		};
		
	};

	return $message;	
}

sub DESTROY {
	my $self = $_[0];
	if ($socket) {
		$self->_debug("TelnetUtil::DESTROY: Disconnecting", 7);
		close($socket);
	}
}


return 1;

END { }
