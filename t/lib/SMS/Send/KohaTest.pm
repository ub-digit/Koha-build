package SMS::Send::KohaTest;

=pod

=head1 NAME

SMS::Send::KohaTest - SMS::Sent Testing Driver for C4::SMS tests

=head1 SYNOPSIS

  my $send = SMS::Send->new( 'KohaTest' )
  $message = $send->send_sms(
      text => 'Hi there',
      to   => '+61 (4) 1234 5678',
  )

=head1 DESCRIPTION

When writing tests for L<C4::SMS> we are unable to trap messages using the
L<SMS::Send::Test> driver since the L<SMS::Send> instance cannot be accessed
directly. We do however have access to the return value of the driver's
send_sms method, so by returning the incoming arguments here we are able
verify these have been set correctly.

=cut

use 5.006;
use strict;
use parent 'SMS::Send::Driver';

sub new {
    my $class = shift;
    my $self = bless {
    }, $class;
    $self;
}

sub send_sms {
    # Shift $self
    shift;
    use Data::Dumper;
    # Return arguments
    return { @_ };
}
1;
