import std.stdio;
import std.conv;
import std.process;
import slack;

int main() {
	auto token = environment.get("SLACK_TOKEN");
	if (token is null) {
		writefln("Please set the SLACK_TOKEN environment variable");
		return 1;
	}

	auto channelName = "random";

	auto slack = Slack(token, channelName);

	auto r = slack.postMessage("Hello from slack-d!");
	if (!r) {
		writefln("failed to post to %s: %s", slack.channel, r);
		return 1;
	}
	// writefln("posted message to channel %s: %s", slack.channel, r);

	r = slack.conversationsList();
	if (!r) {
		writefln("failed to get conversations list: %s", r);
		return 1;
	}

	string channelId;
	foreach (channel; r["channels"].array) {
		if (channel["name"].str == channelName) {
			writefln("found channel id for #%s: %s ", channel["name"].str, channel["id"].str);
			channelId = channel["id"].str;
			break;
		}
	}

	import core.time : seconds;

	auto oldest = Clock.currTime() - seconds(10);

	r = slack.conversationsHistory(channelId, oldest);
	if (!r) {
		writefln("failed to get conversations history: %s", r);
		return 1;
	}

	writefln("history: %s", r);

	foreach (message; r["messages"].array) {
		writefln("message: %s", message);
		auto ts = to!double(message["ts"].str);
		auto t = SysTime.fromUnixTime(to!long(ts));
		writefln("ts: %s (%s)", t, to!long(ts));
	}

	return 0;
}
