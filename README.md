connection_bench
================

A quickly thrown together ruby script that can benchmark connection rates

To run, run the server process on some computer (eg. hostname is hostA)

    ruby server.rb
    
On a different computer, run the client process

    ruby client hostA
    
The connection rate is limited to 100 connections by default. Increase that like this.

    ruby client hostA 200
    
If you go too high, you'll run out of ephemeral ports and see connect rate drop to 0

You can also send concurrent connection attempts. Here's how you'd send 5 concurrent connections at a rate of 200 connections each.

    ruby client hostA 200 5
