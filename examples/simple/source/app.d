import std.datetime.systime : SysTime, Clock;

import std.process, std.stdio;
import std.conv : to;
import slack;

private mixin template SlackDemo(alias slack) {
  void post(bool async)
  {
    writefln("Post 10 %ssynchronous messages.", async ? "a" : "");
    Response[10] r;
    immutable t = Clock.currTime();
    foreach (n; 0 .. 10)
      r[n] = slack.postMessage(to!string(n) ~ (async
          ? " a" : " ") ~ "sync hello from slack-d !", async);
    auto d = Clock.currTime() - t;
    writefln("Took: %s", d);
    // Uncomment the next line if you want to see the (async) responses.
    // foreach (ref r; r2) writeln(r.await);
  }
}

void main()
{
  immutable token = environment.get("SLACK_TOKEN");
  assert(token != null, "Please set the SLACK_TOKEN environment variable");

  // Create a Slack object using the given token.
  immutable slack = Slack(token, "bottest");

  // Check if slacking is possible by using the slack.test api endpoint.
  auto res = slack.test();
  if (!res)
    writefln("cannot slack: %s", res);

  // Use a mixin template just for fun :)
  mixin SlackDemo!slack;
  post(false);
  post(true);
}
