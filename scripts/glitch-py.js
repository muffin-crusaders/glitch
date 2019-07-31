const github = require('github-api');

module.exports = token => {
    const gh = new github({ token: token });

    return {
        comment: (user, repo, pull, message) => {
            const issues = gh.getIssues(user, repo);
            issues.createIssueComment(pull, message);
        },

        checkPrAssignee: (repository, pull) => {
            const [user, repo] = repository.split('/');
            const issues = gh.getIssues(user, repo);
            gh.getIssue(pull, (pr) => {
                if (pr.assignees.length === 0) {
                    issues.createIssueComment(pull, `You forgot to assign your PR! It's a muffin offence, you know...`);
                }
            })
        }
    };
};
