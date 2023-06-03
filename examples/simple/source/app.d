import std.datetime.systime : SysTime, Clock;
import std.process, std.stdio;
import std.conv : to;
import slack;

void main() {
    auto token = environment.get("SLACK_TOKEN");
    assert(token != null, "Please set the SLACK_TOKEN environment variable");

    // Create a Slack object using the given token.
    auto slack = Slack(token);

    writeln("Post 10 synchronous messages.");
    Response[] r1;
    auto t = Clock.currTime();
    foreach (n; 0..10)
        r1 ~= slack.postMessage(to!string(n) ~ " sync hello from slack-d !", false);
    auto d = Clock.currTime() - t;
    writefln("Took: %s", d);
    // foreach (ref r; r1) writeln(r);

    writeln("Post 10 asynchronous messages.");
    Response[10] r2;
    t = Clock.currTime();
    foreach (n; 0..10)
        r2[n] = slack.postMessage(to!string(n) ~ " async hello from slack-d !", true);
    d = Clock.currTime() - t;
    writefln("Took: %s", d);
    // foreach (ref r; r2) writeln(r.await);
}
