package Path::Resource;

use warnings;
use strict;

=head1 NAME

Path::Resource - URI/Path::Class combination.

=head1 VERSION

Version 0.01_1

=cut

our $VERSION = '0.01_1';

use URI::URL;
use Path::Class();
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(path dir_base loc_base http_uri_base));

=head1 SYNOPSIS

This is a development release; it works, but the interface could change at any time.

=over 4

=item new
=cut

sub new {
	my $self = bless {}, shift;
	$self->path(Path::Class::dir(shift || ""));
	local %_ = @_;
	$self->dir_base($_{dir_base});
	$self->loc_base($_{loc_base});
	$self->http_uri_base($_{http_uri_base});
	return $self;
}

=item clone
=cut

sub clone {
	my $self = shift;
	my $path = shift || $self->path;
	my $rsc = __PACKAGE__->new($path, dir_base => $self->dir_base,
		loc_base => $self->loc_base, http_uri_base => $self->http_uri_base);
	return $rsc;
}

=item subdir
=cut

sub subdir {
	my $self = shift;
	return $self->clone($self->path->subdir(@_));
}

=item parent
=cut

sub parent {
	my $self = shift;
	return $self->clone($self->path->parent);
}

=item dir
=cut

sub dir {
	my $self = shift;
	return $self->dir_base->subdir($self->path, @_);
}

=item file
=cut

sub file {
	my $self = shift;
	return $self->dir_base->file($self->path, @_);
}

=item loc
=cut

sub loc {
	my $self = shift;
	return $self->loc_base->subdir($self->path, @_);
}

=item http_uri
=cut

sub http_uri {
	my $self = shift;
	return $self->http_uri_base->clone unless @_;
	my $path = @_ ? $self->path->subdir(@_) : $self->path;
	$path = Path::Class::dir $self->http_uri_base->base->path, $path;
	$path = $path->relative('/');
	return URI::URL->new($path->stringify, $self->http_uri_base->abs);
}

=item http_loc
=cut

sub http_loc {
	my $self = shift;
	return $self->http_uri(@_)->abs->as_string;
}

=back 

=head1 AUTHOR

Robert Krimen, C<< <robertkrimen at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-path-resource at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Path-Resource>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Path::Resource

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Path-Resource>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Path-Resource>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Path-Resource>

=item * Search CPAN

L<http://search.cpan.org/dist/Path-Resource>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Path::Resource

__END__

package Archie::Path::Resource;

use strict;

use Archie::Utility;
use URI::URL;
use Path::Class();
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(path dir_base loc_base http_uri_base));

sub new {
	my $self = bless {}, shift;
	$self->path(Path::Class::dir(shift || ""));
	local %_ = @_;
	$self->dir_base($_{dir_base});
	$self->loc_base($_{loc_base});
	$self->http_uri_base($_{http_uri_base});
	return $self;
}

sub clone {
	my $self = shift;
	my $path = shift || $self->path;
	my $rsc = __PACKAGE__->new($path, dir_base => $self->dir_base,
		loc_base => $self->loc_base, http_uri_base => $self->http_uri_base);
	return $rsc;
}

sub subdir {
	my $self = shift;
	return $self->clone($self->path->subdir(@_));
}

sub parent {
	my $self = shift;
	return $self->clone($self->path->parent);
}

sub dir {
	my $self = shift;
	return $self->dir_base->subdir($self->path, @_);
}

sub file {
	my $self = shift;
	return $self->dir_base->file($self->path, @_);
}

sub loc {
	my $self = shift;
	return $self->loc_base->subdir($self->path, @_);
}

sub http_uri {
	my $self = shift;
	return $self->http_uri_base->clone unless @_;
	my $path = @_ ? $self->path->subdir(@_) : $self->path;
	$path = Path::Class::dir $self->http_uri_base->base->path, $path;
	$path = $path->relative('/');
	return URI::URL->new($path->stringify, $self->http_uri_base->abs);
}

sub http_loc {
	my $self = shift;
	return $self->http_uri(@_)->abs->as_string;
}

1;

__END__

sub new {
	my $self = bless {}, shift;
	$self->archie(shift);
#	my ($path, $trail, $base) = @_;
	my ($trail, $path) = @_;
	if (ref $trail eq "File::VirtualPath") {
		$self->virtual($trail);
	}
	elsif (ref $trail eq __PACKAGE__) {
		return $trail;
	}
	else {
		($trail, $path) = @$trail if ref $trail eq "ARRAY";
		$path = $self->archie->path unless $path;
		$self->virtual(new File::VirtualPath($path, undef, undef, $trail));
	}
	return $self;
}

sub trail {
	my $self = shift;
	return @_ ? $self->virtual->child_path_string(@_) : $self->virtual->path_string;
}

sub path {
	my $self = shift;
	return @_ ? $self->virtual->physical_child_path_string(@_) : $self->virtual->physical_path_string;
}

sub location {
	my $self = shift;
	return $self->archie->location($self->trail(@_));
}

sub httplocation {
	my $self = shift;
	return $self->archie->httplocation($self->trail(@_));
}

sub child {
	my $self = shift;
	return __PACKAGE__->new($self->archie, $self->virtual->child_path_obj(@_));
}

sub toJson {
	my $self = shift;
	return inspect { trail => $self->trail, path => $self->path };
}

1;
