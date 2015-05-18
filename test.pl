#!/usr/bin/perl -w
use strict;
use lib "lib";
use SocketAutomation;


my $objTelnet = SocketAutomation -> new('192.168.1.95', 23, \&mydbg);

# wait "login" from remote host
if ($objTelnet->wait_from_socket('login')) {
	
	$objTelnet->send_to_socket("someusername\n");# send login to remote host
	$objTelnet->wait_from_socket('password'); #wait "password" from remote host
	$objTelnet->send_to_socket("somepassword\n");# send password
	
	print $objTelnet->recieve_from_socket(2);   # receiveing data from remote host within 3 seconds, print received data
	$objTelnet->send_to_socket("show interfaces\n"); # send command "show interfaces" to remote host
	print $objTelnet->recieve_from_socket(5);   # read and print result

};

sub mydbg {
	my $val;
	$val =$_[0]; 
	print "Level: " . $_[1] . ' ';
	print "Another debug: $val\n";
}
