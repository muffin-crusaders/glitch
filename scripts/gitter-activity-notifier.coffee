Gitter = require('node-gitter')
sprintf = require('sprintf-js').sprintf
vsprintf = require('sprintf-js').vsprintf

roomNames = (process.env.GITTER_ACTIVITY_FUNNEL || '').split('|')

console.log(roomNames)

module.exports = (robot) ->
    gitter = new Gitter(process.env.HUBOT_GITTER2_TOKEN)
    store = {}
    timeoutHandle = null
    timeoutDuration = 4000

    primg = '![](https://goo.gl/hjqlaA)&nbsp;&nbsp;'
    commentimg = '![](https://goo.gl/8IdEJl)&nbsp;&nbsp;'
    infoimg = '![](https://goo.gl/9bHFwO)&nbsp;&nbsp;'
    pushimg = '![](https://goo.gl/UHCtHx)&nbsp;&nbsp;'


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
            }

            events.on('snapshot', (snapshot) ->
                console.log(snapshot.length + ' messages in the snapshot');
            )

            events.on('events', (message) ->
                console.log('A message was ' + message.operation);
                console.log('Text: ', message.model.text);
                parseMessage(room.id, message.model.text)
            )
        )

    # help!
    helper = (items, id, prop, value, parts) ->

        if items[id] and items[id][prop].indexOf(value) == -1
            items[id][prop] += ',' + value
        # add new notification
        else
            items[id] = parts

    parseMessage = (roomid, text) ->
        message = ''

        clearTimeout timeoutHandle

        comment = /\[Github\] (\w[\w-]+) commented in (.+?\/.+?) on issue: (.*?) http.*?\/(\d+)#.*/
        # name:1; reponame:2; issuename:3; issueid:4

        issue = /\[Github\] (\w[\w-]+) (closed|opened|reopened|assigned|unassigned|labeled|unlabeled) an issue in (.+?\/.+?): (.*?) http.*?\/(\d+)/
        # name:1; action:2; reponame:3; issuename:4; issueid:5

        pr = /\[Github\] (\w[\w-]+) (opened|closed|reopened|synchronize) a Pull Request to (.+?\/.+?): (.*?) http.*?\/(\d+)/
        # name:1; action:2; reponame:3; prname:4; prid: 5;

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

            helper(store[roomid].issue, m[0] + m[4], 1, m[1], m)

            #message = vsprintf('@%1$s %2$s a Pull Request to [%3$s](https://github.com/%3$s/): %3$s#%5$s', m)
            #message = primg + vsprintf('%1$s %2$s a Pull Request: %3$s#%5$s; [Reviewable %5$s](https://reviewable.io/reviews/%3$s/%5$s)', m)
        else if commit.test text
            m = text.match commit
            m.shift(1)
            console.log(m)

            items[m[0] + m[1] + m[2]] = parts

            #message = pushimg + vsprintf('%1$s pushed %2$s commit(s) to [%3$s](https://github.com/%3$s/): [\[compare\]](%4$s)', m)

        console.log(' -->', message)

        # store message and wait in case new messages come soon
        #if message != ''
           #store[roomid].push message
        timeoutHandle = setTimeout repostMessage, timeoutDuration, roomid
        console.log(' ---> timeout handle', timeoutHandle)

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
            messages.push(commentimg + vsprintf('%1$s commented on issue %2$s#%4$s', parts))

        # construct comment messages
        for issueid, parts of store[roomid].issue
            console.log(issueid, parts)
            parts[1] = andify parts[1]
            messages.push(infoimg + vsprintf('%1$s %2$s an issue: %3$s#%5$s', parts))

        for prid, parts of store[roomid].pr
            console.log(prid, parts)
            parts[1] = andify parts[1]
            messages.push(primg + vsprintf('%1$s %2$s a Pull Request: %3$s#%5$s; [Reviewable %5$s](https://reviewable.io/reviews/%3$s/%5$s)', parts))

        for commitid, parts of store[roomid].commit
            console.log(commitid, parts)
            messages.push(pushimg + vsprintf('%1$s pushed %2$s commit(s) to [%3$s](https://github.com/%3$s/): [\[compare\]](%4$s)', parts))

        # join different types of messages
        robot.send
            room: roomid
            messages.join('\n')

        console.log store[roomid]

        # clear store
        store[roomid] = {
            comment: {}
            issue: {}
            pr: {}
            commit: {}
        }

    return
