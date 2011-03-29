function __hex (hexdata) {
    var data = hexdata.replace (/([a-f0-9]){2}/ig, function (x) {
        return String.fromCharCode (parseInt (x, 16))
    })

    return data
}

function connectionDidFailWithError (connid, err) {
    var e = document.createElement ("p")
    e.textContent = "fail: " + err
    document.body.appendChild (e)
}

function connectionDidReceiveData (connid, data) {
    var e = document.createElement ("p")
    e.textContent = "recv: " + data.length
    document.body.appendChild (e)
}

function connectionDidReceiveResponse (connid) {
    var e = document.createElement ("p")
    e.textContent = "recv response"
    document.body.appendChild (e)
}

function connectionDidSendBodyData (connid) {
    var e = document.createElement ("p")
    e.textContent = "data sent"
    document.body.appendChild (e)
}

function connectionDidFinishLoading (connid) {
    var e = document.createElement ("p")
    e.textContent = "finish"
    document.body.appendChild (e)
}

////////////////////

function init () {
    document.body.onload = function () {
        location.href = "bridge:///-123/-456/@add/-hoge/-1/@callback"
    }
}

function hoge (x) {
    var e = document.createElement ("p")
    e.textContent = x
    document.body.appendChild (e)
    setTimeout (function () {
        location.href = "bridge:///-hoge/-key/@hmac_sha1/@base64data/@print/-hoge2/-0/@callback"
    }, 100)
}

function hoge2 () {
    var e = document.createElement ("p")
    e.textContent = "hoge2"
    document.body.appendChild (e)

    setTimeout (function () {
        var url = "http://google.com"
        var hex = ""
        for (var i = 0; i < url.length; i ++) {
            hex += url.charCodeAt (i).toString (16)
        }
        location.href = "bridge:///-" + hex + "/@hexstr/@str/@http_get/-hoge3/-1/@callback"
    }, 100)
}

function hoge3 (connid) {
    var e = document.createElement ("p")
    e.textContent = "hoge3" + connid
    document.body.appendChild (e)
}

init ();
