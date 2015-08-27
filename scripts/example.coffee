# Description:
#   Scripts that didn't merit moving to their own file
#
# Commands:
#   hi/hello/hey/yo/greetings/sup - Responds with a greeting
#   enhance - ENHANCE

module.exports = (robot) ->

    greetings = ['Hi', 'Hello', 'Hey', 'Yo']
    robot.hear /\bhi\b|\bhello\b|\bhey\b|\byo\b|\bgreetings\b|\bsup\b/i, (res) ->
        res.send res.random greetings

    robot.hear /\benhance\b/i, (res) ->
        res.send "![](http://i.giphy.com/10nMEclFWTPCp2.gif)"
