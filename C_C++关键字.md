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

### 3.1 定义变量为常量

局部变量或全局变量，可以通过 const 来定义为常量，一旦赋值后，该常量的值就不能被修改。

```c
const int N = 100; // 定义常量N,值为100
// N = 50;      // 错误: 常量的值不能被修改
const int n; // 错误: 常量在定义时必须初始化
```

### 3.2 修饰函数的参数

使用 const 修饰函数参数，表示该参数在函数体内不能被修改。这样可以保证函数不会无意间修改传入的参数值，增加代码的可维护。

```c
void func(const int x) {
// x = 10; // 错误: x是常量,不能修改
}
```

### 3.3 修改函数的返回值

**返回指针类型并使用 const 修饰**

当函数返回指针时，若用 const 修饰返回值类型，那么返回的指针所指向的数据内容不能被修改，同时该指针也只能赋值给被 const 修饰的指针。

```c
const char* Getstring() {
    return "Hello";
}

const char* str = Getstring(); // 正确，str 被声明为 const
// char* str = Getstring();    // 错误，str 未声明为 const，不能修改返回值
```

**返回普通类型并使用 const 修饰**

如果 const 用于修饰普通类型的返回值，如 int，由于返回值是临时的副本，在函数调用结束后，返回值的生命周期也随之结束，此将其修饰为 const 是没有意义的。

```c
const int GetValue() {
    return 5;
}

int x = GetValue();        // 正确，返回值可以赋给普通变量
// const int y = GetValue(); // 不必要的，因为返回值会是临时变量，不会被修改
```

### 3.4 节省空间，避免不必要的内存分配

const 关键字还可以帮助优化内存管理。当你使用 const 来定义常量时，编译器会考虑将常量放入只读存储区，避免了额外的内存对于宏（#define）和 const 常量，它们在内存分配的方式上有所不同

```
#define PI 3.14159       // 使用宏定义常量 PI
const double pi = 3.14159; // 使用 const 定义常量 pi
```

使用宏定义的常量（如 PI）会在编译时进行文本替换，所有使用该宏的地方都会被替换为常量值，因此不会单独分配内存；而 const 则会在内存中分配空间，通常存储在只读数据区。

```
double i = PI；//编译器件进行宏替换，不会分配内存
double I = pi；//分配内存，存储常量 pi
```

宏定义常量的每次使用都会进行文本替换，因此会进行额外的内存分配。相反，const常量只会分配一次内存

```
#define PI 3.14159 //宏定义常量 PI
double j = PI； //这里会进行宏替换，不会再次分配内存
double I = PI； //宏替换后再次分配内存
```

### 3.5 什么情况使用Const

| 序号 | 使用场景         | 示例                                                         | 说明                                                         |
| ---- | ---------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 1    | 修饰一般常量     | `const int x = 2;  `        `  int const x = 2;`             | 定义只读的常量，const 位置灵活。                             |
| 2    | 修饰常数组       | `const int arr[8] = {1,2,3,4,5,6,7,8};`                                                                                     `int const arr[8] = {1,2,3,4,5,6,7,8};` | 定义的数组内容不可修改。                                     |
| 3    | 修饰常对象       | `const A obj; `                        `  A const obj;`      | 定义的类对象不可被修改，且需立即初始化。                     |
| 4    | 修饰指针相关     | `const int *p;（指向常量的指针，p的内容不可变，p指向的地址可变）`                                                                          `int* const p;（指针常量，p指向的地址是不可以变的，但是p指向的地址可以通过指针改变）`                                                                                                     `const int* const p;（指向常量的常量指针，p和内容都不可变)` | 不同组合修饰指针的行为。                                     |
| 5    | 修饰常引用       | `void func(const int &ref);`                                 | 常引用绑定到变量后不能更改其指向对象的值，可保护传入变量被函数修改。 |
| 6    | 修饰函数的常参数 | `void func(const int var);`                                  | 参数不可在函数体内被修改。                                   |
| 7    | 修饰函数的返回值 | `const int func();（返回的值不可修改）  `                                      `const A func();（返回的对象不可修改）` | 表明返回值不可被外部代码修改。                               |
| 8    | 跨文件使用常量   | `extern const int i;`                                        | 在其他文件中使用 const 修饰的全局变量。                      |

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

**（1）在函数体内定义静态变量**，在函数体，指挥初始化一次，且在函数调用结束后其值不会丢失，而是保持到下次 函数调用。

```c
#include<stdio.h>

void FunC(){
    static int count = 0;//只初始化一次
    count++;
    printf("%d\n",count);
}

int main() {
    FunC();
    FunC();
    FunC();
    return 0;
}

[Running] cd "d:\C\" && gcc study.c -o study && "d:\C\"study
1
2
3
```

- `static`保证变量只初始化一次，即使函数被多次调用。
- 变量在函数作用域内可见，但其值会在多次调用中保持

**（2）在模块内定义静态变量**

```c
#include<stdio.h>//File1.c
static int count = 10;

void FunC(){
    printf("%d\n",count);
}

#include<stdio.h>//File2.c
extern int count;

int main() {
      printf("%d\n",count);
    return 0;
}
//执行编译链接命令
PS D:\C> gcc -c study.c -o study.o     
PS D:\C> gcc -c .\study1.c -o study1.o 
PS D:\C> gcc study.o study1.o -o study1                                     
study1.o:study1.c:(.rdata$.refptr.count[.refptr.count]+0x0): undefined reference to `count'                                                                                
collect2.exe: error: ld returned 1 exit status
//如果没有static，则可以正常输出10
```

- 只能在当前.c文件使用。
- 不会导出其他文件（不会被extern使用）。
- 避免命名冲突，特别是在大型项目中。

通常用于**模块封装**，例如驱动内部的状态机变量。

**（3）在模块内定义静态函数**

当函数使用 static 关键字修饰时，其作用域被限制在当前文件，不能被其他文件调用。这种函数被称为静态函数。

在模块内，一个被声明为静态的函数只可被这一模块内的其它函数调用。那就是，这个函数被限制在声明它的模块的本地范围内使用 (只能被当前文件使用)

```c
#include<stdio.h>//File1
static int count = 10;

static void FunC(){
    printf("Func");
}

void CALL_Func(){
    FunC();
}

#include<stdio.h>//File2
extern void CALL_Func();

int main() {
    CALL_Func();
    return 0;
}
//当void CALL_Func()
PS D:\C> gcc -c study.c -o study.o     
PS D:\C> gcc -c .\study1.c -o study1.o 
PS D:\C> gcc study.o study1.o -o study1
PS D:\C> ./study1                      
Func
//当staic void CALL_Func()
study1.o:study1.c:(.text+0xe): undefined reference to `CALL_Func'
collect2.exe: error: ld returned 1 exit status
```

- 限制函数作用域，仅在当前文件中可见。
- 适合用于实现模块内部的辅助功能，避免函数命名冲突。

## 5 extern “C”的作用是什么

`extern "C"`的主要作用就是为了能够正确实现 C++ 代码调用其他 C 语言代码。加上`extern "C"`后，会指示编译器这部分代码按 C 语言的进行编译，而不是 C++ 的。

`extern "C"`的主要作用是实现 C++ 和 C 之间的兼容性：

- C++ 和 C 在函数符号（名称）处理上有本质区别。
- C++ 支持函数重载，因此采用了名称修饰（Name Mangling）技术，使同名函数可以根据参数的类型和数量生成唯一的符号。
- C 不支持函数重载，函数名称在编译后直接对应符号表中的函数名。
- 如果 C++ 代码直接调用 C 的函数（或者反之），名称修饰会导致链接器无法找到正确的符号。
- `extern "C"`告诉编译器关闭 C++ 的名称修饰，按照 C 的方式处理符号表。

```c
//C++ 文件
#include"example.h"

extern "c"{
    #include"example.h"
}

int main(){
    print_message("Hello fron C++");
    return 0;
}
//在同一个文件夹下，创建example.h
#ifdef __cplusplus
extern "C" {
#endif
    void print_message(const char *msg);//function_in_c
    
#ifdef __cplusplus
}
#endif
//在同一文件夹下创建example.c
#include "example.h"
#include <stdio.h>  // 用于printf输出

// 实现print_message函数，与头文件声明完全一致
void print_message(const char *msg) {
    printf("%s\n", msg);  // 输出传入的字符串
}
```

- 仅限在 C++ 环境中使用:・C 编译器不支持 extern "C" 关键字，因此在混合编译时需要通过去区分语言环境（__cplusplus 宏用于判断是否是 C++ 编译器）。

- 仅影响链接（Linking）阶段:・extern "C" 并不改变代码的编译方式，只是改变符号表的生成方式。

## 6 new/delete 与 malloc/free 的区别是什么？

new、delete 是 C++ 中的操作符，而 malloc 和 free 是标准库函数。

### 6.1 类型安全性

**new 和 delete：**

- new 是 C++ 的运算符，delete 也是运算符，具有类型安全性。new 会返回正确类型的指针，无需强制转换。使用时，编译器会自动计算所需内存的大小。
- delete 会释放通过 new 分配的内存，并自动调用对象的析构函数。

```cpp
int *p = new int;    // 分配内存并返回指向 int 类型的指针
delete p;            // 释放内存并调用析构函数
```

**malloc 和 free：**

- malloc 和 free 是 C 标准库函数，malloc 返回的是 void * 指针，必须显式转换为实际的类型指针。它没有类型安全性，容易导致错误。
- malloc 只是为内存分配空间，并不调用构造函数，而 free 只是释放内存，并不调用析构函数。

```c
int *p = (int*)malloc(sizeof(int)); //需要手动转换类型
free(p);                            //只释放内存
```

### 6.2 构造函数与析构函数

**new 和 delete：**

- 当使用 new 分配内存时，会自动调用类的构造函数来初始化对象。
- 当使用 delete 释放内存时，会自动调用类的析构函数。

```cpp
class MyClass {
public:
    MyClass() { cout << "constructor called" << endl; }
    ~MyClass() { cout << "destructor called" << endl; }
};

MyClass* obj = new MyClass;  // 自动调用构造函数
delete obj;                  // 自动调用析构函数
```

**malloc 和 free：**

- malloc 不会调用构造函数，仅分配内存；free 不会调用析构函数，仅释放内存。

```c
MyClass* obj = (MyClass*)malloc(sizeof(MyClass));  // 不会调用构造函数
free(obj);                                         // 不会调用析构函数
```

### 6.3 内存管理

**new 和 delete：**

- new 在分配内存时会计算所需内存的大小，并根据类型自动计算。delete 自动处理内存释放及相关清理工作

**malloc 和 free：**

- malloc 需要明确指定需要分配的字节数，不会考虑对象的类型。free 只能释放 malloc 或 calloc 分配的内存，并且不能自动调用析构函数。

```c
int *p = (int*)malloc(10 * sizeof(int));  // 需要手动计算内存大小
```

### 6.4 对象的内存对齐和初始化

**new 和 delete：**

- new 会调用类的构造函数进行初始化，并且会适当地进行内存对齐。
- delete 会释放内存并自动调用析构函数。

```cpp
int* p = new int(5);  // 自动初始化
delete p;             // 自动释放并调用析构函数
```

**malloc 和 free：**

- malloc 只分配原始内存，不会初始化对象。如果需要初始化对象，必须手动进行。
- free 只会释放内存，而不会调用析构函数。

### 6.5 特性对比表

| 特性                | new/delete                  | malloc/free               |
| ------------------- | --------------------------- | ------------------------- |
| 语言                | C++                         | C                         |
| 类型安全            | 类型安全，自动推导和转换    | 需要手动类型转换          |
| 构造函数 / 析构函数 | 自动调用构造函数 / 析构函数 | 不调用构造函数 / 析构函数 |
| 内存分配            | 自动计算内存大小            | 需要手动指定内存大小      |
| 内存初始化          | 支持初始化                  | 不会初始化内存            |
| 使用方式            | 运算符，使用 new 和 delete  | 函数，使用 malloc 和 free |

## 7 sizeof 和 strlen

### 7.1 `strlen("\0")=? sizeof("\0")=?`

`strlen("\0")=0，sizeof("\0")=2`。

`strlen()` 用来计算**字符串的长度**（在 C/C++ 中，字符串是以`\0`作为结束符的），它从内存的某个位置开始扫描直到碰到第一个字符串结束符`\0`为止，然后返回计数数值。因为`"\0"`本身就是空字符`\0`，所以`strlen("\0")`的结果是 0

```c
strlen("\0"); // 结果是 0，因为字符串仅包含一个 '\0' 终止符
```

`sizeof()` 计算的是**操作数的存储大小**（通常以字节为单位）。在 C 中，字符串字面量`"str"`的实际类型会包含一个额外的空字符`\0`作为结束符。因此，字符串`"\0"`实际上是一个包含两个字符的字符数组（原`\0` + 结束符`\0`），所以`sizeof("\0")`结果是 2。

### 7.2 `sizeof`和`strlen`有什么区别？

`strlen`与`sizeof`的差别表现在以下 5 个方面：

1. `sizeof`是**运算符（既是关键字，也是运算符，但不是函数）**，而`strlen`是**函数**。`sizeof`后跟类型名时要加括号，如果是变量名，则可以不加括号。
2. `sizeof`运算符的结果类型是`size_t`，它在头文件中被`typedef`为`unsigned int`类型。该类型保证能够容纳实现所建立的最大对象的字节数。
3. `sizeof`可以用类型作为参数，`strlen`只能用`char*（字符指针）`作参数，而且必须是以`\0`结尾的。`sizeof`还可以以函数作为参数，如`int g()`，则`sizeof(g())`的值等于`sizeof(int)`的值，在 32 位计算机下，该值为 4。
4. 大部分编译程序的`sizeof`都是在编译的时候计算的，所以可以通过`sizeof(x)`来定义数组维数。而`strlen`则是在运行期计算的，用来计算字符串的实际长度，不是类型占内存的大小。例如，`char str[20]="0123456789"`，
   字符数组`str`是**编译期**大小已经固定的数组，在 32 位机器下`sizeof(char)*20=20`，
   而其`strlen`大小是在**运行期**确定的，所以其值为字符串的实际长度 **10**。当数组作为参数传给函数时，传递的是指针而不是数组，即传递的是数组的首地址。

### 7.3 不使用sizeof，如何求int占用的字节数？

```c
#include<stdio.h>
#define Mysizeof(value) ((char *)(&value + 1) - (char *)(&value))

int main(){
    int n1;
    printf("int的大小:%d\n",Mysizeof(n1));

    float f;
    printf("float的大小:%d\n",Mysizeof(f));

    char c;
    printf("char的大小:%d\n",Mysizeof(c));
    return 0;
}

[Running] cd "d:\C\" && gcc study.c -o study && "d:\C\"study
int的大小:4
float的大小:4
char的大小:1
```

**核心原理说明**

1. **`&value`**：获取变量`value`的内存起始地址。
2. **`&value + 1`**：指针算术运算，这里的`+1`不是偏移 1 个字节，而是偏移`value`整个类型的大小（比如`int`变量，就偏移`int`的字节数），得到`value`内存末尾的下一个地址。
3. **`(char \*)`强制转换**：将两个地址都转换为`char*`类型（`char`类型固定占用 1 字节），此时两个地址相减的结果，就是两个地址之间的字节数，也就是`value`类型的大小。
4. **地址相减**：`(char *)(&value + 1) - (char *)&value` 最终得到的就是`int`（或其他传入类型）占用的字节数。

## 8 C语言中 struct 和 union的区别是什么？

| 比较项目 | struct（结构体）                                             | union（联合体）                                              |
| -------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 内存分配 | 每个成员有独立的存储空间，大小是所有成员大小的累加值（考虑字节对齐）。 | 所有成员共用同一块内存，大小等于最大成员的大小（考虑字节对齐）。 |
| 成员访问 | 所有成员可以独立访问且互不影响。                             | 同一时刻只能访问一个成员，写入一个成员会覆盖其他成员的值。   |
| 用途     | 用于保存多个相关但独立的数据。                               | 用于在同一存储区域保存多个数据（节省内存）。                 |
| 字节对齐 | 根据成员类型和字节对齐规则进行分配。                         | 最大成员决定内存分配，并根据字节对齐规则调整大小。           |
| 适用场景 | 常用于多种类型数据的组合使用。                               | 常用于需要节省内存或多种数据类型共用时。                     |

```c
#include<stdio.h>
//
typedef union 
{
    double i;   // 8 bytes
    int k[5];   // 5 x 4 bytes = 20 bytes
    char c;     // 1 byte
} DATE; 
//
typedef struct data{
    int cat;    // 4 bytes
    DATE cow;   // 24 bytes (union,8-byte alignment)
    double dog; // 8 bytes
} too;   

DATE max;
int main(){
    printf("union struct两者占用的大小:%d  %d\n",sizeof(max),sizeof(too));
    return 0;
}

[Running] cd "d:\C\" && gcc study.c -o study && "d:\C\"study
union struct两者占用的大小:24  40
```

### 8.1 联合体 `DATE` 大小计算（`sizeof(DATE) = 24`）

联合体的核心特性是**所有成员共用一块内存，大小取最大成员大小 + 字节对齐补偿**：

- 三个成员大小分别为：`double i`(8 字节)、`int k[5]`(20 字节)、`char c`(1 字节)，最大成员大小为 20 字节；
- 字节对齐规则：联合体的对齐模数与它的最大基本数据类型成员一致，这里`double`是 8 字节，因此联合体需要按 8 字节对齐；
- 20 字节无法被 8 字节整除，向上取最近的 8 的倍数（24 字节），因此`sizeof(DATE) = 24`。

### 8.2 结构体 `too` 大小计算（`sizeof(too) = 40`）

结构体的核心特性是**成员按声明顺序依次排布，每个成员按自身类型对齐，整体大小按最大成员对齐模数对齐**：我们分步拆解（按 8 字节对齐规则，结构体`too`的最大对齐模数是`double`对应的 8 字节）：

1. `int cat`：占 4 字节，起始地址 0~3（满足 4 字节对齐）；
2. 字节填充：为了让后续`DATE cow`满足 8 字节对齐，在`cat`后填充 4 字节（地址 4~7）；
3. `DATE cow`：占 24 字节，起始地址 8~31（满足 8 字节对齐，正好对应联合体的 24 字节大小）；
4. `double dog`：占 8 字节，起始地址 32~39（满足 8 字节对齐）；
5. 整体大小：4（cat）+4（填充）+24（cow）+8（dog）= 40 字节，40 是 8 的倍数，无需额外填充，因此`sizeof(too) = 40`。

## 9 左值和右值是什么？

左值是指可以出现在等号左边的变量或表达式，它最重要的特点就是可写（可寻址）。也就是说，它的值可以被修改，如果表达式的值不能被修改，那么它就不能作为左值。

```c
int a = 10; // a 是左值
a = 20;     // a 出现在赋值号的左边，可修改其值
```

右值是指只可以出现在等号右边的变量或表达式。它最重要的特点是可读。一般的使用场景都是把一个右值赋值给一个左值。

```c
int b = a + 5; // (a + 5) 是右值，提供计算结果但无法修改
```

通常，左值可以作为右值，但是右值不一定是左值。

### 9.1 左值（L-value）与右值（R-value）对比表

| 类别       | 左值（L-value）                              | 右值（R-value）                                      |
| ---------- | -------------------------------------------- | ---------------------------------------------------- |
| 定义       | 表示内存中的一个地址，可出现在赋值运算符左侧 | 表示一个值，不占据内存地址，只能出现在赋值运算符右侧 |
| 特点       | 可寻址、可修改                               | 不可寻址、只提供值，不能被修改                       |
| 作用       | 提供一个持久的存储位置，可读写               | 提供数据，通常用于计算或赋值                         |
| 示例       | 变量：`int a; a = 5;`                        | 常量或表达式：`5; a + 3;`                            |
| 内存分配   | 与具体内存地址绑定                           | 通常是临时值，不绑定内存地址                         |
| 使用场景   | - 出现在赋值号左侧- 可作为右值               | - 出现在赋值号右侧- 参与计算                         |
| 互相关系   | 左值可以用作右值                             | 右值不能用作左值                                     |
| 函数返回值 | 函数返回引用或指针是左值                     | 函数返回具体值                                       |

## 10 `++a`和`a++`有什么区别？两者是如何实现的？

- **`++a`（前置自增）**：先对变量自增 1，再返回变量的值。
- **`a++`（后置自增）**：先返回变量的值，再对变量自增 1。

### 10.1 `a++`的实现过程

```c
int a = 5;
int temp = a;  // 保存当前值到临时变量 temp
a = a + 1;     // 自增
return temp;   // 返回保存的临时变量 temp
```

### 10.2 `++a`的实现过程

```c
int a = 5;
a = a + 1;     // 自增
return a;      // 返回自增后的值
```
