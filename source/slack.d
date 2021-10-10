/// Main module for slack-d
module slack;

import std.net.curl, std.conv;

public import std.datetime.systime;
public import std.json;

/// Base Slack Web API URL.
package immutable slackApiUrl = "https://slack.com/api/";

/**
 * Contains the response from a Slack REST API call encoded as JSON.
 * See_Also: $(D std.json)
 */
struct Response {
	/// Returns `true` if the last API call succeeded, `false` otherwise.
	auto opCast(T : bool)() const { return _value["ok"].boolean; }
	/// Returns the JSON response as a string.
	auto toString() const { return toJSON(_value); }
	/// Assign another Response to this one.
	auto ref opAssign(inout Response rhs) { _value = rhs._value; return this; }
	/// Returns the value for the given key from the JSON response.
	auto opIndex(string key) const { return _value[key]; }
package:
	/// Response may only be constructed in this package.
	this(const char[] response) { _value = parseJSON(response); }
	@disable this();
private:
	JSONValue _value;
}

unittest {
	import std.exception, core.exception;
	auto r = Response("");
	assertThrown!JSONException(to!bool(r));
	assert(r.toString() == "null");

	r = Response(`{"ok":false}`);
	assert(r.toString() == `{"ok":false}`);
	assert(r["ok"].boolean == false);
	assert(to!bool(r) == false);

	r = Response(`{"ok":true}`);
	assert(r.toString() == `{"ok":true}`);
	assert(r["ok"].boolean == true);
	assert(to!bool(r) == true);

	auto r2 = Response(`{"ok":true}`);
	assert(r == r2);

	r = r2;
	assert(r == r2);
	assert(r2["ok"].boolean == true);
}

/**
 * Holds the authorization token and the current channel for further REST API calls.
 */
struct Slack {
	/**
	 * Constructs a new Slack object and stores the token and channel for later use.
	 * Params:
	 *   token = Slack BOT token to use for REST API authorization.
	 *   channel = Channel to use. Default is `general`.
	 */
	this(string token, string channel = "general") {
		_token = token;
		_channel = channel;
		_urlHeader = HTTP();
		_urlHeader.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		_jsonHeader = HTTP();
		_jsonHeader.addRequestHeader("Content-Type", "application/json");
		_jsonHeader.addRequestHeader("Authorization", "Bearer " ~ _token);
	}	// ctor()

	/**
	 * Sends a message to a channel.
	 * Params:
	 *   msgString = Message string
	 * Returns: JSON response from REST API endpoint.
	 * See_Also: $(LINK https://api.slack.com/methods/chat.postMessage)
	 */
	Response postMessage(string msgString) {
		return Response(post(slackApiUrl ~ "chat.postMessage",
						`{"channel":"` ~ _channel ~ `", "attachments": [{"text":"` ~ msgString ~ `","color":"good"}]}`,
						_jsonHeader));
	}	// postMessage()

	/**
	 * Fetches a conversation's history of messages and events.
	 * Params:
	 *   channelId = Conversation ID to fetch history for.
	 *   oldest = SysTime of oldest entry to look for (default=0)
	 *   latest = SysTime of latest entry to look for (default=now)
	 * Returns: JSON response from REST API endpoint.
	 * See_Also: $(LINK https://api.slack.com/methods/conversations.history)
	 */
	Response conversationsHistory(string channelId, SysTime oldest = SysTime(), SysTime latest = SysTime()) {
		string[string] data = ["token": _token, "channel": channelId];
		if (oldest != SysTime.init) data["oldest"] = to!string(oldest.toUnixTime());
		if (latest != SysTime.init) data["latest"] = to!string(latest.toUnixTime());
		return Response(post(slackApiUrl ~ "conversations.history", data, _urlHeader));
	}

	/**
	 * Lists all channels in a Slack team.
	 * Returns: JSON response from REST API endpoint.
	 * See_Also: $(LINK https://api.slack.com/methods/conversations.list)
	 */
	Response conversationsList() {
		return Response(post(slackApiUrl ~ "conversations.list",
						["token": _token, "exclude_archived": "true"], _urlHeader));
	}

	/// Sets the current channel.
	@property void channel(string channel) { _channel = channel; }
	/// Returns the current channel.
	@property string channel() { return _channel; }

private:
	HTTP _jsonHeader, _urlHeader;
	string _channel, _token;
}

unittest {
	import std.process, std.format, std.system, core.cpuid;
	import std.stdio;

	auto token = environment.get("SLACK_TOKEN");
	assert(token !is null, "please define the SLACK_TOKEN environment variable!");

	auto slack = Slack(token);

	auto r = slack.postMessage(format("OS: %s (%s) CPU: %s %s with %s cores (%s threads)",
							os, endian, vendor, processor, coresPerCPU, threadsPerCPU));
	assert(to!bool(r), to!string(r));

	r = slack.conversationsList();
	assert(to!bool(r), to!string(r));

	string channelId;
	foreach (channel; r["channels"].array)
		if (channel["name"].str == slack.channel)
			channelId = channel["id"].str;
	assert(channelId.length > 0, to!string(r));
	writefln("channel: %s", channelId);

	import core.time : seconds;
	r = slack.conversationsHistory(channelId, Clock.currTime() - seconds(10));
	writefln("r: %s", r);
	assert(to!bool(r), to!string(r));

	// TODO: check if message we sent is in history
	foreach (message; r["messages"].array)
		writefln("message: %s", message);

	slack.channel = "some_channel";
	assert(slack.channel == "some_channel");
}
