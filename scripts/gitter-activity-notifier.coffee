Gitter = require('node-gitter')
sprintf = require('sprintf-js').sprintf
vsprintf = require('sprintf-js').vsprintf
request = require('request')

# importing a regular JS file because I don't care for coffee anymore
path = require('path')
glitchpy = require( path.resolve( __dirname, "./glitch-py.js" ) )(process.env.HUBOT_PR_TOKEN)

roomNames = (process.env.GITTER_ACTIVITY_FUNNEL || '').split('|')
notificationRoom = process.env.GITTER_ACTIVITY_TARGET || 'same';

console.log(roomNames)

module.exports = (robot) ->
    gitter = new Gitter(process.env.HUBOT_GITTER2_TOKEN)
    store = {}
    timeoutHandle = null
    timeoutDuration = process.env.GITTER_ACTIVITY_FUNNEL_DELAY || 10000;

    primg = '![](https://goo.gl/hjqlaA)&nbsp;&nbsp;'
    commentimg = '![](https://goo.gl/8IdEJl)&nbsp;&nbsp;'
    infoimg = '![](https://goo.gl/9bHFwO)&nbsp;&nbsp;'
    pushimg = '![](https://goo.gl/UHCtHx)&nbsp;&nbsp;'
    travisOk = '![](https://goo.gl/0i3kmz)&nbsp;&nbsp;' #https://cdn2.iconfinder.com/data/icons/oxygen/16x16/actions/ok.png
    travisBroken = '![](https://goo.gl/4RUx7z)&nbsp;&nbsp;' #https://cdn2.iconfinder.com/data/icons/oxygen/16x16/actions/mail-delete.png

    for roomName in roomNames
        #console.log(roomName)
        ###
        gitter.rooms.join(roomName).then((room) ->
            events = room.streaming().events();

            console.log('events object', events)

            events.on('snapshot', (snapshot) ->
                console.log(snapshot.length + ' messages in the snapshot');
            )

            events.on('events', (message) ->
                console.log('A message was ' + message.operation);
                console.log('Text: ', message.model.text);
            )
        )
        ###

        # listen to events in the rooms
        gitter.rooms.join(roomName).then((room) ->
            events = room.streaming().events();

            console.log('room id', room.name, room.id)

            store[room.id] = {
                comment: {}
                issue: {}
                pr: {}
                commit: {}
                prDelay: {}
                travis: {}
            }

            events.on('snapshot', (snapshot) ->
                console.log(snapshot.length + ' messages in the snapshot');
            )

            events.on('events', (message) ->
                console.log('A message was ' + message.operation + ' in room ' + room.id);
                console.log('Text: ', message.model.text);
                parseMessage(room.id, message.model.text)
            )
        )

        if notificationRoom != 'same'
             gitter.rooms.join(notificationRoom)

    # help!
    helper = (items, id, prop, value, parts) ->

        # split to prevent matching 'label' in 'unlabel'
        if items[id] and items[id][prop].split(',').indexOf(value) == -1
            items[id][prop] += ',' + value
        # add new notification
        else
            items[id] = parts

    parseMessage = (roomid, text) ->
        message = ''
        flag = true

        comment = /\[Github\] (\w[\w-]+) commented in (.+?\/.+?) on issue: (.*?) http.*?\/(\d+)#.*/
        # name:1; reponame:2; issuename:3; issueid:4

        issue = /\[Github\] (\w[\w-]+) (closed|opened|reopened|assigned|unassigned|labeled|unlabeled) an issue in (.+?\/.+?): (.*?) http.*?\/(\d+)/
        # name:1; action:2; reponame:3; issuename:4; issueid:5

        # remove `assigned|unassigned|labeled|unlabeled` from tracked pr actions
        pr = /\[Github\] (\w[\w-]+) (closed) a Pull Request to (.+?\/.+?): (.*?) http.*?\/(\d+)/
        prDelay = /\[Github\] (\w[\w-]+) (opened|reopened|synchronize) a Pull Request to (.+?\/.+?): (.*?) http.*?\/(\d+)/
        # name:1; action:2; reponame:3; prname:4; prid: 5; demourl: 6

        travis = /Travis (.+?\/.+?)#(\d+) \[(passed|broken)\]\((http.*?)\) \((\d+)\)/
        # reponame:1; issueid:2; status:3; travisurl:4; buildid:5

        commit = /\[Github\] (\w[\w-]+) pushed (\d+) commit\(s\) to (.+?\/.+?) (http.*)/
        # name:1; commits:2; reponame:3; compare:4;

        ###
        primg = '![](https://cdn0.iconfinder.com/data/icons/octicons/1024/git-pull-request-16.png)&nbsp;&nbsp;'
        commentimg = '![](https://cdn0.iconfinder.com/data/icons/octicons/1024/comment-16.png)&nbsp;&nbsp;'
        infoimg = '![](https://cdn0.iconfinder.com/data/icons/octicons/1024/info-16.png)&nbsp;&nbsp;'
        pushimg = '![](https://cdn0.iconfinder.com/data/icons/octicons/1024/repo-push-16.png)&nbsp;&nbsp;'
        ###

        if comment.test text
            m = text.match comment
            m.shift(1)
            console.log(m)

            helper(store[roomid].comment, m[3], 0, m[0], m)

            ###
            # if notification exists, add new name
            if comment[id] and comment[id][0].indexOf(m[0]) == -1
                comment[id][0] += ',' + m[0]
            # add new notification
            else
                issue[id] = m
            ###

        else if issue.test text
            m = text.match issue
            m.shift(1)
            console.log(m)

            helper(store[roomid].issue, m[0] + m[4], 1, m[1], m)

            ###
            # if notification exists, add new action
            if issue[id] and issue[id][1].indexOf(m[1]) == -1
                issue[id][1] += ',' + m[1]
            # add new notification
            else
                issue[id] = m
            ###

        else if pr.test text
            m = text.match pr
            m.shift(1)
            console.log(m)

            helper(store[roomid].pr, m[0] + m[4], 1, m[1], m)

            #message = vsprintf('@%1$s %2$s a Pull Request to [%3$s](https://github.com/%3$s/): %3$s#%5$s', m)
            #message = primg + vsprintf('%1$s %2$s a Pull Request: %3$s#%5$s; [Reviewable %5$s](https://reviewable.io/reviews/%3$s/%5$s)', m)

        else if prDelay.test text
            m = text.match prDelay
            m.shift(1)

            url = 'https://api.github.com/repos/' + m[2] + '/pulls/' + m[4]
            console.log url

            # try to get branch name
            request {
                headers: 'User-Agent': 'request'
                url: url
            }, (error, response, body) ->
                if !error and response.statusCode == 200
                    fbResponse = JSON.parse(body)
                    branchName = fbResponse.head.ref
                    user = fbResponse.user.login
                    demourl = 'http://fgpv.cloudapp.net/demo/users/' + user + '/' + branchName + '/samples/index-one.html'
                    console.log 'Demo url', demourl, m[2], m[2].indexOf('/fgpv-vpgf')

                    # demo urls are only constructed for fgpv-vpgf repos
                    if m[2].indexOf('/fgpv-vpgf') != -1
                        m.push demourl
                else
                    console.log 'Got an error: ', error, ', status code: ', response.statusCode

                store[roomid].prDelay[m[4]] = m
                console.log(m)

            #helper(store[roomid].prDelay, m[0] + m[4], 1, m[1], m)

            ##### -> store[roomid].prDelay[m[4]] = m

            #console.log(store[roomid].prDelay[m[4]])

            #message = vsprintf('@%1$s %2$s a Pull Request to [%3$s](https://github.com/%3$s/): %3$s#%5$s', m)
            #message = primg + vsprintf('%1$s %2$s a Pull Request: %3$s#%5$s; [Reviewable %5$s](https://reviewable.io/reviews/%3$s/%5$s)', m)

            flag = false # skip outputting messages about opened pr; wait for travis to reply

        else if travis.test text
            m = text.match travis
            m.shift(1)
            console.log(m)

            #helper(store[roomid].travis, m[0] + m[4], 1, m[1], m)
            store[roomid].travis[m[1]] = m

            #console.log(store[roomid].travis[m[1]])

            #message = vsprintf('@%1$s %2$s a Pull Request to [%3$s](https://github.com/%3$s/): %3$s#%5$s', m)
            #message = primg + vsprintf('%1$s %2$s a Pull Request: %3$s#%5$s; [Reviewable %5$s](https://reviewable.io/reviews/%3$s/%5$s)', m)

        else if commit.test text
            m = text.match commit
            m.shift(1)
            console.log(m)

            store[roomid].commit[m[0] + m[1] + m[2]] = m

            #message = pushimg + vsprintf('%1$s pushed %2$s commit(s) to [%3$s](https://github.com/%3$s/): [\[compare\]](%4$s)', m)
        else
            flag = false

        console.log(' -->', message)

        # store message and wait in case new messages come soon
        #if message != ''
           #store[roomid].push message

        # start timeout if the message was accepted
        if flag
            clearTimeout timeoutHandle
            timeoutHandle = setTimeout repostMessage, timeoutDuration, roomid
            console.log(' ---> timeout handle')

    # add 'and' between workd is needed
    andify = (string) ->
        ar = string.split(',')
        joint = ', '

        if ar.length == 1
            return string
        else if ar.length == 2
            joint = ' '

        ar.push('and ' + ar.pop())

        return ar.join(joint)

    # when timeout resolves, repost all captured messages
    repostMessage = (roomid) ->
        messages = []

        console.log(' ---> time out; reposting', roomid)

        # construct issue messages
        for commentid, parts of store[roomid].comment
            console.log(commentid, parts)
            parts[0] = andify parts[0]
            messages.push(commentimg + vsprintf('`%1$s` commented on the "__%3$s__" issue: %2$s#%4$s', parts))

        # construct comment messages
        for issueid, parts of store[roomid].issue
            console.log(issueid, parts)
            parts[1] = andify parts[1]
            messages.push(infoimg + vsprintf('`%1$s` %2$s the "__%4$s__" issue: %3$s#%5$s', parts))

        for prid, parts of store[roomid].pr
            console.log(prid, parts)
            parts[1] = andify parts[1]
            messages.push(primg + vsprintf('`%1$s` %2$s the "__%4$s__" Pull Request: %3$s#%5$s; [Reviewable %5$s](https://reviewable.io/reviews/%3$s/%5$s)', parts))

        for travisid, parts of store[roomid].travis
            console.log('travisid -->', travisid, parts)

            prDelayParts = store[roomid].prDelay[travisid]
            if prDelayParts
                parts.push(prDelayParts[0])
                messages.push(primg + vsprintf('`%1$s` %2$s the "__%4$s__" Pull Request: %3$s#%5$s; [Reviewable %5$s](https://reviewable.io/reviews/%3$s/%5$s); [Demo](%6$s)', prDelayParts))
                store[roomid].prDelay[travisid] = undefined # null delayed pr message
            else
                parts.push('Someone')

            if parts[2] == 'passed'
                messages.push(travisOk + vsprintf('Pull Request %1$s#%2$s ([Reviewable %2$s](https://reviewable.io/reviews/%1$s/%2$s)) has __passed__: [Travis %5$s](%4$s)', parts))

                if prDelayParts[5]
                    # add travis id to the delayed parts array to add to the message
                    prDelayParts.push(parts[4]) # parts[4] -> %5$s

                    # add a comment to the pull request with a demo url
                    console.log('PR demo -->', prDelayParts[4], prDelayParts[5], prDelayParts)
                    glitchpy.comment("fgpv-vpgf/fgpv-vpgf", prDelayParts[4], vsprintf('I updated your PR Demo: [Build #%7$s](%6$s).', prDelayParts))
            else
                messages.push(travisBroken + vsprintf('`%6$s` owes muffins now!!! :cake: Pull Request %1$s#%2$s ([Reviewable %2$s](https://reviewable.io/reviews/%1$s/%2$s)) is __broken__: [Travis %5$s](%4$s)', parts))

        for commitid, parts of store[roomid].commit
            console.log(commitid, parts)
            messages.push(pushimg + vsprintf('`%1$s` pushed %2$s commit(s) to [%3$s](https://github.com/%3$s/): [\[compare\]](%4$s)', parts))

        # funnel notification to a single room is specified; otherwise post to the event origin room
        target = if notificationRoom == 'same' then roomid else notificationRoom

        # join different types of messages
        robot.send
            room: target
            messages.join('\n')

        console.log(roomid, store[roomid])

        # clear store
        store[roomid].comment = {}
        store[roomid].issue = {}
        store[roomid].pr = {}
        store[roomid].commit = {}
        store[roomid].travis = {}

    return
