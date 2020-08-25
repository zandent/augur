#!/usr/bin/perl
use strict;
use warnings;
use POSIX;

for(@ARGV){
	print("File $_ is parsed\n");
  open( my $main_fh, "<", "$_" ) or die $!;
  open( my $df_fh, ">", "$_.delete" ) or die $!;
  # my $virtual = 0;
  # if($_ =~ /\/I(.+)\.sol/){
  #   $virtual = 1;
  # }
  while (my $row = <$main_fh>) {
    if($row =~ /pragma solidity/){
      $row = "pragma solidity >=0.5.10;\n";
    }
    # if ($virtual == 1){
    #   if ($row =~ /function/ && $row !~ /virtual/){
    #     my ($p1) = $row =~ /function([^\)]+)\)/;
    #     my ($p2) = $row =~ /function[^\)]+\)(.+)/;
    #     $row = "function$p1\) virtual $p2\n";
    #   }
    # }
    print {$df_fh} $row;
  }
  close $main_fh;
  close $df_fh;
  system("mv $_.delete $_");
}
