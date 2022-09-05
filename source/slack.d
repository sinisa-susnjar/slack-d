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
	}	// ctor()

	/**
	 * Sends a message to a channel.
	 * Params:
	 *   msgString = Plain message string
	 * Returns: JSON response from REST API endpoint.
	 * See_Also: $(LINK https://api.slack.com/methods/chat.postMessage)
	 */
	Response postMessage(string msgString) const {
		string[string] data = ["token": _token, "channel": _channel, "text": msgString];
		auto http = HTTP();
		http.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		return Response(post(slackApiUrl ~ "chat.postMessage", data, http));
	}	// postMessage()

	/**
	 * Sends a message to a channel.
	 * Params:
	 *   jsonMsg = Message containing either "attachments" or "blocks" for more elaborate formatting
	 * Returns: JSON response from REST API endpoint.
	 * See_Also: $(LINK https://api.slack.com/methods/chat.postMessage)
	 */
	Response postMessage(JSONValue jsonMsg) const {
		string[string] data = ["token": _token, "channel": _channel];
		if ("attachments" in jsonMsg)
			data["attachments"] = toJSON(jsonMsg["attachments"]);
		else if ("blocks" in jsonMsg)
			data["blocks"] = toJSON(jsonMsg["blocks"]);
		else
			assert(0, `missing "attachment" or "blocks"`);
		auto http = HTTP();
		http.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		return Response(post(slackApiUrl ~ "chat.postMessage", data, http));
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
	Response conversationsHistory(string channelId, SysTime oldest = SysTime(), SysTime latest = SysTime()) const {
		string[string] data = ["token": _token, "channel": channelId];
		if (oldest != SysTime.init) data["oldest"] = to!string(oldest.toUnixTime());
		if (latest != SysTime.init) data["latest"] = to!string(latest.toUnixTime());
		auto http = HTTP();
		http.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		return Response(post(slackApiUrl ~ "conversations.history", data, http));
	}

	/**
	 * Lists all channels in a Slack team.
	 * Returns: JSON response from REST API endpoint.
	 * See_Also: $(LINK https://api.slack.com/methods/conversations.list)
	 */
	Response conversationsList() const {
		auto http = HTTP();
		http.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		return Response(post(slackApiUrl ~ "conversations.list",
						["token": _token, "exclude_archived": "true"], http));
	}

	/// Sets the current channel.
	@property void channel(string channel) { _channel = channel; }
	/// Returns the current channel.
	@property string channel() const { return _channel; }

private:
	string _channel, _token;
}

unittest {
	import std.process, std.format, std.system, core.cpuid, std.uuid;

	auto token = environment.get("SLACK_TOKEN");
	assert(token !is null, "please define the SLACK_TOKEN environment variable!");

	auto slack = Slack(token);

	auto msg = format("%s OS: %s (%s) CPU: %s %s with %s cores (%s threads)",
					randomUUID(), os, endian, vendor, processor, coresPerCPU, threadsPerCPU);
	auto r = slack.postMessage(msg);
	assert(to!bool(r), to!string(r));

	auto attachments = `{"attachments":[{
			"fallback": "A message with more elaborate formatting",
			"pretext": "` ~ msg ~ `",
			"title": "Don't click here!",
			"title_link": "https://youtu.be/dQw4w9WgXcQ",
			"text": "You know the rules and so do I",
			"color": "#7CD197",
			"image_url": "https://assets.amuniversal.com/086aac509ee3012f2fe600163e41dd5b"
			}]}`;
	r = slack.postMessage(parseJSON(attachments));
	assert(to!bool(r), to!string(r));

	auto blocks = `{"blocks":[
			{
				"type": "header",
				"text": {
					"type": "plain_text",
					"text": "` ~ msg ~ `",
					"emoji": true
				}
			},
			{
				"type": "section",
				"fields": [
					{
						"type": "mrkdwn",
						"text": "*Type:*\nPaid Time Off"
					},
					{
						"type": "mrkdwn",
						"text": "*Created by:*\n<example.com|Fred Enriquez>"
					}
				]
			},
			{
				"type": "section",
				"fields": [
					{
						"type": "mrkdwn",
						"text": "*When:*\nAug 10 - Aug 13"
					},
					{
						"type": "mrkdwn",
						"text": "*Type:*\nPaid time off"
					}
				]
			},
			{
				"type": "section",
				"fields": [
					{
						"type": "mrkdwn",
						"text": "*Hours:*\n16.0 (2 days)"
					},
					{
						"type": "mrkdwn",
						"text": "*Remaining balance:*\n32.0 hours (4 days)"
					}
				]
			},
			{
				"type": "section",
				"text": {
					"type": "mrkdwn",
					"text": "<https://example.com|View request>"
				}
			},
			{
				"type": "divider"
			},
			{
				"type": "section",
				"text": {
					"type": "mrkdwn",
					"text": "Pick a date for the deadline."
				},
				"accessory": {
					"type": "datepicker",
					"initial_date": "1990-04-28",
					"placeholder": {
						"type": "plain_text",
						"text": "Select a date",
						"emoji": true
					},
					"action_id": "datepicker-action"
				}
			},
			{
				"type": "section",
				"text": {
					"type": "mrkdwn",
					"text": "Section block with a timepicker"
				},
				"accessory": {
					"type": "timepicker",
					"initial_time": "13:37",
					"placeholder": {
						"type": "plain_text",
						"text": "Select time",
						"emoji": true
					},
					"action_id": "timepicker-action"
				}
			},
			{
				"type": "section",
				"text": {
					"type": "mrkdwn",
					"text": "This is a section block with an accessory image."
				},
				"accessory": {
					"type": "image",
					"image_url": "https://pbs.twimg.com/profile_images/625633822235693056/lNGUneLX_400x400.jpg",
					"alt_text": "cute cat"
				}
			},
			{
				"type": "divider"
			},
			{
				"type": "image",
				"image_url": "https://i1.wp.com/thetempest.co/wp-content/uploads/2017/08/The-wise-words-of-Michael-Scott-Imgur-2.jpg?w=1024&ssl=1",
				"alt_text": "inspiration"
			}
		]}`;

	r = slack.postMessage(parseJSON(blocks));
	assert(to!bool(r), to!string(r));

	r = slack.conversationsList();
	assert(to!bool(r), to!string(r));

	import std.range.primitives;

	string channelId;
	foreach (channel; r["channels"].array)
		if (channel["name"].str == slack.channel)
			channelId = channel["id"].str;
	assert(channelId.length > 0, to!string(r));

	import core.time : seconds;
	r = slack.conversationsHistory(channelId, Clock.currTime() - seconds(10));
	assert(to!bool(r), to!string(r));

	auto foundAttachments = false;
	auto foundBlocks = false;
	auto foundPlain = false;
	foreach (message; r["messages"].array) {
		if ("text" in message && message["text"].str == msg)
			foundPlain = true;
		if ("attachments" in message && message["attachments"][0]["pretext"].str == msg)
			foundAttachments = true;
		if ("blocks" in message && "text" in message["blocks"][0] && message["blocks"][0]["text"]["text"].str == msg)
			foundBlocks = true;
	}
	assert(foundPlain, "did not find plain message in history");
	assert(foundBlocks, "did not find blocks message in history");
	assert(foundAttachments, "did not find attachments message in history");

	slack.channel = "some_channel";
	assert(slack.channel == "some_channel");
}

unittest {
	import std.process, std.format, std.system, core.cpuid, std.uuid;

	auto token = environment.get("SLACK_TOKEN");
	assert(token !is null, "please define the SLACK_TOKEN environment variable!");

	auto slack = Slack(token);

	auto msg = `this&that \\[@\\] an!// '; < ? >> , <~ ~ @ # \\} \\{ * & % $ ! >~<`;
	auto r = slack.postMessage(msg);
	assert(to!bool(r), to!string(r));

	auto attachments = `{"attachments":[{
			"fallback": "` ~ msg ~ `",
			"pretext": "` ~ msg ~ `",
			"text": "` ~ msg ~ `",
			"color": "#7CD197"
			}]}`;
	r = slack.postMessage(parseJSON(attachments));
	assert(to!bool(r), to!string(r));
}
