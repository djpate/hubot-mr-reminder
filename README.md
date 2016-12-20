# hubot-mr-reminder

Reminds people when MR are just waiting around.

See [`src/mr-reminder.coffee`](src/mr-reminder.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-mr-reminder --save`

Then add **hubot-mr-reminder** to your `external-scripts.json`:

```json
["hubot-mr-reminder"]
```

You'll need to set a couple of variables

```
HUBOT_GITLAB_URL
HUBOT_GITLAB_TOKEN
```

## Commands

```
hubot start monitor for <repository> - Bot will start to monitor for MRs in the channel
```

```
hubot stop monitor for <repository> - Bot will stop to monitor for MRs in the channel
```

```
hubot list monitors - Bot will list all monitored repository for this channel
```
