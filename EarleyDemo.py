class EarleyParser:
    def __init__(self, grammar, start_symbol):
        self.grammar = grammar
        self.start_symbol = start_symbol

    def parse(self, input_string):
        # 初始化 Chart
        chart = [[] for _ in range(len(input_string) + 1)]
        
        # 种子：在位置 0 预测起始符号
        self._predict(self.start_symbol, 0, 0, chart)
        print(f"输入 Tokens: {input_string}")
        print("-" * 60)

        # 主循环：处理每个位置
        for i in range(len(input_string) + 1):
            print(f"\n--- Chart {i} ---")
            
            # 这个 while 循环是为了处理 "预测" 可能引发新的 "预测" (比如链式非终结符)
            # 我们遍历当前 Chart[i] 的所有状态
            pos = 0
            while pos < len(chart[i]):
                item = chart[i][pos]
                lhs, rhs, dot, start = item
                print(f"  处理状态: {self._format_item(item)}")

                # --- 情况 1: 点还没到末尾 ---
                if dot < len(rhs):
                    # A. 点后面是终结符 (数字或符号)，且我们还没读完输入
                    if i < len(input_string) and self._is_terminal(rhs[dot]) and rhs[dot] == input_string[i]:
                        # 执行 SCAN：移动到下一个 Chart
                        new_item = (lhs, rhs, dot + 1, start)
                        if new_item not in chart[i + 1]:
                            chart[i + 1].append(new_item)
                            print(f"    SCAN -> 发现 '{rhs[dot]}', 移入 Chart {i+1}: {self._format_item(new_item)}")

                    # B. 点后面是非终结符
                    elif not self._is_terminal(rhs[dot]):
                        # 执行 PREDICT：把该非终结符的所有规则加入 Chart[i]
                        self._predict(rhs[dot], i, i, chart)

                # --- 情况 2: 点到了末尾 (这条规则匹配完了) ---
                else:
                    # 执行 COMPLETE：去 Chart[start] 找谁在等着这个 lhs
                    print(f"    COMPLETE: '{lhs}' 从 Chart {start} 到 Chart {i} 匹配完成!")
                    for prev_item in chart[start]:
                        prev_lhs, prev_rhs, prev_dot, prev_start = prev_item
                        # 如果前一个状态的点后面正好是我 (lhs)
                        if prev_dot < len(prev_rhs) and prev_rhs[prev_dot] == lhs:
                            newer_item = (prev_lhs, prev_rhs, prev_dot + 1, prev_start)
                            if newer_item not in chart[i]:
                                chart[i].append(newer_item)
                                print(f"    触发: Chart {i} 新增状态 {self._format_item(newer_item)}")

                pos += 1

        # 检查结果：在最后一个 Chart 中，是否有 S 完全匹配且起始位置为 0
        for item in chart[len(input_string)]:
            lhs, rhs, dot, start = item
            if lhs == self.start_symbol and dot == len(rhs) and start == 0:
                print("\n" + "="*60)
                print("🎉 解析成功！")
                return True
                
        print("\n" + "="*60)
        print("❌ 解析失败！")
        return False

    def _predict(self, nonterminal, rule_pos, input_pos, chart):
        """预测：添加非终结符的规则"""
        for lhs, rhs in self.grammar:
            if lhs == nonterminal:
                item = (lhs, rhs, 0, input_pos)
                if item not in chart[rule_pos]:
                    chart[rule_pos].append(item)
                    print(f"    PREDICT -> Chart {rule_pos}: {self._format_item(item)}")

    def _is_terminal(self, symbol):
        """判断是否为终结符"""
        return symbol in ['1', '2', '3', '+'] or symbol.isdigit()

    def _format_item(self, item):
        """格式化打印状态"""
        lhs, rhs, dot, start = item
        before_dot = ' '.join(rhs[:dot]) if dot > 0 else ''
        after_dot = ' '.join(rhs[dot:]) if dot < len(rhs) else ''
        dot_str = '•'
        if before_dot and after_dot:
            return f"{lhs} -> {before_dot} {dot_str} {after_dot}"
        elif before_dot:
            return f"{lhs} -> {before_dot} {dot_str}"
        else:
            return f"{lhs} -> {dot_str} {after_dot}"

# --- 定义文法 ---
grammar = [
    ("E", ["E", "+", "T"]),
    ("E", ["T"]),
    ("T", ["1"]),
    ("T", ["2"]), 
    ("T", ["3"])
]

# --- 测试 ---
parser = EarleyParser(grammar, "E")
# 成功案例
# parser.parse(["1", "+", "2"])
# 也可以试试更复杂的
parser.parse(["1", "+", "2", "+", "3"])