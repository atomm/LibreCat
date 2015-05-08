#!/usr/bin/env perl

use Catmandu::Sane;
use Catmandu -all;
use Search::Elasticsearch;
use Data::Dumper;

Catmandu->load(':up');
Catmandu->config;

my $backup = Catmandu->store('backup')->bag('publication');

my $e = Search::Elasticsearch->new();

my $pub1_exists = $e->indices->exists(index => 'pub1');
my $pub2_exists = $e->indices->exists(index => 'pub2');

if ($pub1_exists and !$pub2_exists) {
	print "Index pub1 exists, new index will be pub2.\n";
	my $bag = Catmandu->store('search', index_name => 'pub2')->bag('publication');
	$bag->add_many($backup);
	my $researcher_result = `/usr/local/bin/perl /home/bup/pub/bin/index_researcher.pl -m pub2`;
	my $department_result = `/usr/local/bin/perl /home/bup/pub/bin/index_department.pl -m pub2`;
	my $project_result = `/usr/local/bin/perl /home/bup/pub/bin/index_project.pl -m pub2`;
	my $award_result = `/usr/local/bin/perl /home/bup/pub/bin/index_award.pl -m pub2`;

	print "New index is pub2. Testing...\n";
	my $checkForIndex = $e->indices->exists(index => 'pub2');
	if($checkForIndex){
		print "Index pub2 exists. Setting index alias 'pub' to pub2, testing and then deleting index pub1.\n";

		$e->indices->update_aliases(
		    body => {
		    	actions => [
		    	    { add    => { alias => 'pub', index => 'pub2' }},
		    	    { remove => { alias => 'pub', index => 'pub1' }}
		    	]
		    }
		);

		$checkForIndex = $e->indices->exists(index => 'pub');

		if($checkForIndex){
			print "Alias 'pub' is ok and points to index pub2. Deleting pub1.\n";
			$e->indices->delete(index => 'pub1');
		}
		else {
			print "Error: Could not create alias.\n";
			exit;
		}
	}
	else {
		print "Error: Could not create index pub2.\n";
		exit;
	}

}
elsif($pub2_exists and !$pub1_exists) {
	print "Index pub2 exists, new index will be pub1.\n";
	my $bag = Catmandu->store('search', index_name => 'pub1')->bag('publication');
	$bag->add_many($backup);
	my $researcher_result = `/usr/local/bin/perl /home/bup/pub/bin/index_researcher.pl -m pub1`;
	my $department_result = `/usr/local/bin/perl /home/bup/pub/bin/index_department.pl -m pub1`;
	my $project_result = `/usr/local/bin/perl /home/bup/pub/bin/index_project.pl -m pub1`;
	my $award_result = `/usr/local/bin/perl /home/bup/pub/bin/index_award.pl -m pub1`;

	print "New index is pub1. Testing...\n";
	my $checkForIndex = $e->indices->exists(index => 'pub1');
	if($checkForIndex){
		print "Index pub1 exists. Setting index alias 'pub' to pub1, testing and then deleting index pub2.\n";

		$e->indices->update_aliases(
		    body => {
		    	actions => [
		    	    { add    => { alias => 'pub', index => 'pub1' }},
		    	    { remove => { alias => 'pub', index => 'pub2' }}
		    	]
		    }
		);

		$checkForIndex = $e->indices->exists(index => 'pub');

		if($checkForIndex){
			print "Alias 'pub' is ok and points to index pub1. Deleting pub2.\n";
			$e->indices->delete(index => 'pub2');
		}
		else {
			print "Error: Could not create alias.\n";
			exit,
		}
	}
	else {
		print "Error: Could not create index pub1.\n";
		exit;
	}

}
else { # $pub1_exists and $pub2_exists
	print "Both indexes exist. Find out which one is running (curl -s -XGET 'http://localhost:9200/[alias]/_status') and delete the other (curl -s -XDELETE 'http://localhost:9200/[unused_index]').\n Then restart!\n";
	exit;
}