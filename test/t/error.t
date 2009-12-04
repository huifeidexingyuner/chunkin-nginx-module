# vi:filetype=perl

use lib 'lib';
use Test::Nginx::Socket;

plan tests => $Test::Nginx::Socket::RepeatEach * 2 * blocks();

no_diff;

run_tests();

__DATA__

=== TEST 1: sanity
--- config
    location /main {
        echo hi;
    }
--- request
GET /main
--- response_body
hi



=== TEST 2: good chunked body
--- config
    chunkin on;
    location /main {
        echo_request_body;
    }
--- more_headers
Transfer-Encoding: chunked
--- request eval
"POST /main
5\r
hello\r
0\r
\r
"
--- response_body chomp
hello



=== TEST 3: chunk size too small
--- config
    chunkin on;
    location /main {
        echo_request_body;
    }
--- more_headers
Transfer-Encoding: chunked
--- request eval
"POST /main
4\r
hello\r
0\r
\r
"
--- error_code: 400
--- response_body_like: 400 Bad Request



=== TEST 4: chunk size too big (but accepted by ragel DFA)
--- config
    chunkin on;
    location /main {
        echo_request_body;
    }
--- more_headers
Transfer-Encoding: chunked
--- request eval
"POST /main
6\r
hello\r
0\r
\r
"
--- response_body eval: "hello\r"



=== TEST 5: chunk size bigger but still accepted by ragel DFA
--- config
    chunkin on;
    location /main {
        echo_request_body;
    }
--- more_headers
Transfer-Encoding: chunked
--- request eval
"POST /main
7\r
hello\r
0\r
\r
"
--- response_body eval: "hello\r\n"



=== TEST 6: chunk size WAY too big and rejected by ragel DFA
--- config
    chunkin on;
    location /main {
        echo_request_body;
    }
--- more_headers
Transfer-Encoding: chunked
--- request eval
"POST /main
8\r
hello\r
0\r
\r
"
--- error_code: 400
--- response_body_like: 400 Bad Request



=== TEST 7: missing LF after data chunk
--- config
    chunkin on;
    location /main {
        echo_request_body;
    }
--- more_headers
Transfer-Encoding: chunked
--- request eval
"POST /main
5\r
hello\r0\r
\r
"
--- error_code: 400
--- response_body_like: 400 Bad Request



=== TEST 8: missing CR after data chunk
--- config
    chunkin on;
    location /main {
        echo_request_body;
    }
--- more_headers
Transfer-Encoding: chunked
--- request eval
"POST /main
5\r
hello
0\r
\r
"
--- error_code: 400
--- response_body_like: 400 Bad Request



=== TEST 9: missing CRLF after data chunk
--- config
    chunkin on;
    location /main {
        echo_request_body;
    }
--- more_headers
Transfer-Encoding: chunked
--- request eval
"POST /main
5\r
hello0\r
\r
"
--- error_code: 400
--- response_body_like: 400 Bad Request



=== TEST 10: 2 zero chunks
--- config
    chunkin on;
    location /main {
        echo_request_body;
    }
--- more_headers
Transfer-Encoding: chunked
--- request eval
"POST /main
0\r
\r
0\r
\r
"
--- response_body



=== TEST 11: 1 00 chunk and 1 zero chunk
--- config
    chunkin on;
    location /main {
        #echo "length: $http_content_length";
        echo_request_body;
    }
--- more_headers
Transfer-Encoding: chunked
--- request eval
"POST /main
00\r
\r
0\r
\r
"
--- response_body



=== TEST 12: 1 00 chunk and 1 zero chunk
--- config
    chunkin on;
    location /main {
        echo_request_body;
    }
--- more_headers
Transfer-Encoding: chunked
--- request eval
"POST /main
10\r
helloworld,hello\r
00\r
\r
0\r
\r
"
--- response_body: helloworld,hello
