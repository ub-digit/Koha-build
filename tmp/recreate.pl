#!/usr/bin/perl

use Koha::SearchEngine::Elasticsearch;
use Koha::SearchEngine::Elasticsearch::Indexer;
use YAML::XS;
use JSON::XS;
use Data::Dumper;

#$config_file ||= '/home/vagrant/kohaclone/admin/searchengine/elasticsearch/field_config.yaml';
#local $YAML::XS::Boolean = 'JSON::PP';
#$settings = YAML::XS::LoadFile( $config_file );

#print Dumper([$settings]);
#$json = JSON::XS->new->convert_blessed->allow_blessed;
#$json_text = $json->utf8->encode ($settings);
#print Dumper([$json_text]);
#print $json_text;

 my $indexer = Koha::SearchEngine::Elasticsearch::Indexer->new( { index => "koha_kohadev_biblios" } );
 
 $indexer->drop_index() if $indexer->index_exists();
 $indexer->create_index();

