#!/usr/bin/perl

sub main
{
    require 'banner.pm';
  banner::top("Faces of NVAD");

    require 'facebox.pm';
  facebox::faceindex();

  banner::bottom();
}


main;
