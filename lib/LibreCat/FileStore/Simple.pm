package LibreCat::FileStore::Simple;

use Catmandu::Sane;
use Moo;
use Carp;
use LibreCat::FileStore::Container::Simple;
use Data::UUID;
use POSIX qw(ceil);
use namespace::clean;

with 'LibreCat::FileStore';

has root    => (is => 'ro', required => '1');
has uuid    => (is => 'ro', trigger  => 1);
has keysize => (is => 'ro', default  => 9, trigger => 1);

sub _trigger_keysize {
    my $self = shift;

    croak "keysize needs to be a multiple of 3"
        unless $self->keysize % 3 == 0;
}

sub _trigger_uuid {
    my $self = shift;

    $self->{keysize} = 36;
}

sub list {
    my ($self, $callback) = @_;

    my $root    = $self->root;
    my $keysize = $self->keysize;

    my $mindepth = ceil($keysize / 3);
    my $maxdepth = $mindepth + 1;

    unless (-d $root) {
        $self->log->error("no root $root found");
        return sub {undef};
    }

    $self->log->debug("creating generator for root: $root");
    return sub {
        state $io;

        unless (defined($io)) {
            open($io,
                "find -L $root -mindepth $mindepth -maxdepth $maxdepth -type d |"
            );
        }

        my $line = <$io>;

        unless (defined($line)) {
            close($io);
            return undef;
        }

        chop($line);
        $line =~ s/$root//;
        $line =~ s/\///g;
        $line;
    };
}

sub exists {
    my ($self, $key) = @_;

    croak "Need a key" unless defined $key;

    $self->log->debug("Checking exists $key");

    my $path = $self->path_string($key);

    -d $path;
}

sub add {
    my ($self, $key) = @_;

    croak "Need a key" unless defined $key;

    my $path = $self->path_string($key);

    unless ($path) {
        $self->log->error("Failed to create path from $key");
        return undef;
    }

    $self->log->debug("Generating path $path for key $key");

    LibreCat::FileStore::Container::Simple->create_container($path, $key);
}

sub get {
    my ($self, $key) = @_;

    croak "Need a key" unless defined $key;

    my $path = $self->path_string($key);

    unless ($path) {
        $self->log->error("Failed to create path from $key");
        return undef;
    }

    $self->log->debug("Loading path $path for key $key");

    LibreCat::FileStore::Container::Simple->read_container($path, $key);
}

sub delete {
    my ($self, $key) = @_;

    croak "Need a key" unless defined $key;

    my $path = $self->path_string($key);

    unless ($path) {
        $self->log->error("Failed to create path from $key");
        return undef;
    }

    $self->log->debug("Destoying path $path for key $key");

    LibreCat::FileStore::Container::Simple->delete_container($path);
}

sub path_string {
    my ($self, $key) = @_;

    my $keysize = $self->keysize;

    # Allow all hexidecimal numbers
    $key =~ s{[^A-F0-9-]}{}g;

    # If the key is a UUID then the matches need to be exact
    if ($self->uuid) {
        try {
            Data::UUID->new->from_string($key);
        }
        catch {
            return undef;
        };
    }
    else {
        return undef unless length($key) && length($key) <= $keysize;
        $key =~ s/^0+//;
        $key = sprintf "%-${keysize}.${keysize}d", $key;
    }

    my $path = $self->root . "/" . join("/", unpack('(A3)*', $key));

    $path;
}

1;

__END__


=pod

=head1 NAME

LibreCat::FileStore::Simple - The default implementation of a file storage

=head1 SYNOPSIS

    use LibreCat::FileStore::Simple;

    my $filestore =>LibreCat::FileStore::Simple->new(root => '/data2/librecat/file_uploads');

    my $generator = $filestore->list;

    while (my $key = $generator->()) {
        my $container = $filestore->get($key);

        for my $file ($container->list) {
            my $filename = $file->key;
            my $size     = $file->size;
            my $checksum = $file->md5;
            my $created  = $file->created;
            my $modified = $file->modified;
            my $io       = $file->data;
        }
    }

    my $container = $filestore->get('1234');

    if ($filestore->exists('1234')) {
        ...
    }

    my $container = $filestore->add('1235');

    $filestore->delete('1234');

=head1 CONFIGURATION

=head2 root($path)

The path to the root of the Simple file store storage.

=head2 uuid(0|1)

Optional. Support UUID-s as identifiers. Default 0

=head2 keysize($num)

Option. Support a FileStore with larger integer keys. Default 9

=head1 SEE ALSO

L<LibreCat::FileStore>