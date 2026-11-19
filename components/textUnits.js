.pragma library

// The pieces a text effect shows one by one. A line of Latin letters is cut into single
// characters. A line with other scripts (Bengali, Arabic, emoji, ...) is cut into words and the
// spaces between them, because cutting between the letters of a joined script breaks their shapes.
function split(text) {
    if (/[^\u0000-\u024F]/.test(text))
        return text.split(/(\s+)/).filter(function (s) { return s.length > 0 })
    return text.split("")
}

// How many pieces two lists share at the start
function sharedStart(a, b) {
    var n = Math.min(a.length, b.length)
    var i = 0
    while (i < n && a[i] === b[i]) i++
    return i
}

// A repeatable "random" number in 0..1 from two numbers: the same input always gives the same
// output, so a text types the same way on every run
function steady(a, b) {
    var x = Math.abs(Math.sin(a * 12.9898 + b * 78.233) * 43758.5453)
    return x - Math.floor(x)
}

// The wait before a piece (ms): `speed` give or take `jitter` (0..1) of it
function keystrokeWait(speed, jitter, a, b) {
    return Math.max(1, Math.round(speed * (1 + jitter * (2 * steady(a, b) - 1))))
}