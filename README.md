# slack-d

A Slack REST API for D

# Implemented methods (so far)[^1]

## Chat

| Method           | Description                   |
| ---------------- | ----------------------------- |
| chat.postMessage | Sends a message to a channel. |

## Conversations

| Method                | Description                                              |
| --------------------- | -------------------------------------------------------- |
| conversations.list    | Lists all channels in a Slack team.                      |
| conversations.history | Fetches a conversation's history of messages and events. |

[^1]: see https://api.slack.com/methods for a full list of methods offered by the Slack API.
