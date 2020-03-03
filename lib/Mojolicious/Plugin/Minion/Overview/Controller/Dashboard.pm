package Mojolicious::Plugin::Minion::Overview::Controller::Dashboard;
use Mojo::Base 'Mojolicious::Controller';

=head2 search

Show dashboard metrics

=cut

sub search {
    my $self = shift;

    my $dashboard = $self->app->minion_overview->dashboard;

    return $self->render('minion_overview/dashboard/search',
        cards   => $dashboard->{ cards },
        workers => $dashboard->{ workers },
    );
}

1;
