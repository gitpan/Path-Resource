#!perl -T

#use Test::More tests => 1;
use Test::More qw(no_plan);

BEGIN {
	use_ok( 'Path::Resource' );
}

my $rsc = new Path::Resource dir => "dir", uri => [ "http://hostname", "loc" ];
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir");
is($rsc->loc, "loc");
is($rsc->uri, "http://hostname/loc");

$rsc = $rsc->subdir("one");
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/one");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir/one");
is($rsc->loc, "loc/one");
is($rsc->uri, "http://hostname/loc/one");

$rsc = $rsc->subdir("two");
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/one/two");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir/one/two");
is($rsc->loc, "loc/one/two");
is($rsc->uri, "http://hostname/loc/one/two");

$rsc = $rsc->subfile("three.txt");
ok(!$rsc->is_dir);
ok($rsc->is_file);
is($rsc->path, "/one/two/three.txt");
is($rsc->file, "dir/one/two/three.txt");
eval { $rsc->dir }; ok($@);
is($rsc->loc, "loc/one/two/three.txt");
is($rsc->uri, "http://hostname/loc/one/two/three.txt");

eval { $rsc->subdir("impossible-file-subdir") }; ok($@);

$rsc = $rsc->parent;
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/one/two");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir/one/two");
is($rsc->loc, "loc/one/two");
is($rsc->uri, "http://hostname/loc/one/two");

$rsc = $rsc->subdir("four");
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/one/two/four");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir/one/two/four");
is($rsc->loc, "loc/one/two/four");
is($rsc->uri, "http://hostname/loc/one/two/four");

$rsc = $rsc->parent;
$rsc = $rsc->parent;
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/one");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir/one");
is($rsc->loc, "loc/one");
is($rsc->uri, "http://hostname/loc/one");

$rsc = $rsc->parent;
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir");
is($rsc->loc, "loc");
is($rsc->uri, "http://hostname/loc");

$rsc = $rsc->parent;
ok($rsc->is_dir);
ok(!$rsc->is_file);
is($rsc->path, "/");
eval { $rsc->file }; ok($@);
is($rsc->dir, "dir");
is($rsc->loc, "loc");
is($rsc->uri, "http://hostname/loc");

$rsc = $rsc->subfile("five.jpg");
ok(!$rsc->is_dir);
ok($rsc->is_file);
is($rsc->file, "dir/five.jpg");
eval { $rsc->dir }; ok($@);
is($rsc->loc, "loc/five.jpg");
is($rsc->uri, "http://hostname/loc/five.jpg");
