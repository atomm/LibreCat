package App::Catalogue::Route::publication;

=head1 NAME App::Catalogue::Route::publication

Route handler for publications.

=cut

use Catmandu::Sane;
use Catmandu qw(:load export_to_string);
use Catmandu::Fix qw(expand);
use App::Helper;
use App::Catalogue::Controller::Permission;
use Dancer qw(:syntax);
use Encode qw(encode);
use Dancer::Plugin::Auth::Tiny;
use Dancer::Plugin::Email;
use LibreCat::Worker::DataCite;

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

All actions related to a publication record are handled under this prefix.

=cut

prefix '/librecat/record' => sub {

=head2 GET /new

Prints a list of available publication types + import form.

Some fields are pre-filled.

=cut
    get '/new' => needs login => sub {
        my $type = params->{type};
        my $user = h->get_person(session->{personNumber});
        my $edit_mode = params->{edit_mode} || $user->{edit_mode} || "";

        return template 'backend/add_new' unless $type;

        my $id = h->new_record('publication');
        # set some basic values
        my $data = {
            _id => $id,
            type => $type,
            department => $user->{department},
            creator => {
                id => session->{personNumber},
                login => session->{user},
            },
        };

        if ( $type eq "research_data" ) {
            $data->{doi} = h->config->{doi}->{prefix} . "/" . $id;
        }
        if(params->{lang}){
            $data->{lang} = params->{lang};
        }

        my $templatepath = "backend/forms";

        if(($edit_mode and $edit_mode eq "expert") or ($edit_mode eq "" and session->{role} eq "super_admin")){
            $templatepath .= "/expert";
        }

        $data->{new_record} = 1;

        template $templatepath . "/$type", $data;
    };

=head2 GET /edit/:id

Displays record for id.

Checks if the user has permission the see/edit this record.

=cut
    get '/edit/:id' => needs login => sub {
        my $id = param 'id';

        unless (p->can_edit($id, session->{user}, session->{role})) {
            status '403';
            forward '/access_denied', {referer => request->{referer}};
        }
        my $person = h->get_person(session->{personNumber});
        my $edit_mode = params->{edit_mode} || $person->{edit_mode};

        forward '/' unless $id;
        my $rec = h->publication->get($id);

        my $templatepath = "backend/forms";
        my $template = $rec->{type}. ".tt";
        if(($edit_mode and $edit_mode eq "expert") or (!$edit_mode and session->{role} eq "super_admin")){
            $templatepath .= "/expert";
            $edit_mode = "expert";
        }

        $rec->{return_url} = request->{referer} if request->{referer};
        if ($rec) {
            $rec->{edit_mode} = $edit_mode if $edit_mode;
            template $templatepath . "/$template", $rec;
        }
        else {
            template 'error', { error => "No publication with ID $id." };
        }
    };

=head2 POST /update

Saves the record in the database.

Checks if the user has the rights to update this record.

=cut
    post '/update' => needs login => sub {
        my $p = params;

        unless ($p->{new_record} or p->can_edit($p->{_id}, session->{user}, session->{role})) {
            status '403';
            forward '/access_denied';
        }
        delete $p->{new_record};

        $p = h->nested_params($p);

        my $old_status = $p->{status};

        my $result = h->update_record('publication', $p);
        #return to_dumper $result; # leave this here to make debugging easier

        if ($result->{type} =~ /^bi/ and $result->{status} eq "public" and $old_status ne "public") {
            $result->{host} = h->host;
            my $mail_body = export_to_string($result, 'Template', template => 'views/email/thesis_published.tt');

            try {
                email {
                    to => $result->{email},
                    subject => h->config->{thesis}->{subject},
                    body => $mail_body,
                    reply_to => h->config->{thesis}->{to},
                };
            } catch {
                error "Could not send email: $_";
            }
        }

        if ($result->{type} eq "research_data") {
            if ($result->{status} eq "submitted") {
                $result->{host} = h->host;
                my $mail_body = export_to_string($result, 'Template', template => 'views/email/rd_submitted.tt');

                try {
                    email {
                        to => h->config->{research_data}->{to},
                        subject => h->config->{research_data}->{subject},
                        body => $mail_body,
                        reply_to => h->config->{research_data}->{to},
                    };
                } catch {
                    error "Could not send email: $_";
                }
            }
            elsif ($result->{status} eq 'public' and $result->{doi} =~ /unibi\/\d+$/) {
                try {
                    my $registry = LibreCat::Worker::DataCite->new(user => h->config->{doi}->{user}, password => h->config->{doi}->{passwd});
                    $result->{host} = h->host;
                    my $datacite_xml = export_to_string($result, 'Template', template => 'views/export/datacite.tt');
                    $registry->work({
                        doi          => $result->{doi},
                        landing_url  => h->host ."/data/$result->{_id}",
                        datacite_xml => $datacite_xml
                    });
                } catch {
                    error "Could not register DOI: $_ -- $result->{_id}";
                }
            }
        }

        redirect '/librecat';
    };

=head2 GET /return/:id

Set status to 'returned'.

Checks if the user has the rights to edit this record.

=cut
    get '/return/:id' => needs login => sub {
        my $id  = params->{id};

        unless (p->can_edit($id, session->{user}, session->{role})) {
            status '403';
            forward '/access_denied';
        }

        my $rec = h->publication->get($id);
        $rec->{status} = "returned";
        h->update_record('publication', $rec);

        redirect '/librecat';
    };

=head2 GET /delete/:id

Deletes record with id. For admins only.

=cut
    get '/delete/:id' => needs role => 'super_admin' => sub {
        h->delete_record('publication', params->{id} );
        redirect '/librecat';
    };

=head2 GET /preview/id

Prints the frontdoor for every record.

=cut
    get '/preview/:id' => needs login => sub {
        my $id = params->{id};

        my $hits = h->publication->get($id);
        $hits->{bag} = $hits->{type} eq "researchData" ? "data" : "publication";
        $hits->{style} = h->config->{default_fd_style} || "default";
        $hits->{marked}  = 0;

        template 'frontdoor/record.tt', $hits;
    };

=head2 GET /internal_view/:id/:dumper

Prints internal view, optionally as data dumper.

For admins only!

=cut
    get qr{/internal_view/(\w{1,})/*} => needs role => 'super_admin' => sub {
        my ($id) = splat;

        return template 'backend/internal_view',
            {data => to_yaml h->publication->get($id)};
    };

=head2 GET /publish/:id

Publishes private records, returns to the list.

=cut
    get '/publish/:id' => needs login => sub {
        my $id = params->{id};

        unless (p->can_edit($id, session->{user}, session->{role})) {
            status '403';
            forward '/access_denied';
        }

        my $record = h->publication->get($id);
        my $old_status = $record->{status};

        #check if all mandatory fields are filled
        my $publtype;
        if ($record->{type} =~ /^bi[A-Z]/) {
            $publtype = "bithesis";
        } else {
            $publtype = lc($record->{type});
        }

        my $basic_fields = h->config->{forms}->{publication_types}->{$publtype}->{fields}->{basic_fields};
        my $field_check = 1;

        foreach my $key ( keys %$basic_fields ) {
            next if $key eq "tab_name";
            next if $key eq "bi_doctype";
            if($key =~ /author|editor|translator|supervisor/){
                if($basic_fields->{$key} and $basic_fields->{$key}->{mandatory}){
                    if(!$record->{$key}){
                        $field_check = 0;
                    }
                    elsif($basic_fields->{$key}->{multiple}){
                        foreach my $entry (@{$record->{$key}}){
                            unless ($entry->{first_name} and $entry->{last_name}){
                                $field_check = 0;
                            }
                        }
                    }
                    else{
                        unless ($record->{$key}->{first_name} and $record->{$key}->{last_name}){
                            $field_check = 0;
                        }
                    }
                }
            }
            elsif ( $basic_fields->{$key}->{mandatory} and $basic_fields->{$key}->{mandatory} eq "1"
                and ( !$record->{$key} || $record->{$key} eq "" ) )
            {
                $field_check = 0;
            }
        }

        $record->{status} = "public" if $field_check;
        h->update_record('publication', $record);

        if ($record->{type} =~ /^bi/ and $record->{status} eq "public" and $old_status ne "public") {
            $record->{host} = h->host;
            my $mail_body = export_to_string($record, 'Template', template => 'views/email/thesis_published.tt');

            try {
                email {
                    to => $record->{email},
                    subject => h->config->{thesis}->{subject},
                    body => $mail_body,
                    reply_to => h->config->{thesis}->{to},
                };
            } catch {
                error "Could not send email: $_";
            }
        }

        redirect '/librecat';
    };

=head2 GET /change_mode

Changes the layout of the edit form.

=cut
    post '/change_mode' => needs login => sub {
        my $mode = params->{edit_mode};
        my $params = params;

        $params->{file} = [$params->{file}] if ($params->{file} and ref $params->{file} ne "ARRAY");

        $params = h->nested_params($params);
        if($params->{file}){
            foreach my $fi (@{$params->{file}}){
                $fi = encode('UTF-8', $fi);
                $fi = from_json($fi);
                $fi->{file_json} = to_json($fi);
            }
        }

        Catmandu::Fix->new(fixes => [
            'publication_identifier()',
            'external_id()',
            'page_range_number()',
            'clean_preselects()',
            'split_field(nasc, " ; ")',
            'split_field(genbank, " ; ")',
            'split_field(keyword, " ; ")',
            'delete_empty()',
        ])->fix($params);

        my $path = "backend/forms/";
        $path .= "expert/" if $mode eq "expert";
        $path .= params->{type} . ".tt";

        template $path, $params;
    };

};

1;
