JavaScript-Objective-C Bridge
=============================

Low Level API
-------------

Pass operands and operators through the `location.href` property.
The path part of the specifined URL is used to represent a sequence of instruction.
JavaScript-Objective-C bridge bridge works as a stack machine.

For example:

    location.href = "bridge:///-123/-456/@add/-hoge/-1/@callback"

In this example, list of instructions is represented as `-123/-456/@add/-hoge/-1/@callback`.
A path component beginning with `-` means a operand, and a path component beginning with `@` means operator.

Operators are defined as methods of the `JavaScriptBridge` class.
