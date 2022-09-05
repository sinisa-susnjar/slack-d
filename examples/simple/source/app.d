import std.process, std.stdio;
import slack;

void main() {
	auto token = environment.get("SLACK_TOKEN");
	assert(token != null, "Please set the SLACK_TOKEN environment variable");

	// Create a Slack object using the given token.
	auto slack = Slack(token);

	// Post a message.
	auto r = slack.postMessage("Hello from slack-d !");
	writeln(r);
}
