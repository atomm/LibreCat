package Catmandu::Fix::maybe_add_urn;

use Catmandu::Sane;
use Moo;

use App::Helper;

sub fix {
    my ($self, $pub) = @_;
    return $pub if $pub->{urn};
    
    if ($pub->{type} =~ /^bi/) {
        $pub->{urn} = h->generate_urn(h->config->{thesis}->{urn_prefix},$pub->{_id});
    } elsif($pub->{file}) {
        my $oa = 0;
        foreach my $f (@{$pub->{file}}) {
            ($f->{access_level} eq 'open_access') && ($oa = 1);
        }

        if ($oa) {
            $pub->{urn} = h->generate_urn(h->config->{urn_prefix},$pub->{_id});
        }
    }

    $pub;
}

1;
