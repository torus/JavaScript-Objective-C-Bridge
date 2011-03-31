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

function create_stack () {
    return []
}

function stack_push_raw_string (st, val) {
    st.push ("-" + val)
}

function stack_push_operator (st, op) {
    st.push ("@" + op)
}

function hexify (str) {
    var hex = ""
    for (var i = 0; i < str.length; i ++) {
        hex += url.charCodeAt (i).toString (16)
    }

    return hex
}

function stack_push_string (st, op) {
    if (typeof (op) != "string")
        op = op.toString ()

    if (op.match (/^[a-zA-Z0-9!@#$%^&*()_+{}|\[\]\:";'<>?,]*$/)) {
        stack_push_raw_string (st, op)
    } else {
        stack_push_raw_string (st, hexify (op))
    }
}

function stack_execute (st) {
    var uri = "bridge:///" + st.join ("/")
    $("pre").append ("\nexecute: " + uri)
    setTimeout (function () {
        location.href = uri
    }, 100)
}

JSBridgeStack = function () {
    this.stack = create_stack ()
}

JSBridgeStack.prototype.push = function () {
    for (var i = 0; i < arguments.length; i ++) {
        stack_push_string (this.stack, arguments[i])
    }
    return this
}

JSBridgeStack.prototype.operate = function (op) {
    stack_push_operator (this.stack, op)
    return this
}

JSBridgeStack.prototype.execute = function () {
    stack_execute (this.stack)
}

///////////////////

function init () {
    $(document).ready (function () {
        $("pre").text ("ready")

        var jsb = new JSBridgeStack ()
        jsb.push (123, 456).operate ("add").push ("hoge", 1).operate ("callback").execute ()
    })
}

function hoge (x) {
    $("pre").append ("\n" + x)

    var jsb = new JSBridgeStack ()
    jsb.push (123, 456).operate ("add").push ("hoge", 1).operate ("callback").execute ()
}

function hoge2 () {
    $("pre").append ("\n" + "hoge2")

    setTimeout (function () {
        var url = "http://scrw.in/"
        var hex = ""
        for (var i = 0; i < url.length; i ++) {
            hex += url.charCodeAt (i).toString (16)
        }
        location.href = "bridge:///-Value2/-X-Scrw-Ex/-Value1/-X-Scrw-Id/-2/-" + hex + "/@hexstr/@str/@http_get/-hoge3/-1/@callback"
    }, 100)
}

function hoge3 (connid) {
    $("pre").append ("\n" + "hoge3" + connid)

    setTimeout (function () {
        location.href = "bridge:///@hexifydata" // causes error
    }, 100)
}

init ();
