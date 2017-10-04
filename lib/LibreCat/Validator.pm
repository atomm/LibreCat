package LibreCat::Validator;

use Catmandu::Sane;
use Catmandu::Fix;
use Catmandu::Validator::JSONSchema;
use Moo;
use namespace::clean;

with 'Catmandu::Validator';

has bag => (is => 'ro', required => 1);
has _validator => (is => 'lazy');

sub _build__validator {
    my $self = shift;
    my $bag  = $self->bag;

    my $s = Catmandu::Validator::JSONSchema->new(

        schema => Catmandu->config->{schemas}->{$bag}

    );

}

sub validate_data {
    my ($self, $data) = @_;

    my $bag       = $self->bag;
    my $validator = $self->_validator;

    my @white_list = $self->white_list;

    for my $key (keys %$data) {
        unless (grep(/^$key$/, @white_list)) {
            # h->log->debug("deleting invalid key: $key");
            delete $data->{$key};
        }
    }

    $validator->validate($data);
    my $errors = $validator->last_errors();

    return unless defined $errors;

    [map {$_->{property} . ": " . $_->{message}} @$errors];
}

sub white_list {
    my ($self) = @_;
    my $bag = $self->bag;

    my $properties = Catmandu->config->{schemas}->{$bag}->{properties}
        // {};
    return sort keys %$properties;
}

1;
