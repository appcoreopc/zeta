The Zeta Programming Language
=============================

[![Join the chat at https://gitter.im/maximecb/zeta](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/maximecb/zeta?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Build Status](https://travis-ci.org/maximecb/zeta.png)](https://travis-ci.org/maximecb)

This is an implementation of a Virtual Machine (VM) for the Zeta programming
language I'm working on in my spare time. Zeta draws inspiration from LISP,
Smalltalk, ML, Python, JavaScript and C. The language is currently at the early
prototype stage, meaning the syntax and semantics are likely to change a lot
in the coming months.

At the moment, this platform and language is mostly of interest to tinkerers
and those with a special interest in compilers or language design. It's still
much too early to talk about adoption and long term goals. I'll be happy if
this project can help me and others learn more about language and compiler
design.

## Quickstart

Requirements:

- A C compiler, GCC 4.8+ recommended (clang and others untested)

- GNU make

- A POSIX compliant OS (Linux or Mac OS)

To built the Zeta VM, go to the source directory and run `make`

Tests can then be executed by running the `make test` command

A read-eval-print loop (shell) can be started by running the `./zeta` binary

## Language Design

Planned features of the Zeta programming language include:

- Dynamic typing

- Garbage collection

- Dynamically extensible objects with prototypal inheritance, as in JavaScript

- Dynamically extensible arrays with zero-based indexing, as in JavaScript

- No distinction between statements and expression, everything is an expression, as in LISP

- A user-extensible grammar, giving programmers the ability to define new syntactic constructs

- Operator overloading, to allow defining new types that behave like native types

- Functional constructs such as map and foreach

- A module system

- A very easy to use canvas library to render simple 2D graphics and make simple UIs

- The ability to suspend and resume running programs

Zeta takes inspiration from JavaScript, but notable differences include:

- No `undefined` or `null` values

- No `new` keyword or constructor functions

- The `==` and `!=` operators are strict identity comparisons

- Object properties cannot be deleted

- Attempting to read missing object properties throws an exception

- Arrays cannot have "holes" (missing elements)

- Distinct 64-bit integer and floating-point value types

- 64-bit integers overflow as part of normal semantics

- Arithmetic operators do not accept strings as input values

- Global variables are not shared among different source files

- Global variables must be declared before they are assigned to

- The `eval` function cannot access local variables

- A distinction between `print` and `println` functions

If you want to know more about my views on programming language design, I've
written several
[blog posts on the topic](http://pointersgonewild.com/category/programming-languages/).

## Zeta Core Language Syntax

The syntax of the Zeta programming language is not finalized. The language is
designed to be easy to parse (no backtracking or far away lookup), relatively
concise, easy to read and familiar-seeming to most experienced programmers.
In Zeta, every syntactic construct is an expression which has a value (although
that value may have no specific meaning in some cases).

The Zeta grammar will be extensible. The Zeta core language itself (without
extensions), is going to be kept intentionally simple and minimalistic.
Features such as regular expressions, switch statements, pattern matching and
template strings will be implemented as grammar extension in libraries, and
not part of the core language. The advantage here is that the core VM will not
need to know anything about things such as regular expressions, and multiple
competing regular expression packages can be implemented for Zeta.

Here is an example of what Zeta code might look like:

```
/*
Load/import the standard IO module
Modules are simple objects with properties
*/
io = import("io")

io.println("This is an example Zeta script");

// Fibonacci function
let fib = fun (n) if n < 1 then n else fib(n-1) + fib(n-1)

// Compute the meaning of life and print out the answer
io.println(fib(42))

// This is a global variable declaration
var y

let foo = fun (n)
{
    io.println("It's also possible to execute expressions in sequence")
    io.println("inside blocks with curly braces.")

    // Since we have parenthesized expressions, we could almost pretend
    // This is JavaScript code, except for the lack of semicolons
    if n < 1 then
    {
        io.println("n is less than 1")
    }
    else
    {
        io.println("n is greater than or equal to 1")
    }

    // This is a local constant declaration, x cannot be reassigned to
    let x = 7 + 1

    // This assigns to the global variable y
    y = 3

    // We can also create anonymous closures
    fun () x + y

    // Function return the the last expression evaluated
}

// This is an object literal
let obj = :{ x:3, y:5 }

// When declaring a method, the "this" argument is simply the first
// function argument, and you can give it the name you want, avoiding all
// of the JavaScript "this" issues
obj.method = fun (this, x) this.x = x

// This object inherits from obj using prototypal inheritance
let obj2 = obj:{ y:6, z:7 }

// There are optional semicolons which are useful in some cases
// to visually and sometimes semantically separate expressions
obj2.z = 6; obj2.w = 7;

// The language suppports arrays similar to JS
let arr = [0, 1, 2, obj, obj2]

// Make the fib and foo functions available to other modules.
export('fib', fib)
export('foo', foo)
```

Everything is still in flux. Your comments on the syntax and above
example are welcome.

## Language Extensions

Zeta's "killer feature" will be the ability to extend the language in a way that feels native. The core language will be kept lean and minimal, but a library of "officially sanctioned" language extensions will be curated. For instance, the core Zeta language will only support functions with fixed arity and positional arguments. I would like, however, to implement variable arity functions, default values, optional and keyword arguments (as in Python) as a language extension.

Some useful language extensions I can think of

- Variable arity functions, optional arguments, keyword arguments
- Multiple return values
- For-in loops to iterate over various containers
- Dictionary types
- PHP-like templating mode
- MATLAB-like vector and matrix arithmetic
- JS-like regular expressions
- JS-like template strings
- A "jsify" extension that makes the grammar JS-like

## Plan of Action

I'm currently writing a Zeta compiler in D, which will generate D code. This
compiler will only be used to bootstap the language. It will not
perform any optimizations and will not be particularly robust or
user-friendly beyond what is needed for the initial bootstrap step.

A more advanced, self-hosted Zeta compiler will be
written in Zeta, and will target LLVM. This self-hosted compiler will use
type inference to optimize code and will be able to generate executables.

If you would like to contribute or get a better idea of tasks to be completed,
take a look at the list of [open issues](https://github.com/maximecb/zeta/issues).

