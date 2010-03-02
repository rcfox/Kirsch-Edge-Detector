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

# We can't work on the perimeter of the image.
for(my $x = 1; $x < $image->width-1; ++$x)
{
    for(my $y = 1; $y < $image->height-1; ++$y)
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

        # For laziness and clarity
        my ($a,$b,$c,$d,$e,$f,$g,$h) = ( $c[2][0], $c[1][0], $c[0][0], $c[0][1], $c[0][2], $c[1][2], $c[2][2], $c[2][1] );
        
        my @edges;
        push @edges, 5*($a+$b+$c) - 3*($d+$e+$f+$g+$h); #W
        push @edges, 5*($b+$c+$d) - 3*($e+$f+$g+$h+$a); #NW
        push @edges, 5*($c+$d+$e) - 3*($f+$g+$h+$a+$b); #N
        push @edges, 5*($d+$e+$f) - 3*($g+$h+$a+$b+$c); #NE 
        push @edges, 5*($e+$f+$g) - 3*($h+$a+$b+$c+$d); #E
        push @edges, 5*($f+$g+$h) - 3*($a+$b+$c+$d+$e); #SE
        push @edges, 5*($g+$h+$a) - 3*($b+$c+$d+$e+$f); #S
        push @edges, 5*($h+$a+$b) - 3*($c+$d+$e+$f+$g); #SW

        my $max_edge = max @edges;
        if($max_edge > 383)
        {
            # I'm not exactly sure of which colour I'm supposed to draw with here.
            $output->setPixel($x,$y,$output->colorResolve($max_edge,$max_edge,$max_edge));
            #$output->setPixel($x,$y,$output->colorResolve(255,255,255));
        }
        else
        {
            $output->setPixel($x,$y,$output->colorResolve(0,0,0));
        }
    }
}

print $output->png;
