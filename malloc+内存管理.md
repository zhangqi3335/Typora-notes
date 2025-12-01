# 目标：

1. 理解堆和栈区别 （与任务栈有关）
2. 知道为什么嵌入式慎用malloc （Freertos 也内部使用）
3. FreeRtos的内存管理
4. 掌握正确写法+常见错误（特别是局部指针）

## 1. 堆(Heap) vs 栈(Stack)

| **特性** | **栈**                                     | **堆**                                                  |
| -------- | ------------------------------------------ | ------------------------------------------------------- |
| 分配方式 | 编译器自动分布（函数进入→创建，退出→销毁） | malloc手动分布（malloc/free 或 pvPortMalloc/vPortFree） |
| 生命周期 | 离开函数自动销毁                           | 直到free                                                |
| 分配速度 | 快                                         | 慢                                                      |
| 容量     | 小（几KB~几十KB）                          | 较大（几KB~几百KB）                                     |
| 常见问题 | 栈溢出                                     | 内存碎片，泄漏                                          |

在FreeRTOS中：

栈：

每个FreeRTOS任务都有自己的独立栈空间（例如在cubeMX设置stack size）。

特点：

- 自动分配/自动回收
- 空间小（通常128~1024字）
- 适合局部变量，临时数组
- **任务栈溢出就是 HardFault** ，必须注意。

堆：

FreeRTOS 所有动态内存来自 **pvPortMalloc()**，而不是标准malloc。

用于：

- 动态创建任务
- 动态创建队列
- 动态创建信号量

```
任务（Task）
│
├─ 任务的栈（stack） ← CubeMX 设置的 stack size
│     ├─ 局部变量（int x, float buf[10]）
│     ├─ 函数参数
│     └─ 函数返回地址
│
└─ 任务的堆使用（heap） ← pvPortMalloc()
      ├─ malloc 出来的内存
      ├─ 动态创建队列
      └─ 动态创建信号量
//任务代码里的局部变量放在任务栈
//用 malloc/pvPortMalloc（）申请的变量放堆
//两者没有必然关系，和是否在任务里面无关。
```

## 2. 嵌入式为什么避免 malloc？

- 可能导致不可控的 **内存碎片**

- 运行时间不可预测（实时性差）

- 在 ISR中无法使用

  - （ISR  = Interrupt Service Routine 中断服务程序“当硬件时间发生时CPU跳进来执行的函数”）
  - 在ISR中必须“短，快，不能阻塞”
  - 禁止：
    1. malloc/pvPortMalloc
    2. free
    3. printf
    4. while（1）等待
    5. vTaskDelay
    6. 阻塞API
  - 因为ISR会阻塞所有任务，如果在ISR里卡住：
    1. 整个系统停摆
    2. 按键不相应
    3. FreeRTOS 任务调度停止
    4. 看门狗复位

  **单片机动作变慢的 90% 原因来自 ISR**：

  | 根因                 | 影响                |
  | -------------------- | ------------------- |
  | ISR 太长             | 卡死任务，整机变慢  |
  | ISR 使用阻塞 HAL API | 延迟变大，上百毫秒  |
  | ISR 优先级太高       | FreeRTOS 任务不运行 |
  | ISR 太频繁           | CPU 时间被中断吃光  |
  | ISR 禁用中断太久     | 系统悬停            |
  | ISR 里计算复杂       | 导致时序严重拖延    |

  

- 长时间使用后系统可能崩溃（指的是使用 **heap_2 / malloc / free** 时，随着时间推移系统越来越碎，最终死机。）
  - 假如一直malloc然后free
  - 堆 会变成：“小洞 + 大洞 + 不连续的可用空间”
  - 最终出现没有连续可用空间，系统逐渐无法工作，最终崩溃/卡死/HardFault

- FreeRTOS 自身有更安全的内存策略。

## 3. FreeRTOS 的内存管理 （heap_1`heap_5）

| 方式       | 特点                                 |
| ---------- | ------------------------------------ |
| **heap_1** | 只能申请不能释放（简单、无碎片）     |
| **heap_2** | 有释放，但碎片严重                   |
| **heap_3** | 直接封装系统 malloc/free（最不建议） |
| **heap_4** | 最推荐，带最佳合并策略，碎片少       |
| **heap_5** | 支持多区域堆                         |

## 4. malloc使用

```
#include <stdio.h>
#include <stdlib.h>

/*
    用malloc创建二维数组
*/
int main() {
    int cols = 4,rols = 3;

    int **arr = malloc(rols * sizeof(int *));
    if(arr == NULL){
        return -1;
    }
    for (int i = 0; i < rols; i++)
    {
        arr[i] = malloc(cols * sizeof(int)) ;
        if(arr[i] == NULL)
        {
            return -2;
        }
    }
    
    for (int i = 0; i < rols; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            arr[i][j] = i *10 + j;
            printf("%d\n",arr[i][j]);
        }
    }

    for (int i = 0; i < rols; i++)
    {
        free(arr[i]);  //释放每一层，防止数据泄露
    }
    free(arr);         //释放这一层，防止整个指针表泄露
    
    
    return 0;
}
```

输出：

```
0
1
2
3
10
11
12
13
20
21
22
23
```

总共有一个二维数组，二维数组包含了三个一维数组，每个意味数组里面有四个int大小的空间，每个int为4字节（32位）————》和指针笔记相似。

- 使用malloc创建二维数组确实比使用静态数组（编译时确定大小的数组）更复杂，但是有很多优点和必要性。
- 动态内存分配： malloc允许在运行时根据需要分配内存。这对于数组的大小在编译时未知或需要用户输入来确定的情况非常有用。
- 大小可变：使用malloc创建的数组可以根据程序的运行时需求调整大小。虽然malloc本身不提供直接的数组大小调整功能，但您可以使用realloc来调整已分配内存的大小。
- 避免栈溢出：静态数组的大小是固定的，如果数组非常大，可能会导致栈溢出。mallco分配到内存位于堆上，可以避免这个问题。
- 内存管理：动态分配内存使得您可以更精细地控制内存的使用和释放。例如，您可以在不再需要某个数组时使用free来释放内存，避免内存泄漏。

常见错误：返回**局部变量地址（野指针）**

```
#include <stdio.h>

int *func(void){
    int x = 0;
    return &x;
}

int main() {
    
    int *p = func();
    return 0;
}
```

输出：

```
study.c: In function 'func':
study.c:7:12: warning: function returns address of local variable [-Wreturn-local-addr]
     return &x;
            ^~
```

错误的原因：

- `x` 是局部变量，存在 **栈** 中
- 函数结束后栈帧销毁
- 返回的地址指向无效区域，称为 **悬空指针 / 野指针**
- 程序随机崩溃（HardFault）

正确方式：把变量放到堆上：

```
int* CorrectFunc(void)
{
    int *p = malloc(sizeof(int));
    *p = 123;
    return p;   // ✔ 安全
}
```

