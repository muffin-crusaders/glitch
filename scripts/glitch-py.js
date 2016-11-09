var PythonShell = require('python-shell');

module.exports = token => {
    return {
        comment: (repo, pull, message) => {
            var options = {
                // pythonPath: 'C:/tools/python2/python.exe',
                args: [`-m ${message}`, `-p ${pull}`, `-r ${repo}`, `-t ${token}`]
            };

            PythonShell.run('./scripts/glitch-py.py', options, function (err, results) {
                if (err) throw err;
                // results is an array consisting of messages collected during execution

                console.log('results: %j', results);
            });
        },

        checkPrAssignee: (repo, pull) => {
            var options = {
                // pythonPath: 'C:/tools/python2/python.exe',
                args: [`-p ${pull}`, `-r ${repo}`, `-t ${token}`]
            };

            PythonShell.run('./scripts/check-pr-assignee.py', options, function (err, results) {
                if (err) throw err;
                // results is an array consisting of messages collected during execution

                console.log('results: %j', results);
            });
        }
    }
};
