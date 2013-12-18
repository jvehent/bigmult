#! /usr/bin/perl -w
use strict;
use Time::HiRes;

# check that both args are integers
unless (defined($ARGV[0]) 
        && defined($ARGV[1]) 
        && ($ARGV[0] && $ARGV[1]) =~ /^\d+$/)
{
    print "usage: ./bigmult.pl <numberA> <numberB> <optional:verbose>\n";
}

# verbose mode
my $verbose = 0;
if (defined($ARGV[2]) && $ARGV[2] eq "verbose"){
    $verbose = 1;
}


# store the two number in scalars, big_b is always the longest (or equal)
my ($big_a, $big_b) = "";
if(length($ARGV[0]) > length($ARGV[1])){
    $big_b = $ARGV[0];
    $big_a = $ARGV[1];
}
else {
    $big_a = $ARGV[0];
    $big_b = $ARGV[1];
}

my $big_b_len = length($big_b);
my $big_a_len = length($big_a);
my $carry = 0;
my $result = "";

print "performing $big_a (l=$big_a_len) x $big_b (l=$big_b_len)\n" if $verbose;

# benchmarking
my $initTime = [Time::HiRes::gettimeofday()];

# linear convolution
# multiply digits one by one
# starting from the rightmost ones
# example:
#                     1   2   3
#                 ×   4   5   6
#                 -------------
#                    6   12  18
#                5   10  15  
#            4   8   12
#             -----------------
#            4   13  28  27  18
#
# this is a two loops process, first we set big_b to the rightmost digit
# and move it to the left, multiplying it with the corresponding $big_a digit
# until big_b reaches the leftmost position
#
# example:
#  loop 1 -> big_b = 6, big_a = 3 => big_b * big_a = 18
#  loop 2 -> (big_b = 5 * big_a = 3) + (big_b = 6 * big_a = 2) = 27
#  loop 3 -> (4*3)+(5*2)+(6*1) = 28
#
# then, when big_b is at the leftmost position, we move big_a to the left
# until big_a is also at the rightmost position
#
# example:
#  loop 4 -> (big_b = 4 * big_a = 2) + (big_b = 5 * big_a = 1) = 13
#  loop 5 -> (4*1) = 4
#
# we need { length(big_a) * length(big_b) -1} loops to find the result
#

# first loop, move big_b from rightmost to leftmost position
for(my $big_b_ptr = -1; $big_b_ptr >= -$big_b_len; $big_b_ptr--) {

    print "LOOP START -------------------\nprev. inter_result\tcurrent mult.\tcur. inter_result\n" if $verbose;

    my $current_big_b_ptr = $big_b_ptr;
    my $inter_result = 0;
    my $big_a_ptr = -1;
    do {
        if($big_a_ptr >= -$big_a_len){
            print "$inter_result\t\t\t" if $verbose;

            $inter_result += substr($big_a,$big_a_ptr,1) * substr($big_b,$current_big_b_ptr,1);

            print substr($big_a,$big_a_ptr,1)." * ".substr($big_b,$current_big_b_ptr,1)."\t\t\t$inter_result\n" if $verbose;
        }

        $current_big_b_ptr++;
        $big_a_ptr--;
    }
    while ($current_big_b_ptr < 0);

    # add previous carry
    print "->inter_result=$inter_result, add carry $carry\n" if $verbose;
    $inter_result += $carry;
    $carry = int($inter_result / 10);
    $inter_result %= 10;
    $result .= $inter_result;
    print "->new carry=$carry, store $inter_result\nLOOP END ---------------------\n" if $verbose;
}

# second loop, big_b is at leftmost, move big_a from rightmost to leftmost,
# ignoring the rightmost digit (already processed in last loop)
for(my $big_a_ptr = -2; $big_a_ptr >= -$big_a_len; $big_a_ptr--){
    print "LOOP START -------------------\nprev. inter_result\tcurrent mult.\tcur. inter_result\n" if $verbose;

    my $current_big_a_ptr = $big_a_ptr;
    my $inter_result = 0;
    my $big_b_ptr = -$big_b_len;

    do {

        print "$inter_result\t\t\t" if $verbose;

        $inter_result += substr($big_a,$current_big_a_ptr,1) * substr($big_b,$big_b_ptr,1);

        print substr($big_a,$current_big_a_ptr,1)." * ".substr($big_b,$big_b_ptr,1)."\t\t\t$inter_result\n" if $verbose;

        $current_big_a_ptr--;
        $big_b_ptr++;

    }while($current_big_a_ptr >= -$big_a_len);

    # add previous carry
    print "->inter_result=$inter_result, add carry $carry\n" if $verbose;
    $inter_result += $carry;
    $carry = int($inter_result / 10);
    $inter_result %= 10;
    $result .= $inter_result;
}

# add final carry
$result .= $carry if $carry > 0;

my $elapsed = Time::HiRes::tv_interval($initTime);

# $result contain the result of the multiplication from right to left
my $printable_result = reverse $result;
print "\n======\nresult= $printable_result\n\ncomputed in $elapsed seconds\n";

