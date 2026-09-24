pragma Singleton
import QtQuick
import Quickshell

// Calculadora do launcher: um parser próprio (descida recursiva), sem eval — só aceita números,
// operadores, parênteses, funções e constantes conhecidas. Aceita vírgula decimal ("2,5").
//
//   + - * / ^ %(resto)   ( )   pi e   sqrt abs sin cos tan asin acos atan log(base 10) ln exp
//   round floor ceil      e 20% de 50 → "50 * 20%" também funciona como percentagem.
Singleton {
    id: root

    // Devolve o resultado (número) ou null se `text` não for uma expressão válida.
    function evaluate(text) {
        const src = String(text).replace(/,/g, ".").replace(/×/g, "*").replace(/÷/g, "/").trim();
        if (src === "" || !/[\d)]/.test(src) || !/[+\-*/^%()a-z]/i.test(src.replace(/^[+-]?\d+(\.\d+)?$/, "")))
            return null;
        const tokens = tokenize(src);
        if (!tokens)
            return null;
        let pos = 0;
        const peek = () => tokens[pos];
        const next = () => tokens[pos++];

        const functions = {
            sqrt: Math.sqrt,
            abs: Math.abs,
            sin: Math.sin,
            cos: Math.cos,
            tan: Math.tan,
            asin: Math.asin,
            acos: Math.acos,
            atan: Math.atan,
            log: Math.log10,
            ln: Math.log,
            exp: Math.exp,
            round: Math.round,
            floor: Math.floor,
            ceil: Math.ceil
        };
        const constants = {
            pi: Math.PI,
            e: Math.E
        };

        // expr := term (('+'|'-') term)*
        function expr() {
            let v = term();
            while (peek() === "+" || peek() === "-") {
                const op = next();
                const r = term();
                v = op === "+" ? v + r : v - r;
            }
            return v;
        }
        // term := power (('*'|'/'|'%') power)*
        function term() {
            let v = power();
            while (peek() === "*" || peek() === "/" || peek() === "%" && tokens[pos + 1] !== undefined && tokens[pos + 1] !== ")" && !"+-*/".includes(tokens[pos + 1])) {
                const op = next();
                const r = power();
                v = op === "*" ? v * r : op === "/" ? v / r : v % r;
            }
            return v;
        }
        // power := unary ('^' power)?
        function power() {
            const b = unary();
            if (peek() === "^") {
                next();
                return Math.pow(b, power());
            }
            return b;
        }
        // unary := ('-'|'+') unary | postfix
        function unary() {
            if (peek() === "-") {
                next();
                return -unary();
            }
            if (peek() === "+") {
                next();
                return unary();
            }
            return postfix();
        }
        // postfix := primary '%'?   (percentagem: 20% = 0.2)
        function postfix() {
            let v = primary();
            if (peek() === "%" && (tokens[pos + 1] === undefined || tokens[pos + 1] === ")" || "+-*/".includes(tokens[pos + 1]))) {
                next();
                v /= 100;
            }
            return v;
        }
        function primary() {
            const t = next();
            if (t === undefined)
                throw "fim";
            if (typeof t === "number")
                return t;
            if (t === "(") {
                const v = expr();
                if (next() !== ")")
                    throw "parêntese";
                return v;
            }
            if (constants[t] !== undefined)
                return constants[t];
            if (functions[t]) {
                if (next() !== "(")
                    throw "função";
                const v = expr();
                if (next() !== ")")
                    throw "parêntese";
                return functions[t](v);
            }
            throw "símbolo";
        }

        try {
            const v = expr();
            if (pos !== tokens.length || !isFinite(v))
                return null;
            return v;
        } catch (e) {
            return null;
        }
    }

    function tokenize(src) {
        const out = [];
        const re = /\s*(\d+\.?\d*(?:e[+-]?\d+)?|\.\d+|[a-z]+|[+\-*/^%()])/iy;
        let m;
        re.lastIndex = 0;
        while (re.lastIndex < src.length) {
            m = re.exec(src);
            if (!m)
                return /^\s*$/.test(src.slice(re.lastIndex)) ? out : null;
            const t = m[1];
            out.push(/^[\d.]/.test(t) ? parseFloat(t) : t.toLowerCase());
        }
        return out;
    }

    // Resultado legível: até 10 casas decimais, sem zeros à direita, com vírgula (pt-PT).
    function format(v) {
        const s = Math.abs(v) >= 1e15 || (Math.abs(v) < 1e-6 && v !== 0) ? v.toExponential(6) : String(Number(v.toFixed(10)));
        return s.replace(".", ",");
    }
}
