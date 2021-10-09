import std.net.curl;
import std.stdio;

public import std.json;

/**
 * Response type. Contains the response from a Slack REST API
 * call encoded as JSON.
 * See_Also: std.json
 */
struct Response {
	/// Returns `true` if the last API call succeeded, `false` otherwise.
	auto opCast(T : bool)() const { return _value["ok"].boolean; }
	/// Returns the JSON response as a string.
	auto toString() const { return toJSON(_value); }
	/// Assign another Response to this one.
	auto ref opAssign(inout Response rhs) { _value = rhs._value; return this; }
	alias _value this;
package:
	/// Response can only be constructed in this package.
	this(const char[] response) { _value = parseJSON(response); }
	@disable this();
private:
	JSONValue _value;
}

struct Slack {
	/** 
	 * Constructs a new Slack object and stores the token and channel for later use.
	 * Params:
	 *   token = Slack BOT token to use for REST API authorization.
	 *   channel = Channel to use. Default is `#general`.
	 */
	this(string token, string channel = "#general") {
		// writefln("Slack.this(token: %s, channel: %s)", token, channel);
		_token = token;
		_channel = channel;
	}
	/**
	 * Sends a message to a channel.
	 * Params:
	 *   msgString = Message string
	 * Returns: JSON response from REST API endpoint.
	 * See_Also: https://api.slack.com/methods/chat.postMessage
	 */
	Response postMessage(string msgString) {
		// writefln("Slack.postMessage(msgString: %s)", msgString);
		auto http = HTTP();
		http.addRequestHeader("Content-Type", "application/json");
		http.addRequestHeader("Authorization", "Bearer " ~ _token);
		auto response = post(slackApiUrl ~ "chat.postMessage",
					`{"channel":"` ~ _channel ~ `", "attachments": [{"text":"` ~ msgString ~ `","color":"good"}]}`,
					http);
		// writeln("response: %s", response);
		return Response(response);
	}	// postMessage()

	/**
	 * Fetches a conversation's history of messages and events.
	 * Params:
	 *   channelId = Conversation ID to fetch history for.
	 * Returns: JSON response from REST API endpoint.
	 * See_Also: https://api.slack.com/methods/conversations.history
	 */
	Response conversationsHistory(string channelId) {
		// writefln("Slack.conversationsHistory(channel: %s)", channel);
		auto http = HTTP();
		http.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		auto response = post(slackApiUrl ~ "conversations.history", ["token": _token, "channel": channelId], http);
		// writeln("response: %s", response);
		return Response(response);
	}

	/**
	 * Lists all channels in a Slack team.
	 * Returns: JSON response from REST API endpoint.
	 * See_Also: https://api.slack.com/methods/conversations.list
	 */
	Response conversationsList() {
		// writefln("Slack.conversationsList(channel: %s)", channel);
		auto http = HTTP();
		http.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		auto response = post(slackApiUrl ~ "conversations.list", ["token": _token, "exclude_archived": "true"], http);
		// writeln("response: %s", response);
		return Response(response);
	}

	/// Sets the current channel to `channel`.
	@property void channel(string channel) { _channel = channel; }
	/// Returns the current channel.
	@property string channel() { return _channel; }

private:
	string _token;
	string _channel;
}

package:

immutable slackApiUrl = "https://slack.com/api/";
