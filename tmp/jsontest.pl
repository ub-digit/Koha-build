#!/usr/bin/perl

use Koha::SearchEngine::Elasticsearch;
use Koha::SearchEngine::Elasticsearch::Indexer;
use YAML::XS;
use Data::Dumper;

$config_file ||= '/home/vagrant/kohaclone/admin/searchengine/elasticsearch/field_config.yaml';
local $YAML::XS::Boolean = 'JSON::PP';
$settings = YAML::XS::LoadFile( $config_file );

print Dumper([$settings]);
$json = JSON::XS->new;
#$json->allow_blessed;
#$json->convert_blessed;
$json_text = $json->encode($settings);
print Dumper([$json_text]);
#print $json_text;

