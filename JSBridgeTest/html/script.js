function init () {
    document.body.onload = function () {
        location.href = "bridge:///-123/-456/@add/-hoge/-1/@int/@callback"
    }
}

function hoge (x) {
    var e = document.createElement ("h1")
    e.textContent = x
    document.body.appendChild (e)
    setTimeout (function () {
        location.href = "bridge:///-hoge/-key/@hmac_sha1/@base64data/@print"
    }, 100)
}

init ();
