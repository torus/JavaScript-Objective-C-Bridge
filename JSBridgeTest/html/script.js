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
        hex += str.charCodeAt (i).toString (16)
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
        stack_push_operator (st, "hexstr")
        stack_push_operator (st, "str")
    }
}

function stack_push_data (st, op) {
    if (typeof (op) != "string")
        op = op.toString ()

    stack_push_raw_string (st, hexify (op))
    stack_push_operator (st, "hexstr")
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
    $("pre").append ("push: " + arguments)
    for (var i = 0; i < arguments.length; i ++) {
        stack_push_string (this.stack, arguments[i])
    }
    return this
}

JSBridgeStack.prototype.pushdata = function () {
    $("pre").append ("pushdata: " + arguments)
    for (var i = 0; i < arguments.length; i ++) {
        stack_push_data (this.stack, arguments[i])
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
    jsb.push ("hoge", "key").operate ("hmac_sha1").operate ("base64data").operate ("print").push ("hoge2", 0).operate ("callback").execute ()
}

function hoge2 () {
    $("pre").append ("\n" + "hoge2")

    var url = "http://scrw.in/"
    var jsb = new JSBridgeStack ()
    jsb.push ("Value1", "X-Scrw-Key1", "Value2", "X-Scrw-Key2", 2, url).operate ("http_post").push ("hoge3", 1).operate ("callback").execute ()
}

function hoge3 (connid) {
    $("pre").append ("\n" + "hoge3: conn ID: " + connid)

    var mesg = '<chat-entry room="opakapaka"><from><user-by-nickname><string>Toru</string></user-by-nickname><avatar-image><string>http://www.gravatar.com/avatar/5efc507a8db7167e2db7889a5597a3cd?s=40&amp;default=identicon</string></avatar-image></from><content><string>konichiwa</string></content></chat-entry>'

    var jsb = new JSBridgeStack ()
    jsb.pushdata (mesg).push ("Value1", "X-Scrw-Key1", "Value2", "X-Scrw-Key2", 2, "http://scrw.in/push.cgi").operate ("http_post").operate ("print").execute ()
}

init ();
