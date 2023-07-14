udping
======

a [love2d](https://love2d.org)-based network monitor.

this utility constantly messages a udp echo server that i run with incrementing numbers,
and measures the latency of those packets as they return. there is only one server, so
the results are heavily biased on distance.

the main utility is that it plays an audible alert when a packet is _lost_; this can
happen because of issues on either uploading or downloading (this tool does not distinguish
between them). it consumes very little traffic as it is primarily focused on tracking
connection quality and not bandwidth.

the release file is a standard [love2d executable](https://love2d.org/wiki/Game_Distribution#Creating_a_Windows_Executable).

### controls:

* d: enable/disable background droning based on latency. useful for monitoring during speed tests
* 1: dropped packet alert type 1
* 2: dropped packet alert type 2
* 3: no dropped packet alert (mute)

overall volume can be controlled by windows's built-in volume mixer.


### note

this tool, by default, communicates _directly to my server_; while no usage data is stored or tracked, please remember that it is _my server_ and be gentle.

if you would like to set up your own test system, set up a udp echo service and configure that ip address and port in `main.lua`.
