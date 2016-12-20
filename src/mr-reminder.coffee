# Description
#   Reminds people when MR are just waiting around.
#
# Configuration:
#   HUBOT_GITLAB_URL
#   HUBOT_GITLAB_TOKEN
#
# Commands:
#   hubot start monitor for <repository> - Bot will start to monitor for MRs in the channel
#   hubot stop monitor for <repository> - Bot will stop to monitor for MRs in the channel
#   hubot list monitors - Bot will list all monitored repository for this channel
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Christophe Verbinnen[@<org>]

module.exports = (robot) ->

  #setup gitlab
  if process.env.HUBOT_GITLAB_URL? && process.env.HUBOT_GITLAB_TOKEN?
    gitlab = (require 'gitlab')
      url:   process.env.HUBOT_GITLAB_URL
      token: process.env.HUBOT_GITLAB_TOKEN
  else
    console.log('gitlab is not configured :(')

  robot.respond /list monitors/, (res)->
    monitors = []
    for repository,channels of _getMonitors()
      monitors.push repository if res.message.room in channels

    if monitors.length > 0
      res.reply "In this channel, I'm monitoring #{monitors.join(',')}"
    else
      res.reply "No monitors setup"

  robot.respond /start monitor for ([a-z\-_\/]+)/i, (res)->
    repository = res.match[1]
    startMonitoring(repository, res)

  robot.respond /stop monitor for ([a-z\-_\/]+)/i, (res)->
    repository = res.match[1]
    stopMonitoring(repository, res)

  _getMonitors = ->
    monitors = robot.brain.get('mr_monitors') || {}

  _setMonitors = (monitors)->
    robot.brain.set 'mr_monitors', monitors

  _shouldNotify = (mr)->
    !mr.work_in_progress && mr.upvotes == 0 && ((Date.now() - Date.parse(mr.updated_at)) / 1000 / 3600) > 1

  checkForMergeRequests = ->
    for repository, channels of _getMonitors()
      gitlab.projects.merge_requests.list repository,  {state: 'opened'}, (mrs)->
        for mr in mrs
          if _shouldNotify(mr)
            for channel in channels
              robot.send room: channel, "Reminder: #{mr.title} has been waiting for a review for more than 1 hour. Please check it out @ #{mr.web_url}"

  stopMonitoring = (repository, msg)->
    room = msg.message.room
    monitors = _getMonitors()
    monitors[repository] ||= []
    index = monitors[repository].indexOf(room)
    monitors[repository].splice(index, 1)
    _setMonitors(monitors)
    msg.reply "You got it. I'm not monitoring #{repository} in this channel anymore."

  startMonitoring = (repository, msg)->
    room = msg.message.room
    #check if project exists
    gitlab.projects.show repository, (project) ->
      
      if !project
        msg.reply "I can't monitor #{repository} since it does not exist! :("
        return

      monitors = _getMonitors()
      monitors[repository] ||= []
      if room not in monitors[repository]
        monitors[repository].push room
      

      _setMonitors monitors

      msg.reply "Ok, I'm now tracking MRs for #{repository} in ##{room}!"

  #setup cron
  cronJob = require('cron').CronJob
  new cronJob('0 0 9-17 * * 1-5', checkForMergeRequests,null, true, 'America/Los_Angeles')
