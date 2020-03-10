package Mojolicious::Plugin::Minion::Overview;
use Mojo::Base 'Mojolicious::Plugin';

use Mojolicious::Plugin::Minion::Overview::Facade;

use Mojo::ByteStream 'b';
use Mojo::Date;
use Mojo::File 'path';

our $VERSION = '0.1.0';


=head2 register

Register the plugin and defined the routes

=cut

sub register {
    my ($self, $app, $config) = @_;

    # TODO: Find out why the connection is dropped
    # my $minion_overview = Mojolicious::Plugin::Minion::Overview::Facade->load($app->minion);
    $app->helper(minion_overview => sub { Mojolicious::Plugin::Minion::Overview::Facade->load($app->minion) });

    $app->helper(overview_job_status => sub {
        my ($c, $status) = @_;

        my $html = sprintf('<span class="fa fa-pause-circle text-muted" title="%s"></span>', $status);

        if ($status eq 'finished') {
            $html = sprintf('<span class="fa fa-check-circle text-success" title="%s"></span>', $status);
        } elsif ($status eq 'failed') {
            $html = sprintf('<span class="fa fa-times-circle text-danger" title="%s"></span>', $status);
        } elsif ($status eq 'active') {
            $html = sprintf('<span class="fa fa-play-circle text-warning" title="%s"></span>', $status);
        }

        return b($html);
    });

    $app->helper(overview_job_date => sub {
        my ($c, $timestamp) = @_;

        my $date = Mojo::Date->new($timestamp);

        return $date->to_datetime;
    });

    push(@{ $app->routes->namespaces }, 'Mojolicious::Plugin::Minion::Overview::Controller');

    # Config
    my $prefix = $config->{route} // $app->routes->route('minion-overview');
    $prefix->to(return_to => $config->{return_to} // '/');

    # Static files
    my $resources = path(__FILE__)->sibling('Overview', 'resources');
    push @{$app->static->paths}, $resources->child('public')->to_string;

    # Templates
    push @{$app->renderer->paths}, $resources->child('templates')->to_string;

    # Set date
    $prefix->get('/date/:date')
        ->to(controller => 'Overview', action => 'setDate')
        ->name('minion_overview.overview.set_date');

    # Dashboard
    $prefix->get('/')
        ->to(controller => 'Dashboard', action => 'search');

    my $dashboard = $prefix->route('dashboard')
        ->to(controller => 'Dashboard');

        $dashboard->get('/')->to(action => 'search')
            ->name('minion_overview.dashboard');

        $dashboard->get('overview')->to(action => 'overview')
            ->name('minion_overview.dashboard.overview');

        $dashboard->get('workers')->to(action => 'workers')
            ->name('minion_overview.dashboard.workers');

    # Metrics
    my $metrics = $prefix->route('metrics')
        ->to(controller => 'Metrics');

        $metrics->get('/')->to(action => 'search')
            ->name('minion_overview.metrics');

        my $metrics_jobs = $metrics->route('jobs')
            ->to(controller => 'Metrics::Jobs');

            $metrics_jobs->get(':job')->to(action => 'show')
                ->name('minion_overview.metrics.jobs.show');

    # Recent Jobs
    my $failed_jobs = $prefix->route('failed-jobs')
        ->to(controller => 'FailedJobs');

        $failed_jobs->get('/')->to(action => 'search')
            ->name('minion_overview.failed_jobs');

    # Jobs
    my $jobs = $prefix->route('jobs')
        ->to(controller => 'Jobs');

        $jobs->get('/')->to(action => 'search')
            ->name('minion_overview.jobs');

        $jobs->get('/:id')->to(action => 'show')
            ->name('minion_overview.jobs.show');

        $jobs->get('/:id/retry')->to(action => 'retry')
            ->name('minion_overview.jobs.retry');


    # API
    my $api = $prefix->route('api');

        # Metrics
        my $api_metrics = $api->route('metrics');

            # Jobs
            my $api_metrics_jobs = $api_metrics->route('jobs')
                ->to(controller => 'API::Metrics::Jobs');

                $api_metrics_jobs->get('/:job/runtime')->to(action => 'runtime')
                    ->name('minion_overview.api.metrics.jobs.runtime');

                $api_metrics_jobs->get('/:job/throughput')->to(action => 'throughput')
                    ->name('minion_overview.api.metrics.jobs.throughput');
}

1;
