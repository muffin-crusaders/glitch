//console.log(process.env);

process.env.HUBOT_ADAPTER = 'gitter2';
process.env.HUBOT_GITTER2_TOKEN = 'b2699df219531e128317c2ac8e736f38097c6096';

require('coffee-script/register');
module.exports = require('hubot/bin/hubot.coffee');