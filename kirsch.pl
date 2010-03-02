#!/usr/bin/perl
use strict;
use warnings;
use List::Util qw(max);

use GD;
use CGI qw(:standard);

my $image;

# Checks to see if this is running as a command-line script.
# I'm not sure of the best way to do this, but whatever.
if (!(url() eq 'http://localhost'))
{
    use WWW::Mechanize;
    my $mech = new WWW::Mechanize;

    $image = new GD::Image($mech->get(param("img"))->content) or die $!;

    print header(-type=>'image/png');
}
else
{
    $image = new GD::Image(shift()) or die $!;
}

my $output = new GD::Image($image->width,$image->height);

my @colours;
$colours[0] = $output->colorResolve(0,0,0);
$colours[1] = $output->colorResolve(0,255,0);
$colours[2] = $output->colorResolve(255,0,0);
$colours[3] = $output->colorResolve(0,0,255);
$colours[4] = $output->colorResolve(255,255,255);
$colours[5] = $output->colorResolve(0,255,255);
$colours[6] = $output->colorResolve(255,0,255);
$colours[7] = $output->colorResolve(128,128,128);
$colours[8] = $output->colorResolve(255,255,0);

# We can't work on the perimeter of the image.
for (my $x = 1; $x < $image->width-1; ++$x)
{
    for (my $y = 1; $y < $image->height-1; ++$y)
    {
        my @c;
        for (my $m = -1; $m < 2; ++$m)
        {
            for (my $n = -1; $n < 2; ++$n)
            {
                my @arr = $image->rgb($image->getPixel($x+$m,$y+$n));
                $c[$m+1][$n+1] = $arr[0];
            }
        }

        my @edges;
        {
            # For laziness and clarity
            my ($a,$b,$c,$d,$e,$f,$g,$h) = ( $c[2][0], $c[1][0], $c[0][0], $c[0][1], $c[0][2], $c[1][2], $c[2][2], $c[2][1] );

            # The extra number at the end is for colour info.
            push @edges, [5*($a+$b+$c) - 3*($d+$e+$f+$g+$h), 1]; #W
            push @edges, [5*($b+$c+$d) - 3*($e+$f+$g+$h+$a), 2]; #NW
            push @edges, [5*($c+$d+$e) - 3*($f+$g+$h+$a+$b), 3]; #N
            push @edges, [5*($d+$e+$f) - 3*($g+$h+$a+$b+$c), 4]; #NE 
            push @edges, [5*($e+$f+$g) - 3*($h+$a+$b+$c+$d), 5]; #E
            push @edges, [5*($f+$g+$h) - 3*($a+$b+$c+$d+$e), 6]; #SE
            push @edges, [5*($g+$h+$a) - 3*($b+$c+$d+$e+$f), 7]; #S
            push @edges, [5*($h+$a+$b) - 3*($c+$d+$e+$f+$g), 8]; #SW
        }

        # Sort by largest derivative value, or by original order if there's a tie.
        @edges = sort { $b->[0] <=> $a->[0] or $a->[1] <=> $b->[1] } @edges;
        my $max_edge = $edges[0];

        if ($max_edge->[0] > 383)
        {
            $output->setPixel($x,$y,$colours[$max_edge->[1]]);
        }
        else
        {
            $output->setPixel($x,$y,$colours[0]);
        }
    }
}

print $output->png;
