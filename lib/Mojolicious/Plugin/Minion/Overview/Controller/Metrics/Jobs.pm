package Mojolicious::Plugin::Minion::Overview::Controller::Metrics::Jobs;
use Mojo::Base 'Mojolicious::Controller';

sub show {
    my $self = shift;
    
    my $runtime = $self->app->minion_overview->job_runtime_metrics($self->param('job'));
    my $throughput = $self->app->minion_overview->job_throughput_metrics($self->param('job'));

    return $self->render('overview/metrics/jobs/show',
        job         => $self->param('job'),
        runtime     => $runtime,
        throughput  => $throughput,
    );
}

1;
