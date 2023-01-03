#!/usr/bin/env perl
# Copyright (c) 2023 Síle Ekaterin Aman
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
use feature qw(:5.30);
use DBI;
use autodie;

my $name = 'discourse.db';
if (@ARGV) {
	$name = $ARGV[0];
}

my $db = DBI->connect('dbi:SQLite:dbname=' . $name, '', '');

say 'Initializing database ' . $name . '...';
my @fields = ('discourse', 'adjective', 'creature');
foreach my $i (@fields) {
	print 'Creating table ' . $i;
	# this is really stupid lol
	$db->do('CREATE TABLE '.$i.' (id INTEGER PRIMARY KEY, data TEXT);');
	open my $fh, '<', "data/$i.txt";
	my $data;
	{
		local $/;
		$data = <$fh>;
	}
	close $fh;
	my @data = split /\n/, $data;
	print '; populating...';
	# this is really stupid lol
	my $sth = $db->prepare('INSERT INTO '.$i.' (data) VALUES (?);');
	foreach my $j (@data) {
		$sth->execute($j);
	}
	say ' Done.';
}
