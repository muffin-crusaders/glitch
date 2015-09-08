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

    fiftyfifty = ["I'd give that a 50/50", "The odds? Hmmm, 50/50?", "That's simple... 50/50", "50/50 is my best guess"]
    robot.hear /\bodds\b/i, (res) ->
        res.send res.random fiftyfifty
