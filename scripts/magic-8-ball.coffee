# Description
#   Gives answers to yes/no questions
#
# Commands:
#   hubot <question>? - Responds with a randomly chosen Magic 8-ball answer
#
# Author:
#   Spencer Wahl <spencer.s.wahl@gmail.com>

module.exports = (robot) ->

    magic_answers = ['It is certain', 'It is decidedly so', 'Without a doubt', 'Yes definitely', 'You may rely on it',
                     'As I see it, yes', 'Most likely', 'Outlook good', 'Yes', 'Signs point to yes',
                     'Reply hazy try again', 'Ask again later', 'Better not tell you now', 'Cannot predict now',
                     'Concentrate and ask again', "Don't count on it", 'My reply is no', 'My sources say no',
                     'Outlook not so good', 'Very doubtful']
    robot.respond /(.+)\?/i, (res) ->
        res.reply res.random magic_answers
