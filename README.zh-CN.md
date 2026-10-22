# Graft

**Racket 上的遗传编程——程序即 S 表达式，靠子树嫁接繁衍。**

[![CI](https://github.com/turinglambdaai/graft/actions/workflows/ci.yml/badge.svg)](https://github.com/turinglambdaai/graft/actions/workflows/ci.yml) ![Racket](https://img.shields.io/badge/Racket-9F1D20?logo=racket&logoColor=white) [![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

**[English](README.md) · 中文**

Graft 用遗传编程繁衍可执行的 Racket 形式。个体就是普通的 S 表达式：叶子是数字和变量符号，分支是函数调用。因为代码即数据，交叉和变异就是列表结构上的操作——不需要解释器树，也不需要虚拟机——求值就是一次递归遍历。

默认适应度做符号回归：给它一组「环境/目标」数据，它把公式进化出来。Graft 不是机器学习框架；它只是一个循环， knobs 诚实可见，树深由构造保证有界。

## 快速开始

```racket
(require graft)

(random-seed 2026)                      ; 可复现性由调用方决定

(define dataset
  (for/list ([x (in-list '(#i-5 #i-4 #i-3 #i-2 #i-1 #i0 #i1 #i2 #i3 #i4 #i5))])
    (cons (hash 'x x) (+ (* x x) x 1))))

(define result (evolve dataset #:generations 60 #:population-size 300))

(outcome-best-tree result)   ; 形如 (+ x (+ (* x x) 1)) 的树
(outcome-best-error result)  ; 数据集上的平均绝对误差
```

`examples/symbolic-regression.rkt` 是一个可运行的完整走查，CI 里离线执行。

## 设计要点

- **膨胀由构造封顶。** 超出深度上限的交叉后代回退为父本；变异新生的材料按剩余深度预算。任何一次运行都不可能繁衍出无界的树。
- **失败是适应度，不是崩溃。** 默认函数集含 `pdiv`——防零除的除法。搜索会不断路过除零，它应当付出适应度代价，而不是炸掉进程。
- **每个旋钮都是参数。** 函数注册表、变量、常数范围、深度上限、种群、锦标赛规模、比率、精英数——全部 `parameterize` 作用域化，没有需要手动复位的全局状态。
- **可复现性归调用方。** Graft 从不自行播种随机数；`evolve` 之前一句 `(random-seed n)` 即可让运行完全可复现。

## 开发

```sh
raco pkg install --auto --name graft .
raco test -p graft
raco setup --check-pkg-deps graft
racket examples/symbolic-regression.rkt
```

CI 在 Linux、Windows、macOS 三平台 × Racket 9.0 / 9.3 上跑测试，并做依赖声明检查、参考手册构建与种子化走查。

## 许可证

[Apache-2.0](LICENSE)
