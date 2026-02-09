import re
from functools import cache
import sys

# RULE = (LHS,PRIORITY,RHS,LOOKAHEADS,VAL_CNT,FUNC)
RAW_RULES = (
    (   "S"    ,   0   ,  "E"     ,   "$"       ,   1   ,   lambda x:x        ),
    (   "E"    ,   1   ,  "E+T"   ,   "+-)$"    ,   2   ,   lambda x,y:x+y    ),
    (   "E"    ,   1   ,  "E-T"   ,   "+-)$"    ,   2   ,   lambda x,y:x-y    ),
    (   "E"    ,   0   ,  "T"     ,   "+-)$"    ,   1   ,   lambda x:x        ),
    (   "T"    ,   1   ,  "T*F"   ,   "*/+-)$"  ,   2   ,   lambda x,y:x*y    ),
    (   "T"    ,   1   ,  "T/F"   ,   "*/+-)$"  ,   2   ,   lambda x,y:x//y   ),
    (   "T"    ,   0   ,  "F"     ,   "*/+-)$"  ,   1   ,   lambda x:x        ),
    (   "F"    ,   1   ,  "P^F"   ,   "*/+-)$"  ,   2   ,   lambda x,y:x**y   ),
    (   "F"    ,   0   ,  "P"     ,   "*/+-)$"  ,   1   ,   lambda x:x        ),
    (   "P"    ,   0   ,  "(E)"   ,   "*/+-)$"  ,   1   ,   lambda x:x        ),
    (   "P"    ,   0   ,  "I"     ,   "^*/+-)$" ,   1   ,   lambda x:x        ), # I for Integer
)

expr   = input()
tokens = re.findall(r'[\+\-\*\/\^\(\)]|\d+',expr)
tokens.append('$')

rule_map = {}
for lhs, priority, rhs, lookaheads, val_cnt, func in RAW_RULES:
    if lhs not in rule_map:
        rule_map[lhs] = []
    rule_map[lhs].append((priority,rhs,lookaheads,val_cnt,func))

for k,v in rule_map.items():
    rule_map[k] = tuple(v)

# LALR Parser
# we are now using python, which enabled us to use functions as parameters
# 2 TABLES: ACTION & GOTO

# item = (lhs,priority,rhs,lookahead,val_cnt,func,idx)

class ReduceAction:
    def __init__(self,lhs,reduce_len,val_cnt,func):
        self.lhs = lhs
        self.reduce_len = reduce_len
        self.val_cnt = val_cnt
        self.func = func
    def tuple(self):
        return (self.lhs,self.reduce_len,self.val_cnt,self.func)
    def __repr__(self):
        return "Reduce("+str(self.tuple())+")"

class ShiftAction:
    def __init__(self,target_closure):
        self.target_closure = target_closure
    def closure(self):
        return self.target_closure
    def __repr__(self):
        return "Shift("+str(self.closure())+")"

@cache
def make_closure_sym(sym):
    if sym not in rule_map:
        return ()
    res = set()
    for priority, rhs, lookaheads,val_cnt,func in rule_map[sym]:
        res.add((sym,priority,rhs,lookaheads,val_cnt,func,0))
        if len(rhs) > 0 and rhs[0] != sym:
            res |= set(make_closure_sym(rhs[0]))
    return sorted(tuple(res))

States       = {}

@cache
def make_closure(items):
    closure = set(items)
    for _,_,rhs,_,_,_,idx in items:
        if idx < len(rhs):
            closure |= set(make_closure_sym(rhs[idx]))
    return tuple(sorted(closure))

def solve_table(items):
    closure = make_closure(items)
    if closure in States:
        return

    movables = set()
    for lhs,priority,rhs,lookaheads,val_cnt,func,idx in closure:
        if idx < len(rhs):
            movables.add(rhs[idx])
        elif idx == len(rhs):
            movables |= set(lookaheads)

    for mov_sym in movables:
        reduce_action = None
        next_closure  = []
        for lhs,priority,rhs,lookaheads,val_cnt,func,idx in closure:
            if idx < len(rhs) and rhs[idx] == mov_sym:
                next_closure.append((lhs,priority,rhs,lookaheads,val_cnt,func,idx+1))
            if idx == len(rhs) and mov_sym in lookaheads:
                reduce_action = ReduceAction(lhs,len(rhs),val_cnt,func)
        if reduce_action is not None: 
            if closure not in States:
                States[closure] = {}
            States[closure][mov_sym] = reduce_action
        else:
            next_closure = make_closure(tuple(next_closure))
            if closure not in States:
                States[closure] = {}
            States[closure][mov_sym] = ShiftAction(next_closure)
            solve_table(next_closure)

    return

solve_table(((*RAW_RULES[0],0),))

startClosure = None
endClosure   = None
for closure in States:
    if (*RAW_RULES[0],0) in closure:
        startClosure = closure
    if (*RAW_RULES[0],1) in closure:
        endClosure   = closure

# Start Parsing
stateStack = [startClosure]
symStack   = []
IntStack   = []

idx = 0
while idx < len(tokens):
    current_token: str = tokens[idx]
    current_sym        = current_token
    current_val        = None

    if current_token not in "+-*/^()$":
        current_sym = 'I'
        current_val = int(current_token)

    if current_sym not in States[stateStack[-1]]:
        print('unexpected {0}'.format(current_token))
        sys.exit(1)
    
    next_state = States[stateStack[-1]][current_sym]
    if type(next_state) == ShiftAction:
        stateStack.append(next_state.closure())
        symStack.append(current_sym)
        if current_sym == 'I':
            IntStack.append(current_val)
        idx += 1
    elif type(next_state) == ReduceAction:
        lhs,reduce_len,val_cnt,func = next_state.tuple()
        for _ in range(reduce_len):
            stateStack .pop()
            symStack   .pop()
        args = [IntStack.pop() for _ in range(val_cnt)][::-1]
        IntStack.append(func(*args))
        symStack.append(lhs)
        if lhs == 'S':
            break # reduced to S, all complete
        next_state = States[stateStack[-1]][lhs]
        stateStack.append(next_state.closure())

    # # for debug purpose
    # print(len(stateStack))
    # print(symStack)
    # print(IntStack)

print(IntStack[0])