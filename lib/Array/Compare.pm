# use v5.26;
use Feature::Compat::Class;

class Array::Compare {

  our ($VERSION, $AUTOLOAD);

  use Carp;

  field $Sep        :param = '^G';
  field $WhiteSpace :param = 1;
  field $Case       :param = 1;
  field $DefFull    :param = 0;
  field $Skip       :param = {};

  method Sep        { @_ and $Sep        = shift; $Sep }
  method WhiteSpace { @_ and $WhiteSpace = shift; $WhiteSpace }
  method Case       { @_ and $Case       = shift; $Case }
  method DefFull    { @_ and $DefFull    = shift; $DefFull }
  method Skip       { @_ and $Skip       = shift; $Skip }

  method NoSkip {
    $Skip = {};
  }

#
# Utility function to check the arguments to any of the comparison
# function. Ensures that there are two arguments and that they are
# both arrays.
#
  method _check_args($a1, $a2) {
    my @errs;

    push @errs, 'Must compare two arrays.' unless defined $a1 and defined $a2;;
    push @errs, 'Argument 1 is not an array' unless ref($a1) eq 'ARRAY';
    push @errs, 'Argument 2 is not an array' unless ref($a2) eq 'ARRAY';

    croak join "\n", @errs if @errs;

    return;
  }

  method compare_len($a1, $a2) {

    $self->_check_args($a1, $a2);

    return @{$a1} == @{$a2};
  }

  method different_len($a1, $a2) {
    return ! $self->compare_len($a1, $a2);
  }

  method compare($a1, $a2) {
    if ($DefFull) {
      return $self->full_compare($a1, $a2);
    } else {
      return $self->simple_compare($a1, $a2);
    }
  }

  method simple_compare($a1, $a2) {
    $self->_check_args($a1, $a2);

    # No point in continuing if the number of elements is different.
    return unless $self->compare_len($a1, $a2);

    # @check contains the indexes into the two arrays, i.e. the numbers
    # from 0 to one less than the number of elements.
    my @check = 0 .. $#$a1;

    my ($pkg, $caller) = (caller(1))[0, 3];
    $caller = '' unless defined $caller;
    my $perm = $caller eq __PACKAGE__ . "::perm";

    # Filter @check so it only contains indexes that should be compared.
    # N.B. Makes no sense to do this if we are called from 'perm'.
    unless ($perm) {
      @check = grep {!(exists $Skip->{$_} && $Skip->{$_}) } @check
        if keys %{$Skip};
    }

    # Build two strings by taking array slices containing only the columns
    # that we shouldn't skip and joining those array slices using the Sep
    # character. Hopefully we can then just do a string comparison.
    # Note: this makes the function liable to errors if your arrays
    # contain the separator character.
    my $str1 = join($Sep, map { defined $_ ? $_ : '' } @{$a1}[@check]);
    my $str2 = join($Sep, map { defined $_ ? $_ : '' } @{$a2}[@check]);

    # If whitespace isn't significant, collapse it
    unless ($WhiteSpace) {
      $str1 =~ s/\s+/ /g;
      $str2 =~ s/\s+/ /g;
    }

    # If case isn't significant, change to lower case
    unless ($Case) {
      $str1 = lc $str1;
      $str2 = lc $str2;
    }

    return $str1 eq $str2;
  }

  method full_compare($a1, $a2) {
    $self->_check_args($a1, $a2);

    # No point in continuing if the number of elements is different.
    # Because of the expected return value from this function we can't
    # just say 'the arrays are different'. We need to do some work to
    # calculate a meaningful return value.
    # If we've been called in array context we return a list containing
    # the number of the columns that appear in the longer list and aren't
    # in the shorter list. If we've been called in scalar context we
    # return the difference in the lengths of the two lists.
    if ($self->different_len($a1, $a2)) {
      return $self->_different_len_returns($a1, $a2);
    }

    my @diffs = ();

    foreach (0 .. $#{$a1}) {
      next if keys %{$Skip} && $Skip->{$_};

      my ($val1, $val2) = ($a1->[$_], $a2->[$_]);

      if (not defined $val1 or not defined $val2) {
        push @diffs, $_ if $self->_defined_diff($val1, $val2);
        next;
      }

      unless ($WhiteSpace) {
        $val1 =~ s/\s+/ /g;
        $val2 =~ s/\s+/ /g;
      }

      unless ($Case) {
        $val1 = lc $val1;
        $val2 = lc $val2;
      }

      push @diffs, $_ unless $val1 eq $val2;
    }

    return wantarray ? @diffs : scalar @diffs;
  }

  method _different_len_returns($a1, $a2) {

    if (wantarray) {
      if ($#{$a1} > $#{$a2}) {
        return ( $#{$a2} + 1 .. $#{$a1} );
      } else {
        return ( $#{$a1} + 1 .. $#{$a2} );
      }
    } else {
      return abs(@{$a1} - @{$a2});
    }
  }

  method _defined_diff($val1, $val2) {
    return   if not defined $val1 and not defined $val2;
    return 1 if     defined $val1 and not defined $val2;
    return 1 if not defined $val1 and     defined $val2;
  }

  method perm($a1, $a2) {
    return $self->simple_compare([sort @{$a1}], [sort @{$a2}]);
  }

}

1;
__END__

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
  } else {
    print "Nope. Arrays are completely different\n";
  }

In this case the values of C<WhiteSpace> and C<Case> are still used,
but C<Skip> is ignored for, hopefully, obvious reasons.

=head1 METHODS

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

=item DefFull

Flag which indicates whether the default comparison is simple (just returns
true if the arrays are the same or false if they're not) or full (returns an
array containing the indexes of the columns that differ). Default is 0 (simple
comparison).

=back


=head2 compare_len \@ARR1, \@ARR2

Very simple comparison. Just checks the lengths of the arrays are
the same.

=head2 different_len \@ARR1, \@ARR2

Passed two arrays and returns true if they are of different lengths.

This is just the inverse of C<compare_len> (which is badly named).

=head2 compare \@ARR1, \@ARR2

Compare the values in two arrays and return a data indicating whether
the arrays are the same. The exact return values differ depending on
the comparison method used. See the descriptions of L<simple_compare>
and L<full_compare> for details.

Uses the value of DefFull to determine which comparison routine
to use.

=head2 simple_compare \@ARR1, \@ARR2

Compare the values in two arrays and return a flag indicating whether or
not the arrays are the same.

Returns true if the arrays are the same or false if they differ.

Uses the values of 'Sep', 'WhiteSpace' and 'Skip' to influence
the comparison.

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

=head2 perm \@ARR1, \@ARR2

Check to see if one array is a permutation of the other (i.e. contains
the same set of elements, but in a different order).

We do this by sorting the arrays and passing references to the assorted
versions to simple_compare. There are also some small changes to
simple_compare as it should ignore the Skip hash if we are called from
perm.

=head1 AUTHOR

Dave Cross E<lt>dave@mag-sol.comE<gt>

=head1 SEE ALSO

L<Array::Diff> - where Array::Compare focusses on whether two
arrays are different, C<Array::Diff> tells you how they are different.

L<Test::Deep> - functions for comparing arbitrary data structures,
as part of a testsuite.

L<List::Compare> - similar functionality, but again with more options.

L<Algorithm::Diff> - the underlying implementation of the diff algorithm.
If you've got L<Algorithm::Diff::XS> installed, that will be used.

L<YAML::Diff> - find difference between two YAML documents.

L<HTML::Differences> - find difference between two HTML documents.
This uses a more sane approach than L<HTML::Diff>.

L<XML::Diff> - find difference between two XML documents.

L<Hash::Diff> - find the differences between two Perl hashes.

L<Data::Diff> - find difference between two arbitrary data structures.

L<Text::Diff> - can find difference between two inputs, which can be
data structures or file names.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2005, Magnum Solutions Ltd.  All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
