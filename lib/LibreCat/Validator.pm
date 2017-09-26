package LibreCat::Validator;

use Catmandu::Sane;
use Catmandu::Fix;
use Catmandu::Util qw(require_package);
use Moo;
use namespace::clean;

has bag => (is => 'ro', required => 1);
has _validator => (is => 'lazy');

sub _build__validator {
    my $self = shift;
    my $bag  = $self->bag;
    require_package(ucfirst($bag), 'LibreCat::Validator')->new;
}

sub validate {
    my ($self, $data) = @_;

    my $bag       = $self->bag;
    my $validator = $self->_validator;

    my @white_list = $validator->white_list;

    for my $key (keys %$data) {
        unless (grep(/^$key$/, @white_list)) {
            # h->log->debug("deleting invalid key: $key");
            delete $data->{$key};
        }
    }

    unless ($validator->is_valid($data)) {
        # h->log->error($data->{_id} . " not a valid publication!");
        # h->log->error($validator->last_errors);
        $data->{_validation_errors} = $validator->last_errors;
    }

    return $data;
}

1;
