#!/usr/bin/perl -w

# Yarrow stalks simulator
use 5.010;
use strict;
use warnings;
use utf8;

my $hexagram = GenerateHexagram();

print "\nHexagram: $hexagram\n\n";

DrawHexagrams($hexagram);

# ========================================================

sub DrawHexagrams {
    my $hexagram = shift;
    
    for (0..5) {
        my $line = substr($hexagram, $_, 1);
        
        if ($line eq '6') {
             print "--  --  =>  ------\n";
        } elsif ($line eq '7') {
             print "------      ------\n";
        } elsif ($line eq '8') {
             print "--  --      --  --\n";
        } elsif ($line eq '9') {
             print "------  =>  --  --\n";
        }
    }
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
