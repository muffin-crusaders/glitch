Gitter = require('node-gitter')
sprintf = require('sprintf-js').sprintf
vsprintf = require('sprintf-js').vsprintf

roomNames = (process.env.GITTER_ACTIVITY_FUNNEL || '').split('|')

console.log(roomNames)

module.exports = (robot) ->
    gitter = new Gitter(process.env.HUBOT_GITTER2_TOKEN)

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

            events.on('snapshot', (snapshot) ->
                console.log(snapshot.length + ' messages in the snapshot');
            )

            events.on('events', (message) ->
                console.log('A message was ' + message.operation);
                console.log('Text: ', message.model.text);
                repost(room.id, message.model.text)
            )
        )

    repost = (roomid, text) ->
        message = ''
        #console.log('reposting', text)

        comment = /\[Github\] (\w[\w-]+) commented in (.+?\/.+?) on issue: (.*?) http.*?\/(\d+)#.*/
        # name:1; reponame:2; issuename:3; issueid:4

        issue = /\[Github\] (\w[\w-]+) (closed|opened|reopened|assigned|unassigned|labeled) an issue in (.+?\/.+?): (.*?) http.*?\/(\d+)/
        # name:1; action:2; reponame:3; issuename:4; issueid:5

        pr = /\[Github\] (\w[\w-]+) (opened|closed|reopened|synchronize) a Pull Request to (.+?\/.+?): (.*?) http.*?\/(\d+)/
        # name:1; action:2; reponame:3; prname:4; prid: 5;

        commit = /\[Github\] (\w[\w-]+) pushed (\d+) commit\(s\) to (.+?\/.+?) (http.*)/
        # name:1; commits:2; reponame:3; compare:4;

        primg = '![](https://cdn0.iconfinder.com/data/icons/octicons/1024/git-pull-request-16.png)&nbsp;&nbsp;'
        commentimg = '![](https://cdn0.iconfinder.com/data/icons/octicons/1024/comment-16.png)&nbsp;&nbsp;'
        infoimg = '![](https://cdn0.iconfinder.com/data/icons/octicons/1024/info-16.png)&nbsp;&nbsp;'
        pushimg = '![](https://cdn0.iconfinder.com/data/icons/octicons/1024/repo-push-16.png)&nbsp;&nbsp;'

        if comment.test text
            m = text.match comment
            m.shift(1)
            console.log(m)
            #message = vsprintf('@%1$s commented in [%2$s](https://github.com/%2$s/) on issue %2$s#%4$s', m)
            message = commentimg + vsprintf('%1$s commented on issue %2$s#%4$s', m)
        else if issue.test text
            m = text.match issue
            m.shift(1)
            console.log(m)
            #message = vsprintf('@%1$s %2$s an issue in [%3$s](https://github.com/%3$s/): %3$s#%5$s', m)
            message = infoimg + vsprintf('%1$s %2$s an issue: %3$s#%5$s', m)
        else if pr.test text
            m = text.match pr
            m.shift(1)
            console.log(m)
            #message = vsprintf('@%1$s %2$s a Pull Request to [%3$s](https://github.com/%3$s/): %3$s#%5$s', m)
            message = primg + vsprintf('%1$s %2$s a Pull Request: %3$s#%5$s; [Reviewable %5$s](https://reviewable.io/reviews/%3$s/%5$s)', m)
        else if commit.test text
            m = text.match commit
            m.shift(1)
            console.log(m)
            message = pushimg + vsprintf('%1$s pushed %2$s commit(s) to [%3$s](https://github.com/%3$s/): [\[compare\]](%4$s)', m)

        console.log('-->', message)
        if message != ''
            robot.send
                room: roomid
                message

    return
