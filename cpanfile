requires 'perl', 'v5.10.1';

on 'test' => sub {
    requires 'Test::Lib';
    requires 'Test::More';
    requires 'Test::TCP';
    requires 'Test::Exception', '0.43';
    requires 'Dancer::Test';
    requires 'File::Slurp';
    requires 'IO::File';
    requires 'File::Path';
    requires 'Test::Code::TidyAll', '0.20';
    requires 'Test::WWW::Mechanize::Dancer';
    requires 'App::Cmd::Tester';
    requires 'Devel::Cover';
    requires 'Selenium::Remote::Driver', '1.12';
};

requires 'Business::ISBN', 0;
requires 'Module::Install', '1.16';

# Catmandu
requires 'Catmandu', '>=1.06';
requires 'Catmandu::Exporter::Table';
requires 'Search::Elasticsearch', '>=5.02';
requires 'Search::Elasticsearch::Client::1_0','>=5.02';
requires 'Catmandu::Store::ElasticSearch', '>=0.0509';
requires 'Catmandu::Store::MongoDB', '>=0.0403';
requires 'Catmandu::DBI', '>=0.0511';
requires 'Catmandu::BibTeX';
requires 'Catmandu::XML';
requires 'Catmandu::ArXiv', '>=0.100';
requires 'Catmandu::LDAP';
requires 'Catmandu::Importer::getJSON';
requires 'Catmandu::Identifier', '>=0.05';
requires 'Catmandu::RIS', '>=0.04';
requires 'Catmandu::Fix::Date';
requires 'Catmandu::SRU','0.039';
requires 'Catmandu::OAI' , '0.16';

#Dancer
requires 'Dancer';
requires 'Dancer::Plugin';
requires 'Dancer::FileUtils';
requires 'Dancer::Plugin::Catmandu::OAI', '>=0.0501';
requires 'Dancer::Plugin::Catmandu::SRU', '0.0403';
requires 'Dancer::Plugin::Auth::Tiny';
requires 'Dancer::Plugin::StreamData';
requires 'Dancer::Logger::Log4perl';
requires 'Dancer::Session::PSGI';
requires 'Template';
requires 'Template::Plugin::Date';
requires 'Template::Plugin::JSON::Escape', '0.02';
requires 'Template::Plugin::Gravatar';
requires 'Furl';
requires 'HTML::Entities';
requires 'Syntax::Keyword::Junction';

#Plack
requires 'Plack';
requires 'Plack::Middleware::ReverseProxy';
requires 'Dancer::Middleware::Rebase';
requires 'Plack::Middleware::Deflater';
requires 'Plack::Middleware::Negotiate', '>= 0.20';
requires 'Plack::Middleware::Debug';
requires 'Plack::Middleware::Debug::Dancer::Settings';
requires 'Plack::Middleware::Session';
requires 'Plack::Session::Store::Catmandu', '>= 0.03';
requires 'Starman';

# others
requires 'all';
requires 'Business::ISBN10';
requires 'Business::ISBN13';
requires 'App::bmkpasswd', '2.010001';
requires 'Clone';
requires 'DateTime';
requires 'DBD::Pg', '>= 3.6.2';
requires 'DBD::SQLite';
requires 'Config::Onion', '>=1.007';
requires 'Crypt::Digest::MD5';
requires 'Crypt::SSLeay';
requires 'File::Basename';
requires 'XML::RSS';
requires 'YAML::XS';
requires 'YAML';
requires 'JSON::MaybeXS';
requires 'Log::Log4perl';
requires 'Log::Any::Adapter';
requires 'Log::Any::Adapter::Log4perl';
requires 'Getopt::Long';
requires 'URL::Encode';
requires 'Encode';
requires 'Term::ReadKey';
requires 'Net::LDAP';
requires 'Net::LDAPS';
requires 'Email::Sender::Simple';
requires 'REST::Client';
requires 'Data::Uniqid';

requires 'Authen::CAS::Client','0.06';
requires 'Module::Install';
requires 'Gearman::XS', '0.15';
requires 'Net::Telnet::Gearman';
requires 'Proc::Launcher', '0.0.35';
requires 'Path::Tiny', '0.052';
requires 'String::CamelCase';

requires 'MIME::Types','==1.38';
requires 'Catmandu::BagIt' , '>=0.13';

requires 'Catmandu::Store::FedoraCommons';
requires 'IO::All';
requires 'Catmandu::Validator::JSONSchema','0.11';
requires 'Code::TidyAll', 0;

requires 'Locale::Maketext';
requires 'Locale::Maketext::Lexicon';
requires 'AnyEvent','7.13';
requires 'AnyEvent::HTTP','2.23';
