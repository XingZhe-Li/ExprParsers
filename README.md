# 6 expr parser

This Repository is made for expression parsing with 6 different methods:

1. Recursive Descent Parsing

```
key note:
    use loop when left-combined,
    use recursion when right-combined.

this is a typical top-down method.
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

Made for practice
Pay attention to the difference in implementation when operators are left/right combined.

By the way, regular expression can be implemented by finite automata.