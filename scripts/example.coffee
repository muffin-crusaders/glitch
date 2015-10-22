# Description:
#   Scripts that didn't merit moving to their own file
#
# Commands:
#   hi/hello/hey/yo/greetings/sup - Responds with a greeting
#   enhance - ENHANCE
#   odds (on/off/for)/what are the (chances/odds)/know the (chances/odds) - Responds with odds
jsonfile = require('jsonfile')

module.exports = (robot) ->
    robot.hear /\benhance\b/i, (res) ->
        res.send("![](http://i.giphy.com/10nMEclFWTPCp2.gif)")

    fiftyfifty = ["I'd give that a 50/50.", "Hmmm, 50/50?", "That's simple... 50/50.", "50/50 is my best guess."]
    robot.hear /\bodds (on|of|for)\b|\bwhat are the (chances|odds)\b|\bknow the (chances|odds)\b/i, (res) ->
        res.send res.random fiftyfifty

    robot.respond /version( (.*)|)/i, (res) ->
        pkg = res.match[2]
        if pkg
            jsonfile.readFile 'node_modules/' + pkg + '/package.json', (err, obj) ->
                if err
                    jsonfile.readFile 'node_modules/hubot-' + pkg + '/package.json', (err, obj) ->
                        if err
                            res.send 'Could not find that package'
                            console.log err
                            return
                        version = obj.version
                        if version
                            res.send pkg + ' is at version ' + version
                    return
                version = obj.version
                if version
                    res.send pkg + ' is at version ' + version
        else
            jsonfile.readFile 'package.json', (err, obj) ->
                if err
                    res.send 'Could not get version'
                    console.log err
                    return
                res.send 'I am currently at version ' + obj.version
