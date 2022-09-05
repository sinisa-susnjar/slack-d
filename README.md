[![ubuntu](https://github.com/sinisa-susnjar/slack-d/actions/workflows/ubuntu.yml/badge.svg)](https://github.com/sinisa-susnjar/slack-d/actions/workflows/ubuntu.yml) [![macos](https://github.com/sinisa-susnjar/slack-d/actions/workflows/macos.yml/badge.svg)](https://github.com/sinisa-susnjar/slack-d/actions/workflows/macos.yml) [![windows](https://github.com/sinisa-susnjar/slack-d/actions/workflows/windows.yml/badge.svg)](https://github.com/sinisa-susnjar/slack-d/actions/workflows/windows.yml) [![coverage](https://codecov.io/gh/sinisa-susnjar/slack-d/branch/main/graph/badge.svg?token=8IJIAOGVRZ)](https://codecov.io/gh/sinisa-susnjar/slack-d)

# Slack Web API for D

## Example

```d
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
```

## Implemented methods (so far)

### Chat

* https://api.slack.com/methods/chat.postMessage

### Conversations

* https://api.slack.com/methods/conversations.list
* https://api.slack.com/methods/conversations.history

## TODO's

* Add support for RTM (real-time messaging) API (see: https://api.slack.com/methods/rtm.connect)

See https://api.slack.com/methods for a full list of methods offered by the Slack API.
