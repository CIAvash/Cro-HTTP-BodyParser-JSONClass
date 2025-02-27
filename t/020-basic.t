#!/usr/bin/env raku

use Test;
use Cro::HTTP::Request;
use Cro::HTTP::Router;
use JSON::Class;
use Cro::HTTP::BodyParser::JSONClass;

sub body-text(Cro::HTTP::Response $r) {
    $r.body-byte-stream.list.map(*.decode('utf-8')).join
}


class TestClass does JSON::Class {
    has $.a;
    has $.b;
}

class MyParser does Cro::HTTP::BodyParser::JSONClass[TestClass] {
}

my $app = route {
    body-parser MyParser;

    post -> 'parser' {
        request-body -> $body {
            content 'text/plain', "test-parser: $body.^name(), a: $body.a(), b: $body.b()";
        }
    }
}
my $source = Supplier.new;
my $responses = $app.transformer($source.Supply).Channel;

my $t = TestClass.new(a => "lala", b => "po");
my $content = $t.to-json.encode;

{
my $req = Cro::HTTP::Request.new(:method<POST>, :target</parser>);
$req.append-header('Content-type', 'application/json');
$req.append-header('Content-length', $content.bytes);
$req.set-body-byte-stream(supply { emit $content });
$source.emit($req);
my $r =  $responses.receive;
is body-text($r), 'test-parser: TestClass, a: lala, b: po', 'The body-parser successfully created the correct class';
}

done-testing;

# vim: ft=raku
