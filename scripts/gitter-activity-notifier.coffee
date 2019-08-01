Gitter = require('node-gitter')
sprintf = require('sprintf-js').sprintf
vsprintf = require('sprintf-js').vsprintf
request = require('request')

# importing a regular JS file because I don't care for coffee anymore
path = require('path')
glitchpy = require( path.resolve( __dirname, "./glitch-py.js" ) )(process.env.HUBOT_PR_TOKEN)

notificationRoom = process.env.GITTER_ACTIVITY_TARGET;
disabledIssueActions = ['pinned', 'unpinned', 'locked', 'unlocked', 'milestoned', 'demilestoned'];
validLabels = ['priority: low', 'priority: medium', 'priority: high', 'priority: urgent'];

module.exports = (robot) ->
    gitter = new Gitter(process.env.HUBOT_GITTER2_TOKEN)
    store = {
        issues: {}
    }
    debouncedMessages = []
    timeoutHandle = null
    timeoutDuration = process.env.GITTER_ACTIVITY_FUNNEL_DELAY || 10000;

    primg = '![](http://bit.ly/2mN99Pg)&nbsp;&nbsp;'
    commentimg = '![](http://bit.ly/2m05UVA)&nbsp;&nbsp;'
    prReviewimg= '![](http://bit.ly/2EBhCxb)&nbsp;&nbsp;'
    infoimg = '![](http://bit.ly/2ms9KTJ)&nbsp;&nbsp;'
    pushimg = '![](http://bit.ly/2ms41wh)&nbsp;&nbsp;'
    travisOk = '![](http://bit.ly/2mNf9qY)&nbsp;&nbsp;' #https://cdn2.iconfinder.com/data/icons/oxygen/16x16/actions/ok.png
    travisBroken = '![](http://bit.ly/2n9KyFd)&nbsp;&nbsp;' #https://cdn2.iconfinder.com/data/icons/oxygen/16x16/actions/mail-delete.png

    ###
    https://cdn0.iconfinder.com/data/icons/octicons/1024/git-pull-request-16.png
    https://cdn0.iconfinder.com/data/icons/octicons/1024/comment-16.png
    https://cdn0.iconfinder.com/data/icons/octicons/1024/info-16.png
    https://cdn0.iconfinder.com/data/icons/octicons/1024/repo-push-16.png
    https://cdn2.iconfinder.com/data/icons/oxygen/16x16/actions/ok.png
    https://cdn2.iconfinder.com/data/icons/oxygen/16x16/actions/mail-delete.png
    https://cdn0.iconfinder.com/data/icons/octicons/1024/checklist-16.png
    ###

    # stringify list with oxford comma separation
    arrToString = (arr) ->
        l = arr.length;
        if !l
            return ifempty
        if l < 2
            return arr[0];
        if l < 3
            return arr.join(" and ");
        arr = arr.slice();
        arr[l - 1] = "and #{arr[l - 1]}";
        return arr.join(", ");

    # generate issue message from given issue info
    makeIssueMessage = (issue) ->
        actionsStr = arrToString issue.actions
        return "#{infoimg}`#{issue.user}` #{actionsStr} the **\"#{issue.title}\"** issue: #{issue.issue}"

    # post messages for found notifications
    postMessages = () ->
        for num, issue of store.issues
            debouncedMessages.push(makeIssueMessage(issue))

        # Log messages for debugging purposes
        console.log(debouncedMessages)

        robot.send
            room: notificationRoom
            debouncedMessages.join('\n')

        debouncedMessages = []
        store.issues = {}

    # accept post from github webhook and parse information
    robot.router.post "/hubot/github-repo-listener", (req, res) ->
        flag = true
        type = req.headers["x-github-event"]
        body = req.body

        if type == "pull_request"
            action = if body.action == "synchronize" then "synchronized" else body.action
            pr = body.pull_request.html_url
            prNum = body.number
            title = body.pull_request.title
            user = body.sender.login
            repo = body.repository.full_name
            branch = body.pull_request.head.ref
            if action == "closed"
                merged = if body.pull_request.merged then "merged" else "closed"
                debouncedMessages.push("#{primg} `#{user}` #{merged} the **\"#{title}\"** Pull Request: #{pr} ([Reviewable #{prNum}](https://reviewable.io/reviews/#{repo}/#{prNum}))")
            else if action in ["opened", "synchronized"]
                sha = body.pull_request.head.sha
                store[sha] = {
                    pr: pr
                    prNum: prNum
                    user: user
                    branch: branch
                    message: "#{primg} `#{user}` #{action} the **\"#{title}\"** Pull Request: #{pr} ([Reviewable #{prNum}](https://reviewable.io/reviews/#{repo}/#{prNum}))\n"
                }
                if action == "opened"
                    glitchpy.checkPrAssignee(repo, prNum)
                flag = false
            else
                flag = false

        else if type == "pull_request_review"
            action = body.action
            pr = body.pull_request.html_url
            prNum = body.pull_request.number
            title = body.pull_request.title
            user = body.review.user.login
            repo = body.repository.full_name
            debouncedMessages.push("#{prReviewimg} `#{user}` #{action} a review on the **\"#{title}\"** Pull Request: #{pr} ([Reviewable #{prNum}](https://reviewable.io/reviews/#{repo}/#{prNum}))")

        else if type == "issues"
            action = body.action
            issue = body.issue.html_url
            issueNum = body.issue.number
            title = body.issue.title
            user = body.sender.login
            # if issue has has prior recent changes, combine them and prevent duplicates
            if action !in disabledIssueActions
                if action == "labeled" && body.label in validLabels
                    action = "added `#{body.label}`"
                else if action == "unlabeled" && body.label in validLabels
                    action = "removed `#{body.label}`"
                if store.issues[issueNum]
                    if action !in store.issues[issueNum].actions
                        store.issues[issueNum].actions.push(action)
                else
                    store.issues[issueNum] = {
                        actions: [action]
                        user: user
                        title: title
                        issue: issue
                    }

        else if  type == "issue_comment"
            action = body.action
            issue = body.issue.html_url
            title = body.issue.title
            user = body.comment.user.login
            if action == "created"
                debouncedMessages.push("#{commentimg}`#{user}` commented on the **\"#{title}\"** issue: #{issue}")
            else
                debouncedMessages.push("#{commentimg}`#{user}` #{action} a comment on the **\"#{title}\"** issue: #{issue}")

        else if type == "push"
            user = body.sender.login
            ncommits = body.commits.length
            repo = body.repository.html_url
            repoName = body.repository.full_name
            compare = body.compare
            debouncedMessages.push("#{pushimg}`#{user}` pushed #{ncommits} commit(s) to [#{repoName}](#{repo}): [\[compare\]](#{compare})")

        else if type == "status" && body.state != "pending" && body.context == "continuous-integration/travis-ci/pr"
            sha = body.commit.sha
            pr = store[sha].pr
            prNum = store[sha].prNum
            user = store[sha].user
            branch = store[sha].branch
            description = body.description
            travis_url = body.target_url
            if body.state == "success"
                icon = travisOk

                 # Comment demos on PR
                demourl = 'http://fgpv-app.azureedge.net/demo/users/' + user + '/' + branch
                commentString = """
                    Hey, I updated your PR Demo:

                    | Dev Builds                      | Prod Builds                     |
                    | ------------------------------- | ------------------------------- |
                    | [index-one.html](#{demourl}/dev/samples/index-one.html)    | [index-one.html](#{demourl}/prod/samples/index-one.html)    |
                    | [index-mobile.html](#{demourl}/dev/samples/index-mobile.html)    | [index-mobile.html](#{demourl}/prod/samples/index-mobile.html)    |
                    | [index-samples.html](#{demourl}/dev/samples/index-samples.html)    | [index-samples.html](#{demourl}/prod/samples/index-samples.html)    |
                    | [index-fgp-en.html](#{demourl}/dev/samples/index-fgp-en.html) | [index-fgp-en.html](#{demourl}/prod/samples/index-fgp-en.html) |
                    | [index-fgp-fr.html](#{demourl}/dev/samples/index-fgp-fr.html) | [index-fgp-fr.html](#{demourl}/prod/samples/index-fgp-fr.html) |

                    Is it working as expected?
                    """
                glitchpy.comment("fgpv-vpgf", "fgpv-vpgf", prNum, commentString)
            else
                icon = travisBroken
                store[sha].message += ":rotating_light: EMERGENCY ALERT :rotating_light: `#{user}` has broken the :construction: build :construction: :construction_worker: :broken_heart: and owes muffins now!!! :cake:\n"


            debouncedMessages.push(store[sha].message + "#{icon} [#{description}](#{travis_url}) for Pull Request: #{pr} ([Reviewable #{prNum}](https://reviewable.io/reviews/#{repo}/#{prNum}))")
        else
            flag = false

        # start timeout if the message was accepted
        if flag
            clearTimeout timeoutHandle
            timeoutHandle = setTimeout postMessages, timeoutDuration

        res.send 'OK'

    return
