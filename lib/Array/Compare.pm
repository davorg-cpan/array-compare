#
# $Id$
#

=head1 NAME

Array::Compare - Perl extension for comparing arrays.

=head1 SYNOPSIS

  use Array::Compare;

  my $comp1 = Array::Compare->new;
  $comp->Sep('|');
  $comp->Skip({3 => 1, 4 => 1});
  $comp->WhiteSpace(0);
  $comp->Case(1);

  my $comp2 = Array::Compare->new(Sep => '|',
                                  WhiteSpace => 0,
                                  Case => 1,
                                  Skip => {3 => 1, 4 => 1});

  my @arr1 = 0 .. 10;
  my @arr2 = 0 .. 10;

  $comp1->compare(\@arr1, \@arr2);
  $comp2->compare(\@arr1, \@arr2);

=head1 DESCRIPTION

If you have two arrays and you want to know if they are the same or
different, then Array::Compare will be useful to you.

All comparisons are carried out via a comparator object. In the
simplest usage, you can create and use a comparator object like
this:

  my @arr1 = 0 .. 10;
  my @arr2 = 0 .. 10;

  my $comp = Array::Compare->new;

  if ($comp->compare(\@arr1, \@arr2)) {
    print "Arrays are the same\n";
  } else {
    print "Arrays are different\n";
  }

Notice that you pass references to the two arrays to the comparison
method.

Internally the comparator compares the two arrays by using C<join>
to turn both arrays into strings and comparing the strings using
C<eq>. In the joined strings, the elements of the original arrays
are separated with the C<^G> character. This can cause problems if
your array data contains C<^G> characters as it is possible that
two different arrays can be converted to the same string.

To avoid this, it is possible to override the default separator
character, either by passing an alternative to the C<new> function

  my $comp = Array::Compare->new(Sep => '|');

or by changing the separator for an existing comparator object

  $comp->Sep('|');

In general you should choose a separator character that won't appear
in your data.

You can also control whether or not whitespace within the elements of
the arrays should be considered significant when making the comparison.
The default is that all whitespace is significant. The alternative is
for all consecutive white space characters to be converted to a single
space for the purposes of the comparison. Again, this can be turned on
when creating a comparator object:

  my $comp = Array::Compare->new(WhiteSpace => 0);

or by altering an existing object:

  $comp->WhiteSpace(0);

You can also control whether or not the case of the data is significant
in the comparison. The default is that the case of data is taken into
account. This can be changed in the standard ways when creating a new
comparator object:

  my $comp = Array::Compare->new(Case => 0);

or by altering an existing object:

  $comp->Case(0);

In addition to the simple comparison described above (which returns true
if the arrays are the same and false if they're different) there is also
a full comparison which returns a list containing the indexes of elements
which differ between the two arrays. If the arrays are the same it returns
an empty list. In scalar context the full comparison returns the length of
this list (i.e. the number of elements that differ). You can access the full
comparison in two ways. Firstly, there is a C<DefFull> attribute. If this
is C<true> then a full comparison is carried out whenever the C<compare>
method is called.

  my $comp = Array::Compare->new(DefFull => 1);
  $comp->compare(\@arr1, \@arr2); # Full comparison

  $comp->DefFull(0);
  $comp->compare(\@arr1, \@arr2); # Simple comparison

  $comp->DefFull(1);
  $comp->compare(\@arr1, \@arr2); # Full comparison again


Secondly, you can access the full comparison method directly

  $comp->full_compare(\@arr1, \@arr2);

For symmetry, there is also a direct method to use to call the simple
comparison.

  $comp->simple_compare(\@arr1, \@arr2);

The final complication is the ability to skip elements in the comparison.
If you know that two arrays will always differ in a particular element
but want to compare the arrays I<ignoring> this element, you can do it
with Array::Compare without taking array slices. To do this, a
comparator object has an optional attribute called C<Skip> which is a
reference to a hash. The keys in this hash are the indexes of the array
elements and the values should be any true value for elements that should
be skipped.

For example, if you want to compare two arrays, ignoring the values in
elements two and four, you can do something like this:

  my %skip = (2 => 1, 4 => 1);
  my @a = (0, 1, 2, 3, 4, 5);
  my @b = (0, 1, X, 3, X, 5);

  my $comp = Array::Compare->new(Skip => \%skip);

  $comp->compare(\@a, \@b);

This should return I<true>, as we are explicitly ignoring the columns
which differ.

Of course, having created a comparator object with no skip hash, it is
possible to add one later:

  $comp->Skip({1 => 1, 2 => 1});

or:

  my %skip = (1 => 1, 2 => 2);
  $comp->Skip(\%skip);

To reset the comparator so that no longer skips elements, call NoSkip().

  $comp->NoSkip();

You can also check to see if one array is a permutation of another, i.e.
they contain the same elements but in a different order.

  if ($comp->perm(\@a, \@b) {
    print "Arrays are perms\n";
  else {
    print "Nope. Arrays are completely different\n";
  }

In this case the values of C<WhiteSpace> and C<Case> are still used,
but C<Skip> is ignored for, hopefully, obvious reasons.

=head1 METHODS

=cut

package Array::Compare;

require 5.010_000;
use strict;
use warnings;
our ($VERSION, $AUTOLOAD);

use Moo;
use Types::Standard qw(Str Bool HashRef);
use Carp;

$VERSION = '3.0.3';

has Sep        => ( is => 'rw', isa => Str,     default => '^G' );
has WhiteSpace => ( is => 'rw', isa => Bool,    default => 1 );
has Case       => ( is => 'rw', isa => Bool,    default => 1 );
has DefFull    => ( is => 'rw', isa => Bool,    default => 0 );
has Skip       => ( is => 'rw', isa => HashRef, default => sub { {} } );

=head2 new [ %OPTIONS ]

Constructs a new comparison object.

Takes an optional hash containing various options that control how
comparisons are carried out. Any omitted options take useful defaults.

=over 4

=item Sep

This is the value that is used to separate fields when the array is joined
into a string. It should be a value which doesn't appear in your data.
Default is '^G'.

=item WhiteSpace

Flag that indicates whether or not whitespace is significant in the
comparison. If this value is false then all multiple whitespace characters
are changed into a single space before the comparison takes place. Default
is 1 (whitespace is significant).

=item Case

Flag that indicates whther or not the case of the data should be significant
in the comparison. Default is 1 (case is significant).

=item Skip

a reference to a hash which contains the numbers of any columns that should
be skipped in the comparison. Default is an empty hash (all columns are
significant).

=item NoSkip

Reset skipped column details. It assigns {} to the attribute C<Skip>.

=cut

sub NoSkip {
    my $self = shift;

    $self->Skip({});
}

=item DefFull

Flag which indicates whether the default comparison is simple (just returns
true if the arrays are the same or false if they're not) or full (returns an
array containing the indexes of the columns that differ). Default is 0 (simple
comparison).

=back

=cut

#
# Utility function to check the arguments to any of the comparison
# function. Ensures that there are two arguments and that they are
# both arrays.
#
sub _check_args {
  my $self = shift;

  my @errs;

  push @errs, 'Must compare two arrays.' unless @_ == 2;
  push @errs, 'Argument 1 is not an array' unless ref($_[0]) eq 'ARRAY';
  push @errs, 'Argument 2 is not an array' unless ref($_[1]) eq 'ARRAY';

  croak join "\n", @errs if @errs;

  return;
}

=head2 compare_len \@ARR1, \@ARR2

Very simple comparison. Just checks the lengths of the arrays are
the same.

=cut

sub compare_len {
  my $self = shift;

  $self->_check_args(@_);

  return @{$_[0]} == @{$_[1]};
}

=head2 different_len \@ARR1, \@ARR2

Passed two arrays and returns true if they are of different lengths.

This is just the inverse of C<compare_len> (which is badly named).

=cut

sub different_len {
  my $self = shift;
  return ! $self->compare_len(@_);
}

=head2 compare \@ARR1, \@ARR2

Compare the values in two arrays and return a data indicating whether
the arrays are the same. The exact return values differ depending on
the comparison method used. See the descriptions of L<simple_compare>
and L<full_compare> for details.

Uses the value of DefFull to determine which comparison routine
to use.

=cut

sub compare {
  my $self = shift;

  if ($self->DefFull) {
    return $self->full_compare(@_);
  } else {
    return $self->simple_compare(@_);
  }
}

=head2 simple_compare \@ARR1, \@ARR2

Compare the values in two arrays and return a flag indicating whether or
not the arrays are the same.

Returns true if the arrays are the same or false if they differ.

Uses the values of 'Sep', 'WhiteSpace' and 'Skip' to influence
the comparison.

=cut

sub simple_compare {
  my $self = shift;

  $self->_check_args(@_);

  my ($row1, $row2) = @_;

  # No point in continuing if the number of elements is different.
  return unless $self->compare_len(@_);

  # @check contains the indexes into the two arrays, i.e. the numbers
  # from 0 to one less than the number of elements.
  my @check = 0 .. $#$row1;

  my ($pkg, $caller) = (caller(1))[0, 3];
  $caller = '' unless defined $caller;
  my $perm = $caller eq __PACKAGE__ . "::perm";

  # Filter @check so it only contains indexes that should be compared.
  # N.B. Makes no sense to do this if we are called from 'perm'.
  unless ($perm) {
    @check = grep {!(exists $self->Skip->{$_} && $self->Skip->{$_}) } @check
      if keys %{$self->Skip};
  }

  # Build two strings by taking array slices containing only the columns
  # that we shouldn't skip and joining those array slices using the Sep
  # character. Hopefully we can then just do a string comparison.
  # Note: this makes the function liable to errors if your arrays
  # contain the separator character.
  my $str1 = join($self->Sep, map { defined $_ ? $_ : '' } @{$row1}[@check]);
  my $str2 = join($self->Sep, map { defined $_ ? $_ : '' } @{$row2}[@check]);

  # If whitespace isn't significant, collapse it
  unless ($self->WhiteSpace) {
    $str1 =~ s/\s+/ /g;
    $str2 =~ s/\s+/ /g;
  }

  # If case isn't significant, change to lower case
  unless ($self->Case) {
    $str1 = lc $str1;
    $str2 = lc $str2;
  }

  return $str1 eq $str2;
}

=head2 full_compare \@ARR1, \@ARR2

Do a full comparison between two arrays.

Checks each individual column. In scalar context returns the number
of columns that differ (zero if the arrays are the same). In list
context returns a list containing the indexes of the columns that
differ (an empty list if the arrays are the same).

Uses the values of 'Sep' and 'WhiteSpace' to influence the comparison.

B<Note:> If the two arrays are of different lengths then this method
just returns the indexes of the elements that appear in one array but
not the other (i.e. the indexes from the longer array that are beyond
the end of the shorter array). This might be a little
counter-intuitive.

=cut

sub full_compare {
  my $self = shift;

  $self->_check_args(@_);

  my ($row1, $row2) = @_;

  # No point in continuing if the number of elements is different.
  # Because of the expected return value from this function we can't
  # just say 'the arrays are different'. We need to do some work to
  # calculate a meaningful return value.
  # If we've been called in array context we return a list containing
  # the number of the columns that appear in the longer list and aren't
  # in the shorter list. If we've been called in scalar context we
  # return the difference in the lengths of the two lists.
  if ($self->different_len(@_)) {
    return $self->_different_len_returns(@_);
  }

  my ($arr1, $arr2) = @_;

  my @diffs = ();

  foreach (0 .. $#{$arr1}) {
    next if keys %{$self->Skip} && $self->Skip->{$_};

    my ($val1, $val2) = ($arr1->[$_], $arr2->[$_]);

    if (not defined $val1 or not defined $val2) {
      push @diffs, $_ if $self->_defined_diff($val1, $val2);
      next;
    }

    unless ($self->WhiteSpace) {
      $val1 =~ s/\s+/ /g;
      $val2 =~ s/\s+/ /g;
    }

    unless ($self->Case) {
      $val1 = lc $val1;
      $val2 = lc $val2;
    }

    push @diffs, $_ unless $val1 eq $val2;
  }

  return wantarray ? @diffs : scalar @diffs;
}

sub _different_len_returns {
  my $self = shift;
  my ($row1, $row2) = @_;

  if (wantarray) {
    if ($#{$row1} > $#{$row2}) {
      return ( $#{$row2} + 1 .. $#{$row1} );
    } else {
      return ( $#{$row1} + 1 .. $#{$row2} );
    }
  } else {
    return abs(@{$row1} - @{$row2});
  }
}

sub _defined_diff {
  my $self = shift;
  my ($val1, $val2) = @_;

  return   if not defined $val1 and not defined $val2;
  return 1 if     defined $val1 and not defined $val2;
  return 1 if not defined $val1 and     defined $val2;
}

=head2 perm \@ARR1, \@ARR2

Check to see if one array is a permutation of the other (i.e. contains
the same set of elements, but in a different order).

We do this by sorting the arrays and passing references to the assorted
versions to simple_compare. There are also some small changes to
simple_compare as it should ignore the Skip hash if we are called from
perm.

=cut

sub perm {
  my $self = shift;

  return $self->simple_compare([sort @{$_[0]}], [sort @{$_[1]}]);
}

1;
__END__

=head1 AUTHOR

Dave Cross <dave@mag-sol.com>

=head1 SEE ALSO

perl(1).

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2005, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
