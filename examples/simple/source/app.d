import std.stdio;
import slack;

void main() {
	// Create a Slack object using the given token.
	auto slack = Slack("xoxb-YOUR-BOT-TOKEN-HERE");

	// Post a message.
	auto r = slack.postMessage("Hello from slack-d !");
	writeln(r);
}
