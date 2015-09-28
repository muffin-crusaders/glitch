//console.log(process.env);

process.env.HUBOT_ADAPTER = 'gitter2';
process.env.HUBOT_GITTER2_TOKEN = '***REMOVED***';

require('coffee-script/register');
module.exports = require('hubot/bin/hubot.coffee');