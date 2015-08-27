# Description
#   Lets hubot roll dice and flip coins
#
# Commands:
#   hubot flip a coin - Responds with heads or tails, chosen randomly
#   hubot roll a d<num> - Rolls a <num>-sided die and responds with result
#   hubot roll <num1>d<num2> - Rolls <num1> <num2>-sided dice and responds with each roll and the total
#
# Author:
#   Spencer Wahl <spencer.s.wahl@gmail.com>

module.exports = (robot) ->

    coin_results = ['heads', 'tails']
    robot.respond /flip a coin/i, (res) ->
        res.send "The coin landed on " + res.random coin_results

    robot.respond /roll a d(\d+)/i, (res) ->
        sides = parseInt(res.match[1], 10)
        if sides < 2
            res.send "I don't think thats a thing."
            return
        result = Math.ceil(Math.random() * sides)
        res.send "I rolled a " + result

    robot.respond /roll (\d+)d(\d+)/i, (res) ->
        num_dice = parseInt(res.match[1], 10)
        sides = parseInt(res.match[2], 10)
        dice_rolled = 0
        result = []
        if sides < 2
            res.send "I don't think thats a thing."
        else if num_dice < 1
            res.send "That isn't possible."
        else if num_dice > 50
            res.send "I don't have that many dice."
        else
            while (dice_rolled < num_dice)
                result.push(Math.ceil(Math.random() * sides))
                dice_rolled = dice_rolled + 1
            res.send report_dice result

report_dice = (rolls) ->
    if rolls?
        total = 0
        if rolls.length == 1
            "I rolled a " + result[0]
        else
            for num in rolls
                total = total + num
            last_roll = rolls.pop()
            "I rolled " + rolls.join(", ") + ", and " + last_roll + ", which makes " + total + "."
