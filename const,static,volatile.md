## 1. volatile防止编译器优化（外设寄存器/中断标志位）

编译器默认会优化代码，例如：

```
while（flag == 0）；
```

如果 flag 没有 volatile ，编译器可能认为：

**（volatile = “这个变量可能随时被别人改，别给我优化”）**

1. flag 永远不会改变（在当前函数内没看到谁写它）
2. 因此把它优化成死循环：

```
while（1）；
```

**这会让中断标志，外设寄存器，共享变量无法工作。**

如果使用volatile初始化：

**每次循环都会重新从内存读取 flag**。

假设有中断，在while 中等待中断修改flag的值。

volatile 主要用于：

- 中断修改的变量 （如 flag）
- 外设寄存器映射地址
- RTOS/多线程共享变量（不加锁情况下）
- memory-mapped I/O （外设地址）

### 2. const 放入Flash，保护数据不被修改

**常量数据（只读表，查找表，标定参数）应该放在Flash，而不是RAM。**

例如：

```c
const uint8_t table[256];
```

因为是const：

- 编译器可把它放进Flash（ROM区）
- 减少 RAM 占用 （嵌入式 RAM 很宝贵）
- 编译器更容易做优化 （常量折叠，常量传播）

但注意：

- const ！= 放入Flash 要看编译器和链接脚本，但是在嵌入式里通常如此。
- **不能用 extern 在外部文件直接引用**（必须声明为 `extern const int b;`）

**存储位置：**

- `const int b；`通常在Flash/ROM 的`.rodata` （只读段）。
- 不占 RAM （非常适合嵌入式）

### 3.static 生命周期与作用域控制 （编译器+链接期行为）

static 在嵌入式里有3个重要语义：

**（1）局部 static 变量：生命周期整个程序**

```
void func(){
	static int count = 0; //只初始化一次
	count++;
}
```

特性：

- **生命周期**与全局变量一样（程序整个运行期）
- 但**作用域**依然是局部的（函数外无法访问）

**（2）文件作用域 static：隐藏全局变量**

```c
static int sensor_value;
```

特性：

- 只能在当前.c文件使用
- 不会导出其他文件（不会被extern使用）

通常用于**模块封装**，例如驱动内部的状态机变量。

**（3）static 函数：仅本文件可见**

```
static void ADC_InitInternal();
```

避免函数被外部文件调用，减少**命名污染**，模块化更**清晰**。

**存储位置：**

- `static int a；`通常在.bss 或者 .data段 （根据是否初始化）。

### 4. 常见作用

volatile 常见作用：

```
volatile uint32_t *UART_DR = (uint32_t*)0x40004400; // 外设寄存器
volatile int ready;  // 中断修改的变量
```

static 常见作用：

```
static int state;       // 状态机变量
static void ADC_Driver(); // 内部函数，不暴露给外部
```

const 常见作用：

```
const uint8_t crc_table[256];  // 放在 flash，不占 RAM
```

