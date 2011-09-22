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

my $DEBUG = 1;

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
    my $value = $mo;
    push @{ $self->{_seen}{$key} } , $value;
}


sub drain_queue {
    my ($self) = shift;
    my $output_start_column = shift;
    my $output_length       = shift;  # default to the whole line

    my @lines_to_drain;
    #OK.ORG push @lines_to_drain, $self->get_leading_array, $self->get_trailing_array;
    push @lines_to_drain, $self->get_leading_array, $self->get_trailing_array;
    my %lh;
    my $lref;
    foreach $lref ( @lines_to_drain ) {
        %lh = %$lref;
        my $ln   = $lh{line};
        my $lnum = $lh{num};
        #
        # Check for desired email addr in the current line.
        if ( $ln =~ m/$self->{match}/ ) {
            #TBD
            #TBD: if (defined $ln && ($ln =~ /$match_qid/) && ($ln ne $ltd) ) { #}
            #
            # Add line from buffer w/ matching email addr to the "seen" hash.
            #TBD: How to get the correct value into 'num', when inside drain_queue()?
            my ($match_email, $match_qid) = Sendmail::QidTrace::match_line($self->{match}, $ln);
            print "DBG.drain_email_match_found: \$lnum: ,$lnum,\n" if ($DEBUG);
            $self->add_match({match => $match_email,
                              qid   => $match_qid,
                              line  => ($output_length
                                        ? substr($ln, $output_start_column, $output_length)
                                        : substr($ln, $output_start_column)),
                              num   => $lnum });
            #
            # Check for matching qid's in the buffer.
            foreach my $ltdref ( @lines_to_drain ) {
                %lh = %$ltdref;
                my $ln_from_buf   = $lh{line};
                my $lnum_from_buf = $lh{num};
                #
                if (defined $ln_from_buf && ($ln_from_buf =~ /$match_qid/) && ($ln_from_buf ne $ln) ) {
                  #TBD: This eliminates dupes that match $match_email;
                  #  it does not eliminate dupes that only match $match_qid.
                    my ($match_email, $match_qid) = Sendmail::QidTrace::match_line($self->{match}, $ln_from_buf);

                    # If current line has the matching email addr and a matching qid,
                    # skip it to avoid adding a duplicate line in o/p.
                    # Add this line to the o/p only when it is shifted off the 
                    # leading array to check its email addr.
                    next if ($match_email eq $self->{match});

                    print "DBG.drain_buffer_match_found: \$lnum_from_buf: ,$lnum_from_buf,\n" if ($DEBUG);
                    $self->add_match({match => $match_email,
                                      qid   => $match_qid,
                                      line  => ($output_length
                                                ? substr($ln_from_buf, $output_start_column, $output_length)
                                                : substr($ln_from_buf, $output_start_column)),
                                      num   => $lnum_from_buf });
                    #TBD: Delete line from buffer.
                }
            }
            next;  # TBR?
        }
        #
        #
    }  # End foreach $lref.
} # End sub drain_queue_rev1037().



#
# Accessors to get & set the queue.
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

=begin removed

    #
    my @lines_with_addr = grep { /$self->{match}/ } @lines_to_drain;

    foreach  my $ltd ( @lines_with_addr ) {
        #TBD: How else to call match_line?
        # $self->{match} is the desired $email_address.
        my ($match_email, $match_qid) = Sendmail::QidTrace::match_line($self->{match}, $ltd);

        #TBD: How to avoid adding a line already in the %_seen hash?
          # Simple soln: Use a bigger window size, to ensure that all matching lines
          # in the buffer are in the @_leading array, & do not save seen lines
          # in the @_trailing array.
             #  Oops, that won't work.  If a line w/ a matching qid is in buffer before
             #  the line w/ the email addr w/ that qid, that preceding line will always be
             #  in @_trailing when the line w/ email addr is shifted off @_leading.
             #
        #TBD: if (defined $ln && ($ln =~ /$match_qid/) && ($ln ne $ltd) ) { #}
        #
        # Add line from buffer w/ matching email addr to the "seen" hash.
        #TBD: How to get the correct value into 'num', when inside drain_queue()?
            $self->add_match({match => $match_email,
                              qid   => $match_qid,
                              line  => ($output_length
                                        ? substr($ltd, $output_start_column, $output_length)
                                        : substr($ltd, $output_start_column)),
                              num   => $. });
            #
            # Check for matching qid's in the buffer.
            foreach my $ln ( @lines_to_drain ) { 
                if (defined $ln && ($ln =~ /$match_qid/) && ($ln ne $ltd) ) {
                  #TBD: This eliminates dupes that match $match_email;
                  #  it does not eliminate dupes that only match $match_qid.
                    my ($match_email, $match_qid) = Sendmail::QidTrace::match_line($self->{match}, $ln);

                    # If current line has the matching email addr and a matching qid,
                    # skip it to avoid adding a duplicate line in o/p.
                    # Add this line to the o/p only when it is shifted off the 
                    # leading array to check its email addr.
                    next if ($match_email eq $self->{match});

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

=end removed


=cut


1;
