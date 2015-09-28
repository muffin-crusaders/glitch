cloudinary = require('cloudinary')
https = require('https')

cloudinary.config
    cloud_name: process.env.HUBOT_CLOUDINARY_NAME
    api_key: process.env.HUBOT_CLOUDINARY_API_KEY
    api_secret: process.env.HUBOT_CLOUDINARY_API_SECRET

roomNames = [
    #{name: 'AleksueiR/CyberTests'}
    #{name: 'fgpv-vpgf/fgpv-vpgf'}
    #{name: 'fgpv-vpgf/Scrum'}
    #{name: 'fgpv-vpgf'}
]

#console.log(process.env.HUBOT_CLOUDINARY_NAME, process.env.HUBOT_CLOUDINARY_API_KEY, process.env.HUBOT_CLOUDINARY_API_SECRET)

module.exports = (robot) ->
    return

    options =
        hostname: 'api.gitter.im',
        port:     443,
        path:     '/v1/rooms/',
        method:   'GET',
        headers:  {'Authorization': 'Bearer ' + process.env.HUBOT_GITTER2_TOKEN}

    req = https.request(options, (res) ->
        output = ''
        res.on('data', (chunk) ->
            output += chunk.toString()
            )
        res.on('end', ->
            for entry in JSON.parse(output)
                console.log entry.url
                for room in roomNames
                    if entry.url == '/' + room.name
                        room.id = entry.id.toString()
                        console.log '------- MATCHED ------------\n' + entry.id.toString()

            console.log roomNames
            )
        )

    req.on('error', (e) ->
        robot.send e )

    req.end()

    robot.hear /http.*?i\.imgur\.com.*(png|gif|jpg|jpeg)/i, (res) ->
        url = res.match[0]

        for room in roomNames
            if room.id == res.message.room

                cloudinary.uploader.upload url, (result) ->
                    console.log result.url

                    res.send '['+ result.url + '](' + result.url + ')'