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
    #TBD: Maybe push @{ $self->{_seen}{$key} } , $mo;
      # to have all 4 values avbl when needed, instead of just line.
    #DBG push @{ $self->{_seen}{num} } , $mo->{num};
}


#
#TBD: Rev Sun2011_0918_10:37 : grep for all matching addrs first; then check for matching qid's.
# drain the window of all remaining matches.
#  should be called after the end of the input stream
#  to flush out the queue.
sub drain_queue_1037 {
    my ($self) = shift;
    my $output_start_column = shift;
    my $output_length       = shift;  # default to the whole line
    my $rsqa                = shift;
    my $rsqh                = shift;
    my @saved_qids          = @$rsqa;
    my %seen_qids           = %$rsqh;

    my @lines_to_drain;
    push @lines_to_drain, $self->get_leading_array, $self->get_trailing_array;
    my @lines_with_addr = grep { /$self->{match}/ } @lines_to_drain;

    foreach  my $ltd ( @lines_with_addr ) {
        #TBD: How else to call match_line?
        # $self->{match} is the desired $email_address.
        my ($match_email, $match_qid) = Sendmail::QidTrace::match_line($self->{match}, $ltd);

        #TBD: How to avoid adding a line already in the %_seen hash?
          # Simple soln: Use a bigger window size, to ensure that all matching lines
          # in the buffer are in the @_leading array, & do not save seen lines
          # in the @_trailing array.
        #TBD: if (defined $ln && ($ln =~ /$match_qid/) && ($ln ne $ltd) ) { #}
        #
        # Add line from buffer w/ matching email addr to the "seen" hash.
            $self->add_match({match => $match_email,
                              qid   => $match_qid,
                              line  => ($output_length
                                        ? substr($ltd, $output_start_column, $output_length)
                                        : substr($ltd, $output_start_column)),
                              num   => $. });
            #
            # Check for matching qid's in the buffer.
            foreach my $ln ( @lines_to_drain ) { 
                if (defined $ln && ($ln =~ /$match_qid/) && ($ln ne $ltd) ) { #}
                #OK.dupes  if (defined $ln && ($ln =~ /$match_qid/) ) { #}
                  #TBD: This eliminates dupes that match $match_email;
                  #  it does not eliminate dupes that only match $match_qid.
                    my ($match_email, $match_qid) = Sendmail::QidTrace::match_line($self->{match}, $ln);
                    $self->add_match({match => $match_email,
                                      qid   => $match_qid,
                                      line  => ($output_length
                                                ? substr($ln, $output_start_column, $output_length)
                                                : substr($ln, $output_start_column)),
                                      num   => $. });
                    #TBD: Delete line from buffer.
                }
            }
            next;  # TBR?
    }
} # End sub drain_queue_rev1037().



#
#TBD: Rev Sun2011_0918_11:15  : grep for all matching addrs first; then check for matching qid's; print group when found, to debug problem of invalid data being saved as a match.
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
    my @lines_with_addr = grep { /$self->{match}/ } @lines_to_drain;

    foreach  my $ltd ( @lines_with_addr ) {
        #TBD: How else to call match_line?
        # $self->{match} is the desired $email_address.
        my ($match_email, $match_qid) = Sendmail::QidTrace::match_line($self->{match}, $ltd);

            # Print the line w/ matching email addr.
            print "__DRAIN.1__: ", $ltd, "\n";
            # Check for matching qid's in the buffer.
            foreach my $ln ( @lines_to_drain ) { 
                if (defined $ln && ($ln =~ /$match_qid/) && ($ln ne $ltd) ) { 
                #F  if (defined $ln && ($ln =~ /$match_qid/)  ) { 
                    print "__DRAIN.2__: ", $ln, "\n";
                }
            }
            #TMP next;  # TBR?
    }
} # End sub drain_queue_1115().



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
