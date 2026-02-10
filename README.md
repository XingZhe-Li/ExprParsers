# 6 expr parser

This Repository is made for expression parsing with 6 different methods:

1. Recursive Descent Parsing

```
key note:
    use loop when left-combined,
    use recursion when right-combined.

this is a typical top-down method.

Actually there is another way of Recursive Descent Parsing that's more brute-force.
Just try every pattern. if failed, try next pattern. But in this way, you'd need to consume a same token multiple times.
```

2. Precedence Climbing

```
key note:
    next_min_prec = prec if is_right_assoc else prec + 1

to design a PCParser from nothing is hard since you'd determine what should be parsed before the loop.

key note: 
    so what should be coded before the loop?
    the atoms that could serve as the first term in you evaluation!
```

3. LL Parsing

```
LL Parsing have 2 evaluation styles:
    1. semantic actions (
        push action unit into stack
    )
    2. attributes (
        Synthesized (inferred in a bottom-up order), 
        Inherit (inferred in a top-down order) 
    )
    two evaluation style has identical capability when parsing, 
    but the latter always requires a more complex implementation.
    (for you'd need some kind of tree!)

though first sets (infer it in a bottom-up order for convience!) 
    & follow sets (infer it in a top-down  order for convience!)
    does help build the LL table, but the table does not entirely depends on these 2 sets,
    what matters most is actually the productions. The 2 sets are just a way
    for quicker resolution. You see, not all symbols in the first set
    goes into a same production.

key note:
    parser structure: table + 2 stack (for matching & for evaluation)
    left-combined & right-combined are determined by the order of actions
        left-combined:  Expr' -> + Term #ADD Expr'
        right-combined: Expr' -> + Term Expr' #ADD
    if you are using attributes , that's the difference between kinds of attributes , in this case:
        left-combined:  Inherit attribute
        right-combined: Synthesized attribute
    Oh! Keep in mind epsilon & end symbol when interfercing the sets!
```

4. SLR Parsing

```
Notice the difference: LR(0) < SLR < LALR < LR(1)
LR Grammars does always require a starting sign: S' -> S (Accept state should be set on S', since in some grammar, you'd get multiple S, just like Expr, so it could be hard to determine whether parsing is ended.)
While in LL Grammars , it could be optional.
```

5. LALR Parsing

```
Nothing to talk about, check out PRELIMINARIES.md & SLR Parsing first.

Not Implemented for being 2 complex
```

6. Pratt Parsing

```
one pass expr parser with 2 stacks only,
the key: 
    calculate when operators in the stack are priorer to what's lately appended. 
    the implementation of left/right-combined lies in (>= or >)

Pratt Parse does not provide a decent syntax error detection.
```

In Addition:

7. Earley Parsing

```
Earley Parsing is something really similiar to LR Parser.
An earley parser have 3 actions: 
    Predict    , corresponding to LR's closure,
    Scan       , corresponding to LR's shift,
    Completion , corresponding to LR's reduce.

the difference consists in that an Earley Parser does not force it's user to make a choice when facing Shift-Reduce conflict,
    Earley Parser do both, and undoubtedly, here's a trade-off between parsing capability and parsing speed.

An Earley Parser can't be prebuilt with something like closure.
Because in LR, the stack length is determined by your symbols, like "(E)" takes 3 position in your stack history.
While in Earley Parser, the length of chart structure (an array that replaces the state stack) is determined by the inputing tokens,
like "(E)" may actually be "(1+2)", then it would take 5 position in chart. So the state space is relevant to the length of your tokens, 
then it can't be precompiled.

So, how'd on earth a earley compiler work?
Chart is a list of list, where len(chart) == len(tokens) (EOF sign included).
And in the list of chart[i], it's recorded that some items are parsed to some extent,

eg.
    chart[5] = ("E","E+T",2,3)
    means a Item of E -> E + T is parsed to Index 2 (or let's say E -> E + .T),
    with its start at the 3rd token, and its end at 5th token.

once this item is completed, the parser goes back to the start pos of this item (in this case, 3, in some implementation 3-1, depending on your way of indexing), and checks all the items in chart[3] that accepts a "E", adding a moved items to chart[complete_index+1] , and if they are complete, repeat this process.

A gemini made demo is presented in EarleyDemo.py, for I'm too lazy to build another LR like parser. 
```

Made for practice
Pay attention to the difference in implementation when operators are left/right combined.

By the way, regular expression can be implemented by finite automata.