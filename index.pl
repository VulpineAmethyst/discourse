#!/usr/bin/env perl
# Copyright (c) 2023 Síle Ekaterin Liszka
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use strict;
use warnings;
use feature qw(:5.22 signatures);
use CGI::Fast;
use DateTime;
use DateTime::Format::Strptime qw(strftime);
use Math::Random::MT::Auto;
use DBI;

no warnings "experimental::signatures";

# data
my $db = DBI->connect('dbi:SQLite:dbname=discourse.db', '', '');
my $rand = Math::Random::MT::Auto->new();
my $template;
open my $fh, '<', 'template.html';
{
	local $/;
	$template = <$fh>;
}
close $fh;

# utility functions
sub pull($field) {
	if ($field eq 'user') {
		return tc(pull('adjective') . ' ' . pull('creature'));
	} elsif ($field eq 'handle') {
		my $ret = lc(pull('user'));
		$ret =~ s/[ .]//g;
		return $ret;
	} elsif ($field eq 'fursona') {
		return lc(pull('user'));
	} elsif ($field eq 'date') {
		my $days = int($rand->rand(90));
		my $fmt = "%m/%d/%Y %I:%M %p";
		if ($days == 1) {
			$fmt = "today at %H:%m %p";
		} elsif ($days == 2) {
			$fmt = "yesterday at %H:%m %p";
		}
		return strftime($fmt, DateTime->now()->subtract(days => $days));
	} elsif ($field =~ /^(\d+)d(\d+)$/) {
		my ($dice, $sides) = ($1, $2);
		my $ret = 0;
		for (0..$dice) {
			$ret += 1 + int($rand->rand($sides));
		}
		return $ret;
	} else {
		if ($field !~ /(adjective|creature|discourse)/) {
			return "[$field]";
		}
		# this is so stupid lol
		my $sth = $db->prepare(
			'select data from ' . $field .
			' where rowid = (abs(random()) % (select (select max(rowid) from ' . 
			$field . '))+1);'
		);
		$sth->execute;
		my $ret = $sth->fetchrow_array;
		return $ret;
	}
}

sub tc($str) {
	my @data = split / /, lc $str;
	for my $i (1..@data) {
		my @temp = split //, $data[$i - 1];
		$temp[0] = uc($temp[0]);
		$data[$i - 1] = join('', @temp);
	}
	return join(' ', @data);
}

while (my $cgi = CGI::Fast->new()) {
	my $src = $cgi->param('src');
	if (defined($src) && ($src == 1)) {
		open my $fh, '<', $0;
		print "Content-Type: text/plain; charset=utf8\n\n";
		{
			local $/;
			print <$fh>;
		}
		close $fh;
	} else {
		my %data;
		$data{discourse}  = pull('discourse');
		while ($data{discourse} =~ /{(.*?)}/) {
			my $field = $1;
			my $rep = pull($field);
			$data{discourse} =~ s/{$field}/$rep/g;
		}
		$data{discourse}  =~ s/\[(.*?)\]/{$1}/g;
		$data{author}     = pull('user');
		$data{user}       = '@' . lc($data{author});
		$data{user}       =~ s/[ .]//g;
		$data{date}       = pull('date');
		$data{likes}      = int($rand->rand(9999));
		$data{retweets}   = int($rand->rand(9999));
		if (int($rand->rand(2))) {
			$data{retweets} += $data{likes};
		} else {
			$data{likes}    += $data{retweets};
		}
		my $output = $template;
		$output =~ s/{(.*?)}/$data{$1}/g;
		print "Content-Type: text/html; charset=utf8\n\n";
		say $output;
	}
}
