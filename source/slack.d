import std.net.curl;
import std.stdio;

public import std.json;

struct Slack {
	this(string slackToken) {
		writefln("Slack.this(slackToken: %s)", slackToken);
		this.slackToken = slackToken;
	}
	bool postMessage(string msgString) {
		writefln("Slack.postMessage(msgString: %s)", msgString);
		return false;
	}
private:
	string slackToken;
}
