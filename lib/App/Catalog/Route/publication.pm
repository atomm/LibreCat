package App::Catalog::Route::publication;

=head1 NAME App::Catalog::Route::publication

    Route handler for publications.

=cut

use Catmandu::Sane;
use App::Catalog::Helper;
use App::Catalog::Controller::Publication;
use Dancer ':syntax';
use Try::Tiny;
use Dancer::Plugin::Auth::Tiny;

Dancer::Plugin::Auth::Tiny->extend(
    role => sub {
        my ($role, $coderef) = @_;
          return sub {
            if ( session->{role} && $role eq session->{role} ) {
                goto $coderef;
            }
            else {
                redirect '/access_denied';
            }
          }
        }
);

=head1 PREFIX /record

    All actions related to a publication record are handled under
    this prefix.

=cut

prefix '/myPUB/record' => sub {

=head2 GET /new

    Prints a list of available publication types + import form.
    Some fields are pre-filled.

=cut

    get '/new' => needs login => sub {
        my $type = params->{type};

        return template 'add_new' unless $type;

        my $data;
        my $id = new_publication();
        $data->{_id} = $id;
        my $user = h->getPerson( session->{personNumber} );
        $data->{department} = $user->{department};

        if ( $type eq "researchData" ) {
            $data->{doi} = h->config->{doi}->{prefix} . "/" . $id;
        }

        template "backend/forms/$type", $data;
    };

=head2 GET /edit/:id

    Display record for id.
    Checks if the user has permission the see/edit this record.

=cut

    get '/edit/:id' => needs login => sub {
        my $id = param 'id';

        forward '/' unless $id;
        my $rec;
        try {
            $rec = edit_publication($id);
        }
        catch {
            template 'error', { error => "Something went wrong: $_" };
        };

        if ($rec) {
            template "backend/forms/$rec->{type}", $rec;
        }
        else {
            template 'error', { error => "No publication with ID $id." };
        }
    };

=head2 POST /update

    Saves the record in the database.
    Checks if the user has the rights to update this record.
    Validation of the record is performed.

=cut

    post '/update' => needs login => sub {
        my $params = params;

        foreach my $key ( keys %$params ) {
            if ( ref $params->{$key} eq "ARRAY" ) {
                my $i = 0;
                foreach my $entry ( @{ $params->{$key} } ) {
                    $params->{ $key . "." . $i } = $entry, $i++;
                }
                delete $params->{$key};
            }
        }

        $params = h->nested_params($params);

        if ( ( $params->{department} and $params->{department} eq "" )
            or !$params->{department} )
        {
            $params->{department} = ();
            if ( session->{role} ne "super_admin" ) {
                my $person = h->getPerson( session->{personNumber} );
                foreach my $dep ( @{ $person->{department} } ) {
                    push @{ $params->{department} }, $dep->{id};
                }
            }
        }
        elsif ( $params->{department}
            and $params->{department} ne ""
            and ref $params->{department} ne "ARRAY" )
        {
            $params->{department} = [ $params->{department} ];
        }

        ( session->{role} eq "super_admin" )
            ? ( $params->{approved} = 1 )
            : ( $params->{approved} = 0 );

        $params->{creator} = session 'user' unless $params->{creator};

        my $result = update_publication($params);

        redirect '/myPUB';
    };

=head2 GET /return/:id

    Set status to 'returned'.
    Checks if the user has the rights to return this record.

=cut

    get '/return/:id' => needs login => sub {
        my $id  = params->{id};
        my $rec = h->publication->get($id);
        $rec->{status} = "returned";
        try {
            update_publication($rec);
        }
        catch {
            template "error", { error => "something went wrong" };
        };

        redirect '/myPUB';
    };

=head2 GET /delete/:id

    Deletes record with id. For admins only.

=cut

    get '/delete/:id' => needs role => 'super_admin' => sub {
        delete_publication( params->{id} );
        redirect '/myPUB';
    };

=head2 GET /preview/id

    Prints the frontdoor for every record.

=cut

    get '/preview/:id' => needs login => sub {
        my $id   = params->{id};
        my $hits = h->publication->get($id);
        $hits->{bag}
            = $hits->{type} eq "researchData" ? "data" : "publication";
        $hits->{style}
            = h->config->{store}->{default_fd_style} || "frontShort";
        $hits->{marked}  = 0;
        template 'frontend/frontdoor/record.tt', $hits;
    };

    get '/publish/:id' => needs login => sub {
        my $id     = params->{id};
        my $record = h->publication->get($id);

        #check if all mandatory fields are filled
        my $publtype = lc $record->{type};
        my $basic_fields
            = h->config->{forms}->{publicationTypes}->{$publtype}->{fields}
            ->{basic_fields};
        my $field_check = 1;

        foreach my $key ( keys %$basic_fields ) {
            next if $key eq "tab_name";
            if (    $basic_fields->{$key}->{mandatory}
                and $basic_fields->{$key}->{mandatory} eq "1"
                and ( !$record->{$key} || $record->{$key} eq "" ) )
            {
                $field_check = 0;
            }
        }

        $record->{status} = "public" if $field_check;
        my $result  = h->publication->add($record);
        my $publbag = Catmandu->store->bag('publication');
        $publbag->add($result);
        h->publication->commit;

        redirect '/myPUB';
    };
};

1;
