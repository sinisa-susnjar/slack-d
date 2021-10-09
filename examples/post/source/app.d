import std.stdio;
import slack;

import std.net.curl;
import std.json;

void main()
{
	version (None) {
	auto content = post("https://httpbin.org/post", ["name1" : "value1", "name2" : "value2"]);
	writeln("content: %s", content);
	auto json = parseJSON(content);
	writeln("json: %s", toJSON(json, true));
	}

	auto token = "xoxp-533837141921-535502563895-551343694551-8448aff7fdde6771682d00c851f7bea3";
	auto url = "https://slack.com/api/";
	auto channel = "#DEMO";

	// auto http = HTTP();
	// http.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	// auto content = post(url ~ "conversations.list", ["token": token, "exclude_archived": "true"], http);
	// auto content = post(url ~ "conversations.list", `{{"token":"` ~ token ~ `"}}`, http);
	// writeln("content: %s", content);

	auto http = HTTP();
	http.addRequestHeader("Content-Type", "application/json");
	http.addRequestHeader("Authorization", "Bearer " ~ token);
	auto content = post(url ~ "chat.postMessage",
				`{"channel":"` ~ channel ~ `", "attachments": [{"text":"Hello from slack-d!","color":"good"}]}`,
				http);
	writeln("content: %s", content);
}
