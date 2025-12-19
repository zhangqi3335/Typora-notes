## 1 #

### 1.1 （#）字符串化操作符

功能：将宏参数转换为**字符串**字面量

用法：#操作符会将紧随其后的参数转换为一个带双引号的字符串

```c
#include <stdio.h>
#define STR(x) #x
//重点在于%s
int main() {
    printf("%s\n",STR(Hello world!));
    printf("%s\n",STR(123));
    return 0;
}

[Running] cd "d:\C\" && gcc study.c -o study && "d:\C\"study
Hello world!
123
```

### 1.2 （##）符号连接操作符

功能：将两个标记（Token）拼接成一个标记。

用法：## 操作符会将它两边的宏参数或标记拼接在一起，形成新的标记，可用于批量创建格式统一的变量、函数。

注意：拼接后的标识符不能是c语言关键字，且仅在预处理时拼接

```c
#include <stdio.h>
#define CONCAT(x,y) x##y

int main() {
    int xy = 10;
    printf("%d\n",CONCAT(x,y));
    return 0;
}

[Running] cd "d:\C\" && gcc study.c -o study && "d:\C\"study
10
```

```c
// 宏定义：拼接前缀和数字生成变量名
#define VAR(num) var##num
// 宏定义：拼接前缀和功能生成函数名
#define FUNC(func) can_##func
 
int VAR(1) = 10; //预编译后VAR(1)替换为var1
```



## 2 volatile防止编译器优化（外设寄存器/中断标志位）

编译器默认会优化代码，例如：

**（volatile = “这个变量可能随时被别人改，别给我优化”）**

volatile 主要用于：

- 中断修改的变量 （如 flag）
- 外设寄存器映射地址
- RTOS/多线程共享变量（不加锁情况下）
- memory-mapped I/O （外设地址）

### 2.1 并行设备的硬件寄存器

存储器映的硬件寄存器通常要加`volatile`，因为寄存器随时可以被外部硬件修改。当声明指向设备寄存器的指针时一定要用`volatile`，它会告诉编译器不要对存储在这个地址的数据进行假设。

就比如我们常用的 MDK 中，你单纯给一个寄存器赋值，不加`volatile`会被优化掉，程序会跳过这个内容去编译别的部分。

```c
#define XYTE ((volatile unsigned char*)0x8000) // 假设硬件寄存器的基地址
void set_register(){
    XYTE[2] = 0x55; // 写入0x55
    XYTE[2] = 0x56; // 写入0x56
    XYTE[2] = 0x57; // 写入0x57
    XYTE[2] = 0x58; // 写入0x58
}
```

- 如果未声明`volatile`，编译器可能优化为直接写入最后的值 0x58。
- 声明了`volatile`后，编译器会逐条生成机器代码，确保硬件设备能够接收到完整的写入操作序列。

### 2.2 中断服务程序中修改的变量

`volatile`能提醒编译器，它后面所定义的变量随时都有可能改变。因此编译后的程序每次需要存储或读取这个变量的时候，都会直接从变量地址中读取数据。如果没有`volatile`关键字，则编译器可能优化读取和存储，可能暂时使用寄存器中的值。如果这个变量由别的程序更新了的话，将出现不一致的现象。

当中断服务程序（ISR）修改一个变量，主程序可能在等待该变量的改变。在这种情况下，使用`volatile`避免主程序读取优化后的缓存值，确保从内存中读取最新值。

```c
#include <stdbool.h>
volatile bool flag = false;//用于主程序和中断之间的通信

void ISR(){
    flag = true; //中断触发时修改变量
}

void main(){
    while (!flag)
    {
        //等待中断触发
    }
    //中断触发后执行其他操作
}
```

- 如果未声明`volatile`，主程序会把`flag`的值**缓存到 CPU 寄存器**，或直接优化成`while(1)`（死循环），不再从内存读取`flag`的最新值 —— 哪怕中断修改了内存中的`flag`，主程序也看不到。
- 使用`volatile`后，每次都会直接从内存读取flag 的值，确保中断修改可以被感知。 

### 2.3 多线程中共享的变量

在多线程环境中，不同线程可能会访问或修改同一个变量，volatile确保每个线程都能读取到变量的最新值，而不是被优化后的缓存值。

```
#include <windows.h>
#include <stdbool.h>

volatile bool stop = false;

// Windows 线程函数（必须符合 WINAPI 调用约定）
DWORD WINAPI thread_func(LPVOID arg) {
    while (!stop) {
        // 线程操作
    }
    return 0;
}

int main() {
    HANDLE thread;
    // 创建线程（Windows 原生 API）
    thread = CreateThread(NULL, 0, thread_func, NULL, 0, NULL);
    
    stop = true; // 通知线程停止
    WaitForSingleObject(thread, INFINITE); // 等待线程结束
    CloseHandle(thread); // 释放线程句柄
    return 0;
}
```



## 3 const 放入Flash，保护数据不被修改

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

## 4 static 生命周期与作用域控制 （编译器+链接期行为）

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

## 5 常见作用

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

