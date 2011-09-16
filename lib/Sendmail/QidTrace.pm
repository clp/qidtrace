#! /usr/bin/env perl

package Sendmail::QidTrace;

use strict;
use warnings;

use Exporter ();

our @ISA       = qw/Exporter/;
our @EXPORT_OK = qw/match_line/;

# given an email address, and a sendmail log line,
#  return a pair ($email, $qid) from the line where:
#   the email matches if it is found any where in the line.
#   the qid is extracted from several common log lines that have been found with qids
# if either field is not found '' is returned in its place.

# Return the email addr if it matches the desired email addr; else return ''.
# TBD: Return $qid if it matches any qid that is already saved in the queue.
#
sub match_line {
    my $email = shift;
    my $line = shift;
    my $qid;
    return('', '') unless $line;
    if ( $line !~ m/<$email>/ ) { $email = ''}
    if ( $line =~ m/.*:? ([a-zA-Z\d]{14}).? ?.*/ ){
      $qid = $1;
      #TBD-Maybe: Look for a match between $qid and all qid's in the saved queue,
      # and return it if found; else return ''.
      # OR, should this code return $qid if any qid found,
      # and the compare operation be done in the caller,
      # qidtrace, which has the queue in $qt?
    }
    else {
      $qid = '';
    }
    return($email, $qid);
}




package Sendmail::QidTrace::Queue;

use strict;

sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;

    my $queue = { _leading  => [],  # winsize matching lines before
                  _trailing => [],  #                        and after
                  _seen     => {},  # track which lines we have already emitted
    };
    my $args = shift || {};
    while (my ($k, $v) = each(%$args)) {
        $queue->{$k} = $v;
    }
    return bless $queue, $class;
}

#
# expects a ref to a hash containing the canonical form for a matched line:
#  match => the match string, in this case, an email.  possibly the empty string.
#  qid   => the qid.  should not normally be the empty string, but could be.
#  line  => the log line, sans newlines
#  num   => the line number of the log line
#
sub add_match {
    my ($self, $mo) = @_;
    #TBD: Verify i/p is OK.
      # If not, print error & exit or return.
    #
    # Add the line to save to the _seen hash.
    # Store array of refs to lines for each key=qid.
    my $key = "$mo->{qid}"  ;
    my $value = "$mo->{line}"  ;
    push @{ $self->{_seen}{$key} } , $value;

}

#
# drain the window of all remaining matches.
#  should be called after the end of the input stream
#  to flush out the queue.
sub drain_queue {
    my ($self) = shift;
    my $output_start_column = shift;
    my $output_length       = shift;  # default to the whole line
    my $rsqa                = shift;
    my $rsqh                = shift;
    my @saved_qids          = @$rsqa;
    my %seen_qids           = %$rsqh;

    my @lines_to_drain;
    push @lines_to_drain, $self->get_leading_array, $self->get_trailing_array;

    foreach  my $ltd ( @lines_to_drain ) {
        #TBD: How else to call match_line?
        # $self->{match} is the desired $email_address.
        my ($match_email, $match_qid) = Sendmail::QidTrace::match_line($self->{match}, $ltd);
        #OK.ORG if ($match_email || ( grep {m/$match_qid/}  $self->get_seen_qids )) { #}
        if ($match_email || ( grep {m/$match_qid/}  @saved_qids )) {
            $self->add_match({match => $match_email,
                              qid   => $match_qid,
                              line  => ($output_length
                                        ? substr($ltd, $output_start_column, $output_length)
                                        : substr($ltd, $output_start_column)),
                              num   => $. });
            #TBR? push (@saved_qids, $match_qid) unless ( $seen_qids{$match_qid}++ );
              # This line not needed here?
            #TBR: next;
              # This line not needed here?

        }
    }
    # return $self;
} # End sub drain_queue().


#
# Accessors to control the queue.
sub push_onto_leading_array {
    my $self = shift;
    my $line = shift;
    push @{ $self->{_leading} }, $line;
}
sub push_onto_trailing_array {
    my $self = shift;
    my $line = shift;
    push @{ $self->{_trailing} }, $line;
}

sub shift_off_leading_array {
    my $self = shift;
    return shift @{ $self->{_leading} };
}

sub shift_off_trailing_array {
    my $self = shift;
    return shift @{ $self->{_trailing} };
}

sub get_leading_array {
    my $self = shift;
    return @{ $self->{_leading} };
}

sub get_trailing_array {
    my $self = shift;
    return @{ $self->{_trailing} };
}

sub size_of_leading_array {
    my $self = shift;
    return scalar @{ $self->{_leading} };
}

sub size_of_trailing_array {
    my $self = shift;
    return scalar @{ $self->{_trailing} };
}

sub get_seen_qids {
    my $self = shift;
    return keys %{ $self->{_seen} };
}

sub get_seen_hash {
    my $self = shift;
    return  $self->{_seen} ;
}

1;
