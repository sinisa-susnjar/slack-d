import std.process, std.stdio;

import slack;

int main() {
	auto token = environment.get("SLACK_TOKEN");
	if (token is null) {
		writefln("Please set the SLACK_TOKEN environment variable");
		return 1;
	}

	auto channelName = "random";

	// Create a Slack object with the given `token` and `channelName`.
	auto slack = Slack(token, channelName);

	// Post a message to the channel.
	auto r = slack.postMessage("Hello from slack-d!");
	if (!r) {
		writefln("failed to post to %s: %s", slack.channel, r);
		return 1;
	}

	// Get a list of channels from Slack.
	r = slack.conversationsList();
	if (!r) {
		writefln("failed to get conversations list: %s", r);
		return 1;
	}

	// Find the channel #id for the channel.
	foreach (channel; r["channels"].array) {
		if (channel["name"].str == channelName) {
			writefln("found channel id for #%s: %s ", channel["name"].str, channel["id"].str);

			import core.time : seconds;
			// Get the history for the last 10 seconds.
			r = slack.conversationsHistory(channel["id"].str, Clock.currTime() - seconds(10));
			if (!r) {
				writefln("failed to get conversations history: %s", r);
				return 1;
			}

			// Print all messages and events for the last 10 seconds.
			foreach (message; r["messages"].array)
				writefln("message: %s", message);
		}
	}

	return 0;
}
