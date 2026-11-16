.pragma library

// Calculator, unit and currency engine for the launcher. Plain functions: give it the
// typed text (and the exchange rates) and it gives back rows for the list.
// evaluate() gives the answer row, or null when the text is not a calculation.
// suggest() gives suggestion rows while you are still typing.
// An answer row is { title, sub, copy }: the big text, the small text under it, and the
// plain number that Enter copies ("" when there is nothing to copy yet).
// A suggestion row is { title, sub, copy: "", fill }: fill is the text that Enter puts
// into the search box.

function has(obj, key) { return Object.prototype.hasOwnProperty.call(obj, key) }

// ── Number formatting ──

// The number as plain digits, rounded to dp decimals. Tiny and huge numbers use
// exponent form.
function raw(n, dp) {
    var a = Math.abs(n)
    if (a !== 0 && (a >= 1e15 || a < 1e-6)) return n.toExponential(4)
    var p = Math.pow(10, dp)
    return String(Math.round(n * p) / p)
}

// The same with thousands separators: 1234567.5 becomes 1,234,567.5
function pretty(n, dp) {
    var s = raw(n, dp)
    if (s.indexOf("e") !== -1) return s
    var parts = s.split(".")
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
    return parts.join(".")
}

function toNumber(s) { return parseFloat(s.replace(/,/g, "")) }

// How old the exchange rates are, in words
function ageText(fetchedAt) {
    if (!fetchedAt) return ""
    var mins = Math.floor((Date.now() - fetchedAt) / 60000)
    if (mins < 1) return "just updated"
    if (mins < 60) return mins + "m old"
    var hours = Math.floor(mins / 60)
    if (hours < 48) return hours + "h old"
    return Math.floor(hours / 24) + "d old"
}

// ── Spelled-out numbers ("two thousand five hundred") ──

var SMALL = {
    zero: 0, one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8,
    nine: 9, ten: 10, eleven: 11, twelve: 12, thirteen: 13, fourteen: 14, fifteen: 15,
    sixteen: 16, seventeen: 17, eighteen: 18, nineteen: 19
}
var TENS = { twenty: 20, thirty: 30, forty: 40, fifty: 50, sixty: 60, seventy: 70, eighty: 80, ninety: 90 }
var SCALES = { thousand: 1e3, million: 1e6, billion: 1e9 }

function isNumWord(w) {
    return has(SMALL, w) || has(TENS, w) || w === "hundred" || has(SCALES, w)
}

// Reads number words from the start of a word list.
// Returns { value, used } (used = how many words it took) or null if there are none.
function readWords(words) {
    var total = 0, current = 0, used = 0, seen = false
    for (var i = 0; i < words.length; i++) {
        var w = words[i]
        if (has(SMALL, w)) current += SMALL[w]
        else if (has(TENS, w)) current += TENS[w]
        else if (w === "hundred") current = (current === 0 ? 1 : current) * 100
        else if (has(SCALES, w)) { total += (current === 0 ? 1 : current) * SCALES[w]; current = 0 }
        else if (w === "and" && seen && i + 1 < words.length && isNumWord(words[i + 1])) continue
        else break
        seen = true
        used = i + 1
    }
    return seen ? { value: total + current, used: used } : null
}

// ── Currencies ──
// Names you can type for a currency. Any other three-letter code works too, as long as
// the exchange rates have it (see candidates()).
var CURRENCY = {
    "usd": "USD", "dollar": "USD", "$": "USD",
    "bdt": "BDT", "taka": "BDT", "tk": "BDT", "৳": "BDT",
    "eur": "EUR", "euro": "EUR", "€": "EUR",
    "gbp": "GBP", "pound": "GBP", "£": "GBP",
    "inr": "INR", "rupee": "INR", "₹": "INR",
    "jpy": "JPY", "yen": "JPY", "¥": "JPY"
}

// Every name of each currency, for matching what you have typed so far
var CUR_NAMES = {}
Object.keys(CURRENCY).forEach(function (name) {
    var code = CURRENCY[name]
    if (!has(CUR_NAMES, code)) CUR_NAMES[code] = []
    CUR_NAMES[code].push(name)
})

function namesOfCur(code) {
    return has(CUR_NAMES, code) ? CUR_NAMES[code] : [code.toLowerCase()]
}

// The currencies offered as suggestions, in this order
var TARGET_CURRENCIES = ["BDT", "USD", "EUR", "GBP", "INR", "JPY"]

// What a bare number ("100") suggests: pairs of names, each one a currency or a unit
var BARE_PAIRS = [["usd", "bdt"], ["bdt", "usd"], ["usd", "eur"], ["usd", "inr"], ["km", "mi"], ["kg", "lb"]]

// ── Units ──
// Every unit of a kind is stored as a factor to that kind's base unit (m, kg, l, s, m/s).
// Temperature is the exception and is converted by formula. The order of the lines below
// is the order of the suggestions, so the common units come first.
var UNITS = {}
var UNIT_LIST = []

function addUnit(cat, factor, names) {
    var u = { cat: cat, f: factor, label: names[0], names: names }
    names.forEach(function (n) { UNITS[n] = u })
    UNIT_LIST.push(u)
}

function addTemp(kind, label, names) {
    var u = { cat: "temp", t: kind, label: label, names: names }
    names.forEach(function (n) { UNITS[n] = u })
    UNIT_LIST.push(u)
}

// A trailing "s" is dropped when a name is not found, so only irregular plurals are listed
addUnit("length", 1, ["m", "meter", "metre"])
addUnit("length", 1000, ["km", "kilometer", "kilometre"])
addUnit("length", 0.01, ["cm", "centimeter", "centimetre"])
addUnit("length", 0.001, ["mm", "millimeter", "millimetre"])
addUnit("length", 1609.344, ["mi", "mile"])
addUnit("length", 0.3048, ["ft", "foot", "feet"])
addUnit("length", 0.0254, ["in", "inch", "inches"])
addUnit("length", 0.9144, ["yd", "yard"])

addUnit("mass", 1, ["kg", "kilogram", "kilo"])
addUnit("mass", 0.001, ["g", "gram"])
addUnit("mass", 0.45359237, ["lb", "lbs", "pound"])
addUnit("mass", 0.028349523125, ["oz", "ounce"])
addUnit("mass", 0.000001, ["mg", "milligram"])
addUnit("mass", 1000, ["tonne"])

addUnit("volume", 1, ["l", "liter", "litre"])
addUnit("volume", 0.001, ["ml", "milliliter", "millilitre"])
addUnit("volume", 3.785411784, ["gal", "gallon"])

addUnit("time", 1, ["s", "sec", "second"])
addUnit("time", 60, ["min", "minute"])
addUnit("time", 3600, ["h", "hr", "hour"])
addUnit("time", 86400, ["day"])
addUnit("time", 604800, ["week"])
addUnit("time", 0.001, ["ms", "millisecond"])

addUnit("speed", 1000 / 3600, ["km/h", "kmh", "kph"])
addUnit("speed", 0.44704, ["mph"])
addUnit("speed", 1, ["m/s", "mps"])
addUnit("speed", 1852 / 3600, ["knot", "kt"])

addTemp("c", "°C", ["c", "°c", "celsius"])
addTemp("f", "°F", ["f", "°f", "fahrenheit"])
addTemp("k", "K", ["k", "kelvin"])

function toCelsius(v, t) { return t === "c" ? v : t === "f" ? (v - 32) * 5 / 9 : v - 273.15 }
function fromCelsius(c, t) { return t === "c" ? c : t === "f" ? c * 9 / 5 + 32 : c + 273.15 }

// What a typed name could mean: a currency, a unit, or both ("pound" is GBP or lb).
// Both sides of a conversion are matched together, so the pair decides.
function candidates(text, rates) {
    var out = []
    var keys = [text]
    if (text.length > 1 && text.charAt(text.length - 1) === "s") keys.push(text.slice(0, -1))
    for (var i = 0; i < keys.length; i++) {
        if (has(CURRENCY, keys[i])) out.push({ kind: "cur", code: CURRENCY[keys[i]] })
        if (has(UNITS, keys[i])) out.push({ kind: "unit", u: UNITS[keys[i]] })
        if (out.length > 0) break
    }
    if (out.length === 0 && /^[a-z]{3}$/.test(text) && rates && has(rates, text.toUpperCase()))
        out.push({ kind: "cur", code: text.toUpperCase() })
    return out
}

// ── Conversions ("100 dollar to tk", "5 km to m") ──

// Reads the amount at the start of the left side: "100 usd", "$100", "hundred dollar".
// Returns { amount, unit, words } (words is true for spelled-out numbers) or null.
function parseAmount(left) {
    var m = left.match(/^([$€£₹৳¥])\s*(\d[\d,]*\.?\d*|\.\d+)$/)
    if (m) return { amount: toNumber(m[2]), unit: m[1], words: false }
    m = left.match(/^(-?(?:\d[\d,]*\.?\d*|\.\d+))\s*(.*)$/)
    if (m) return { amount: toNumber(m[1]), unit: m[2].trim(), words: false }
    var words = left.split(/\s+/)
    var r = readWords(words)
    if (r) return { amount: r.value, unit: words.slice(r.used).join(" "), words: true }
    return null
}

function convertCurrency(amount, from, to, rates, fetchedAt) {
    var head = pretty(amount, 2) + " " + from + " → " + to
    if (!rates || !has(rates, from) || !has(rates, to))
        return { title: "Rates not loaded yet", sub: head, copy: "" }
    var value = amount / rates[from] * rates[to]
    var dp = Math.abs(value) >= 1 ? 2 : 4
    var age = ageText(fetchedAt)
    return {
        title: pretty(value, dp) + " " + to,
        sub: head + (age !== "" ? " · rates " + age : ""),
        copy: raw(value, dp)
    }
}

function convertUnit(amount, a, b) {
    var value = a.cat === "temp"
        ? fromCelsius(toCelsius(amount, a.t), b.t)
        : amount * a.f / b.f
    var dp = Math.abs(value) >= 1 ? 4 : 6
    return {
        title: pretty(value, dp) + " " + b.label,
        sub: pretty(amount, 6) + " " + a.label + " → " + b.label,
        copy: raw(value, dp)
    }
}

function tryConvert(t, rates, fetchedAt) {
    // "to" first, so that "5 in to cm" is not split at the inch
    var m = t.match(/^(.+?)\s+(?:to|into)\s+(.+)$/) || t.match(/^(.+?)\s+in\s+(.+)$/)
    if (!m) return null
    var left = parseAmount(m[1])
    if (!left || left.unit === "") return null
    var from = candidates(left.unit, rates)
    var to = candidates(m[2].trim(), rates)
    for (var i = 0; i < from.length; i++) {
        for (var j = 0; j < to.length; j++) {
            var a = from[i], b = to[j]
            if (a.kind === "cur" && b.kind === "cur")
                return convertCurrency(left.amount, a.code, b.code, rates, fetchedAt)
            if (a.kind === "unit" && b.kind === "unit" && a.u.cat === b.u.cat)
                return convertUnit(left.amount, a.u, b.u)
        }
    }
    return null
}

// ── Suggestions while typing ──
// "100" suggests a few common conversions, "100 dollar" suggests where dollars can go,
// "100 dollar to t" narrows that to the targets starting with "t", and "100 dol" suggests
// how to finish the unit.

// Does any name start with what was typed?
function anyPrefix(names, p) {
    for (var i = 0; i < names.length; i++) {
        if (names[i].indexOf(p) === 0) return true
    }
    return false
}

// Does a target fit what was typed after "to"? Nothing typed fits all. A name typed in
// full (or in the plural) does not count: that conversion is already the answer row.
function nameMatch(names, f) {
    if (f === "") return true
    var hit = false
    for (var i = 0; i < names.length; i++) {
        if (names[i] === f || names[i] === f.replace(/s$/, "")) return false
        if (names[i].indexOf(f) === 0) hit = true
    }
    return hit
}

// Currencies to offer next to src. Once you type a few letters, every currency in the
// rates can match, not only the listed ones.
function currencyTargets(src, f, rates) {
    var codes = TARGET_CURRENCIES.slice()
    if (f !== "" && rates) {
        Object.keys(rates).forEach(function (c) {
            if (codes.indexOf(c) === -1) codes.push(c)
        })
    }
    return codes.filter(function (c) { return c !== src && nameMatch(namesOfCur(c), f) })
}

// Units of the same kind as src
function unitTargets(src, f) {
    return UNIT_LIST.filter(function (u) {
        return u.cat === src.cat && u !== src && nameMatch(u.names, f)
    })
}

// The name you could type for something, put into the search box by Enter
function nameOf(x) {
    return x.kind === "cur" ? x.code.toLowerCase() : x.u.names[0]
}

// One suggestion row: the finished conversion, with the text that fills the box
function makeRow(amount, a, b, fill, rates, fetchedAt) {
    var r = a.kind === "cur"
        ? convertCurrency(amount, a.code, b.code, rates, fetchedAt)
        : convertUnit(amount, a.u, b.u)
    // No rates yet: show the plain question instead of an error
    if (r.copy === "") return { title: r.sub, sub: "waiting for rates", copy: "", fill: fill }
    return { title: r.title, sub: r.sub, copy: "", fill: fill }
}

// Rows that finish a half-typed unit ("100 dol" gives "100 USD")
function completeSource(left) {
    var amountText = raw(left.amount, 6)
    var out = []
    TARGET_CURRENCIES.forEach(function (c) {
        if (anyPrefix(namesOfCur(c), left.unit))
            out.push({ title: amountText + " " + c, sub: "then pick what to convert to", copy: "", fill: amountText + " " + c.toLowerCase() + " to " })
    })
    UNIT_LIST.forEach(function (u) {
        if (anyPrefix(u.names, left.unit))
            out.push({ title: amountText + " " + u.label, sub: "then pick what to convert to", copy: "", fill: amountText + " " + u.names[0] + " to " })
    })
    return out
}

function suggest(text, rates, fetchedAt) {
    var t = text.trim().toLowerCase()
    if (t === "") return []
    var m = t.match(/^(.+?)\s+(?:to|into)\s+(.+)$/) || t.match(/^(.+?)\s+(?:to|into)$/)
    var hasTo = m !== null
    var leftText = hasTo ? m[1] : t
    var filter = hasTo && m[2] ? m[2].trim() : ""

    var left = parseAmount(leftText)
    if (!left) return []

    // A spelled-out number alone ("one") is more likely the start of an app name
    if (left.words && left.unit === "") return []

    // Just a number: a few common conversions
    if (left.unit === "") {
        if (hasTo) return []
        return BARE_PAIRS.map(function (p) {
            var a = candidates(p[0], rates)[0]
            var b = candidates(p[1], rates)[0]
            return makeRow(left.amount, a, b, raw(left.amount, 6) + " " + p[0] + " to " + p[1], rates, fetchedAt)
        })
    }

    // A unit that is not finished yet
    var from = candidates(left.unit, rates)
    if (from.length === 0) {
        if (hasTo) return []
        return completeSource(left).slice(0, 4)
    }

    // A known unit: where it can go, narrowed by what follows "to"
    var src = from[0]
    var targets = src.kind === "cur"
        ? currencyTargets(src.code, filter, rates)
        : unitTargets(src.u, filter)
    return targets.slice(0, 6).map(function (target) {
        var b = src.kind === "cur" ? { kind: "cur", code: target } : { kind: "unit", u: target }
        return makeRow(left.amount, src, b, leftText + " to " + nameOf(b), rates, fetchedAt)
    })
}

// ── Math ("12*7+3", "2^10", "sqrt(16)", "200*10%") ──
// A small parser, not eval: + - * / ^ ( ), x and × for times, ÷ for divide, % for percent,
// and the functions sqrt, abs and the constant pi.
// Returns { value, ops } or null. ops counts the operators used, so that a bare number
// is not shown as a calculation.
function parseMath(src) {
    var pos = 0
    var ops = 0

    function skip() { while (pos < src.length && src.charAt(pos) === " ") pos++ }
    function next() { skip(); return src.charAt(pos) }
    function fail() { throw new Error("not math") }

    function expr() {
        var v = term()
        for (;;) {
            var c = next()
            if (c === "+") { pos++; ops++; v += term() }
            else if (c === "-") { pos++; ops++; v -= term() }
            else return v
        }
    }

    function term() {
        var v = unary()
        for (;;) {
            var c = next()
            if (c === "*" || c === "x" || c === "×") { pos++; ops++; v *= unary() }
            else if (c === "/" || c === "÷") { pos++; ops++; v /= unary() }
            else return v
        }
    }

    // -2^2 is -(2^2), as in maths
    function unary() {
        var c = next()
        if (c === "-") { pos++; return -unary() }
        if (c === "+") { pos++; return unary() }
        return power()
    }

    function power() {
        var base = postfix()
        var c = next()
        if (c === "^") { pos++; ops++; return Math.pow(base, unary()) }
        if (c === "*" && src.charAt(pos + 1) === "*") { pos += 2; ops++; return Math.pow(base, unary()) }
        return base
    }

    function postfix() {
        var v = primary()
        while (next() === "%") { pos++; ops++; v /= 100 }
        return v
    }

    function primary() {
        if (next() === "(") {
            pos++
            var inner = expr()
            if (next() !== ")") fail()
            pos++
            ops++
            return inner
        }
        var rest = src.slice(pos)
        var m = /^(\d[\d,]*\.?\d*|\.\d+)/.exec(rest)
        if (m) { pos += m[0].length; return toNumber(m[0]) }
        m = /^(sqrt|abs|pi)\b/.exec(rest)
        if (m) {
            pos += m[0].length
            if (m[0] === "pi") return Math.PI
            if (next() !== "(") fail()
            pos++
            var arg = expr()
            if (next() !== ")") fail()
            pos++
            ops++
            return m[0] === "sqrt" ? Math.sqrt(arg) : Math.abs(arg)
        }
        fail()
    }

    try {
        var value = expr()
        skip()
        if (pos !== src.length) return null
        return { value: value, ops: ops }
    } catch (e) {
        return null
    }
}

function tryMath(t) {
    var res = parseMath(t)
    if (!res || !isFinite(res.value) || res.ops === 0) return null
    return { title: pretty(res.value, 6), sub: t, copy: raw(res.value, 6) }
}

// ── The way in ──
// Rates are { USD: 1, BDT: 122, ... } (units per 1 USD), fetchedAt is when they were fetched.
function evaluate(text, rates, fetchedAt) {
    var t = text.trim().toLowerCase()
    if (t === "") return null
    return tryConvert(t, rates, fetchedAt) || tryMath(t)
}