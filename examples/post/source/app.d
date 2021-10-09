import std.stdio;
import std.process;
import slack;

int main() {
	auto token = environment.get("SLACK_TOKEN");
	if (token is null) {
		writefln("Please set the environment variable SLACK_TOKEN");
		return 1;
	}

	auto slack = Slack(token);

	/*
	auto r = slack.postMessage("Hello from slack-d!");
	if (r)
		writefln("posted message to channel %s", slack.channel);
	else
		writefln("Oops - failed to post to %s: %s", slack.channel, r);
	*/

	auto r = slack.conversationsList();
	if (!r) {
		writefln("failed to get conversations list: %s", r);
		return 1;
	}

	r = slack.conversationsHistory("C02HAHW5SNQ-xxx");
	if (!r) {
		writefln("failed to get conversations history: %s", r);
		return 1;
	}
	return 0;
}
