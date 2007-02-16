package Path::Resource;

use warnings;
use strict;

=head1 NAME

Path::Resource - URI/Path::Class combination.

=head1 VERSION

Version 0.01_2

=cut

our $VERSION = '0.01_2';

use URI::URL;
use URI::Split qw(uri_split uri_join);
use Path::Class();
use Carp;
use Scalar::Util qw(blessed);
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(path base_file base_dir base_loc base_uri));

=head1 SYNOPSIS

  use Path::Resource;

  # Map a resource on the local disk to a URI.
  # Its (disk) directory is "/var/dir" and its uri is "http://hostname/loc"
  my $rsc = new Path::Resource dir => "/var/dir", uri => [ "http://hostname", "loc" ];
  # uri: http://hostname/loc 
  # dir: /var/dir

  my $subrsc = $rsc->subdir("subdir");
  # uri: http://hostname/loc/subdir
  # dir: /var/dir/subdir

  my $filersc = $rsc->subfile("info.txt");
  # uri: http://hostname/loc/subdir/info.txt
  # file: /var/dir/subdir/info.txt

  my $filesize = -s $filersc->file;

  redirect($filersc->uri);

=head1 METHODS

=over 4

=item $rsc = Path::Resource->new( ... );

=item $rsc = Path::Resource->new( uri => <uri> dir => <dir>, ... );

Returns a new C<Path::Resource> object. A resource can either be a file resource
or a directory resource.

The constructor accepts the following:

=over 4
  
uri => C<URI>. The base uri of the resource. This can be or will become a C<URI> object. This can also be a uri-like string, e.g. "http://example.com/..."

uri => [ C<URI>, <loc> ]. The base uri of the resource. This option will set C<uri> and C<loc> at the same time. For example, if you pass C<uri => [ "http://example.com", "/loc" ]>, then the final uri will be C<http://example.com/loc> and the final loc will be C</loc>.

dir => The base dir of the resource. This can be or will become a C<Path::Class::Dir> object.

file => The file of the resource. This can be or will become a C<Path::Class::File> object.

path => The starting path of the resource, relative to dir and uri. Adding path to the base uri/base dir will yield the actual uri/dir.

=back

Note: Passing the file object will mark the resource as being a file resource object (You can't subdir or subfile a file resource.

=cut

sub new {
	my $self = bless {}, shift;
	local %_ = @_;
	my ($path, $file, $dir, $loc, $uri);

	$path = defined $_{path} ? $_{path} : "";
	$path = Path::Class::dir $path;

	$dir = defined $_{dir} ? $_{dir} : "";
	$dir = Path::Class::dir $dir;

	if ($_{file}) {
		$file = $_{file};
		$path = Path::Class::file $path;
	}
	else {
		$path = Path::Class::dir $path;
	}

	$uri = $_{uri};
	if (ref $uri eq "ARRAY") {
		($uri, $loc) = @$uri;
		$uri = new URI::URL($uri) unless blessed $uri;
	        my ($scheme, $auth, $path, $query, $frag) = uri_split($uri);
		$path = Path::Class::dir $path, $loc;
	        $uri = uri_join($scheme, $auth, $path, $query, $frag);
		$uri = URI::URL->new($uri);
	}
	else {
		$uri = $_{uri};
		$uri = new URI::URL($uri) unless blessed $uri;
	}

	if ($_{loc} || ! $loc) {
		$loc = defined $_{loc} ? $_{loc} : "";
	}
	$loc = Path::Class::dir $loc;

	$self->path($path);
	$self->base_file($file);
	$self->base_dir($dir);
	$self->base_loc($loc);
	$self->base_uri($uri);

	return $self;
}

=item $rsc->is_file

Returns true if the $rsc maps to a file, false otherwise.

=cut 

sub is_file { return ! shift->path->is_dir }

=item $rsc->is_dir

Returns true if the $rsc maps to a directory, false otherwise.

=cut

sub is_dir { return shift->path->is_dir }

=item $clonersc = $rsc->clone 

=item $clonersc = $rsc->clone(path => <path>, ...);

Returns a new C<Path::Resource> object that is a clone of $rsc; optionally changing any path
file, dir, loc, or uri components.

=cut

sub clone {
	my $self = shift;
	my $path = shift || $self->path;
	local %_ = @_;
	my $rsc = __PACKAGE__->new(path => $path,
		file => exists $_{file} ? $_{file} : $self->base_file,
		dir => exists $_{dir} ? $_{dir} : $self->base_dir,
		loc => exists $_{loc} ? $_{loc} : $self->base_loc,
		uri => exists $_{uri} ? $_{uri} : $self->base_uri);
	return $rsc;
}

=item $subrsc = $rsc->subdir( <dir1>, <dir2>, ... )

Returns a new C<Path::Resource> object representing a subdirectory resource of $rsc.

=cut

sub subdir {
	my $self = shift;
	croak "Not a dir" unless $self->is_dir;
	return $self->clone($self->path->subdir(@_));
}

=item $subfile = $rsc->subfile( <dir1>, <dir2>, ..., <file> )

=cut

sub subfile {
	my $self = shift;
	croak "Not a dir" unless $self->is_dir;
	my $file = $self->dir->file(@_);
	my $path = $self->path->file(@_);
	return $self->clone($path, file => $file);
}

=item $parentrsc = $rsc->parent

=cut

sub parent {
	my $self = shift;
	return $self->clone($self->path->parent, file => undef);
}

=item $dir = $rsc->dir

=cut

sub dir {
	my $self = shift;
	croak "Not a dir resource" unless $self->is_dir;
	return $self->base_dir->subdir($self->path, @_);
}

=item $file = $rsc->file

=cut

sub file {
	my $self = shift;
	return $self->base_file if $self->is_file;
	croak "Not a file" unless @_;
	return $self->base_dir->file($self->path, @_);
}

=item $loc = $rsc->loc

=cut

sub loc {
	my $self = shift;
	return $self->base_loc->subdir($self->path, @_);
}


=item $uri = $rsc->uri

=cut

sub uri {
	my $self = shift;
	my $path = @_ ? $self->path->subdir(@_) : $self->path;
	$path = Path::Class::dir $self->base_uri->path, $path;
	$path = $path->relative('/');
        my ($scheme, $auth, undef, $query, $frag) = uri_split($self->base_uri);
        my $uri = uri_join($scheme, $auth, $path, $query, $frag);
	return URI::URL->new($uri);
}

=back 

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

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
