#!/usr/bin/perl

# *******************************************************************************#
# File   : i_ching.pl                                                            #
# -------------------------------------------------------------------------------#
# Author : John Jacobs <jjacobs@xs4all.nl>                                       #
# Date   : 26 september 2014                                                     #
# Version: 0.1                                                                   #
#                                                                                #
# Description: Perl script for consulting the I-Ching                            #
#                                                                                #
# Remarks: original Yarrow stalks simulator code by TGI                          #
#                                                                                #
# (C) 2014: This program is free software: you can redistribute it and/or modify #
#           it under the terms of the GNU General Public License as published by #
#           the Free Software Foundation, either version 3 of the License, or    #
#           (at your option) any later version.                                  #
#                                                                                #
#           This program is distributed in the hope that it will be useful,      #
#           but WITHOUT ANY WARRANTY; without even the implied warranty of       #
#           MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
#           GNU General Public License for more details.                         #
#                                                                                #
#           You should have received a copy of the GNU General Public License    #
#           along with this program. If not, see <http://www.gnu.org/licenses/>. #
# *******************************************************************************#

use 5.010;
use strict;
use warnings;
use utf8;

my $hexagram = GenerateHexagram();
my $hexagram_key = GenerateKey($hexagram);

my $moving_key = GenerateMovingHexagram($hexagram);
$moving_key = GenerateKey($moving_key) if $moving_key;
    
DrawHexagrams($hexagram);

# Firefox MOET runnen voordat het script gstart wordt!
system("C:\\Users\\John\\Documents\\Develop\\I_Ching\\Book\\$moving_key.html") if $moving_key;
system("C:\\Users\\John\\Documents\\Develop\\I_Ching\\Book\\$hexagram_key.html");

# ========================================================

sub DrawHexagrams {
    my $hexagram = shift;
    
    for (0..5) {
        my $line = substr($hexagram, $_, 1);
        
        given ($line) {
            when (6) {print "--  --  =>  ------\n"};
            when (7) {print "------      ------\n"};
            when (8) {print "--  --      --  --\n"};
            when (9) {print "------  =>  --  --\n"};
        }
    }
}

sub GenerateKey {
    my $hexagram = shift;
    my $key = '';
    
    for (0..5) {
        my $line = substr($hexagram, $_, 1);
        
        $key .= '0' if $line =~ /[68]/;
        $key .= '1' if $line =~ /[79]/;
    }
    
    $key;
}
    
sub GenerateMovingHexagram {
    my $hexagram = shift;
    $hexagram =~ tr/69/78/ ? $hexagram : '';
}

sub PileSplit
{   my $pile_ref = shift ; # Pile to split
    my $max_diff = shift ; # Maximum difference in pile size.
    
    my $pile;
    
    MoveStalks($pile_ref,\$pile,$$pile_ref);
    my $p_diff = int( rand $max_diff ) + 1 ;
    
    my $left_pile  = int($pile/2) + ( $pile%2 + $p_diff ) ;
    my $right_pile = int($pile/2) - ( $p_diff ) ;

    return ($left_pile, $right_pile) ;  
}

# CountPile - Takes a pile and returns a remainder.
sub CountPile
{   my $pile_ref = shift ; # ref to pile

    my $remainder = $pile_ref % 4 ;
    $remainder = 4 if $remainder == 0 ;
 
    return $remainder ;
}

# MoveStalks takes two refs and a quantity, returns one on success, 0 on failure.
sub MoveStalks
{   my $from   = shift;  # Source
    my $to     = shift;  # Destination
    my $number = shift;  # Quantity to move
    
    $$from -= $number;
    $$to += $number;
    
    return 0 if $$from < 0;
    return 1;
}

# CountHand : takes a hand ref and returns the number of stalks in the hand.
sub CountHand 
{   my $hand_ref = shift ; # Reference to hand to count.
    my $stalk_count ;      # How many stalks are in the hand? Return value

    foreach ( keys(%$hand_ref) )
    {   $stalk_count += $$hand_ref{$_}; 
    }
    
    warn "Bad stalk count: $stalk_count\n" unless (grep{$stalk_count == $_} (4,5,8,9)) ;

    return $stalk_count ;
}

# GoodStalkCount : Tests a number to see if it is a good count.  Returns 0 or 1.
sub GoodStalkCount
{   my $count = shift; # Number to be tested.

    return grep {$count == $_} (4,5,8,9) ;
}

#LayHandDown
sub LayHandDown
{   my $hand_ref = shift ; # Reference to hand to lay down.
    my $dest = shift;      # Reference to destination.
    
    foreach ( keys(%$hand_ref) )
    {    MoveStalks(\$$hand_ref{$_}, $dest, $$hand_ref{$_})
    }
    
    return 1;
}

# DrawStalks : input pile count, returns stalk count
sub DrawStalks
{   my $pile = shift;     # The size of the pile to draw stalks from.
    my $hand = shift;     # Reference to the hand to hold stalks in.
    my $max_diff = shift; # Maximum difference between piles when divided
    
    # Step 2 : Split up piles
    my ($left_pile, $right_pile) = PileSplit($pile, $max_diff);

    # Step 3 : Take one stalk from right pile, put in left hand
    MoveStalks(\$right_pile, \$$hand{45}, 1);

    # Step 4 : Count left pile by fours, taking remainder in left hand.
    MoveStalks(\$left_pile, \$$hand{34}, CountPile($left_pile));

    # Step 5 : Count right pile by fours, taking remainder in left hand
    MoveStalks(\$right_pile, \$$hand{23}, CountPile($right_pile));
    
    # Step 6 : Count stalks in left hand. Should be 5 or 9 first time, 4 or 8 on subsequent tries. 
    my $stalk_count = CountHand($hand);
    
    # Step 6.5 : Merge leftover piles
    MoveStalks(\$right_pile, $pile, $right_pile);
    MoveStalks(\$left_pile, $pile, $left_pile);
    
    return 0 unless GoodStalkCount($stalk_count);
    
    return $stalk_count < 7 ? 'low' : 'high' ;
}

sub LineType
{   my $line = shift ; # Reference to an array of lines. First element gets line type.

    my $high = 0 ;     # Number of high counts
    my $low  = 0 ;     # Number of low counts
    my $type;          # The type of line
    
    my %line_types = ( 6 => 'Old Yin',
                       7 => 'Yang',
                       8 => 'Yin',
                       9 => 'Old Yang'
                     ) ;

    foreach my $i (1..3) # Count the type of Drawings
    {   $high++ if ( grep {$$line[$i] eq $_} ('high',8,9) );
        $low++ if ( grep {$$line[$i] eq $_} ('low',4,5) ); 
    }
    
    $type = ($high * 2) + ($low * 3);
    
    $$line[0] = $$line[1]=~/\d/ ? $type : $line_types{$type}; 

    return;
}

# GenerateLine : Takes a number and returns two array refs.
sub GenerateLine
{   my $max_diff = @_ ? shift : 10;  # Maximum difference between piles when divided
    my $pile = 49;                   # Size of starting pile. 49 is traditional.
    my @wu_chi = ('0');              # Numerical results of draws. First element gets line type.
    my @result = ('0');              # Text results of draws. First elemebt gets line type.
    my %left_hand;                   # Used to hold onto stalks, while the other manipulates them :).
    
    foreach(1..3)
    {   $result[$_] = DrawStalks(\$pile,\%left_hand, $max_diff);
        die 'Bad stalk count.' unless $result[$_];
        LayHandDown(\%left_hand,\$wu_chi[$_]);   
    }
    
    LineType(\@result);
    LineType(\@wu_chi);

    return \@wu_chi,\@result;
}

sub GenerateTrigram
{   my @lines ; # Array to store results of line generation.
    
    foreach (1..3) # Get array of numbers
    {   push @lines, (GenerateLine())[0]->[0] ; # get the numerical value of each line 6-9.
    }
    
    return \@lines;
}

sub GenerateHexagram
{   my $below = GenerateTrigram();
    my $above = GenerateTrigram();
    my $hexagram;
    
    $hexagram = join '',@$below,@$above;
    my $moving = $hexagram;
    
    # $moving =~ tr/6789/7788/;
    # $hexagram =~ tr/6789/8787/;
    
    return ($hexagram);
}
