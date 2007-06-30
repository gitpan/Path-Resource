package Path::Resource::Base;

use warnings;
use strict;

=head1 NAME

Path::Resource::Base - A resource base for a Path::Resource object

=cut

use Path::Lite;
use Path::Class();
use Scalar::Util qw(blessed);
use URI;

use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors(qw(dir loc uri));

=over 4

=item Path::Resource::Base->new

=cut

sub new {
	my $self = bless {}, shift;
	local %_ = @_;
	my $dir = $_{dir};
	$dir = Path::Class::dir($dir) unless blessed $dir && $dir->isa("Path::Class::Dir");
	my $loc = $_{loc};
	$loc = new Path::Lite($loc) unless blessed $loc && $loc->isa("Path::Lite");
	my $uri = $_{uri};
	$uri = new URI($uri) unless blessed $uri && $uri->isa("URI");
	my $uri_path = $uri->path;
	$uri->path('');
	if ($uri_path && $loc->branch) {
		$loc = new Path::Lite($uri_path, $loc->path);
	}
	$self->dir($dir);
	$self->loc($loc);
	$self->uri($uri);
	return $self;
}

=item $base_rsc->clone

=cut

sub clone {
	my $self = shift;
	return __PACKAGE__->new(dir => $self->dir, loc => $self->loc->clone, uri => $self->uri->clone);
}

=item $base_rsc->uri

=item $base_rsc->loc

=item $base_rsc->dir

=cut

1;
