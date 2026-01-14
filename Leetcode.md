# 链表

### 反转链表

[反转链表](https://leetcode.cn/problems/reverse-linked-list/)：给你单链表的头节点 `head` ，请你反转链表，并返回反转后的链表。

题解一：

- 定义两个指针： prev 和 cur ；prev 在前 cur 在后。

- 每次让 cur 的 next 指向 prev ，实现一次局部反转

- 局部反转完成之后，prev 和 cur 同时往前移动一个位置

- 循环上述过程，直至 prev 到达链表尾部,cur此时为NULL

```c
/**
 * Definition for singly-linked list.
 * struct ListNode {
 *     int val;
 *     struct ListNode *next;
 * };
 */
struct ListNode* reverseList(struct ListNode* head) {
    struct ListNode *prev = NULL;
    struct ListNode *current = head;
    struct ListNode *nexttemp = NULL;
    while(current != NULL){
        nexttemp = current->next;
        current->next = prev;
        prev = current;
        current = nexttemp;
    }
    return prev;
}
```

题解二：

1. **“递” (Going Deep)**：每次调用 reverseList，就往上叠一个盘子。程序暂停当前盘子的工作，去处理新盘子。
2. **“归” (Coming Back)**：当最上面的盘子处理完（触发 return），把盘子拿走，**露出底下那个盘子**。底下的盘子**继续从刚才暂停的地方往下执行**。

递是一直执行struct ListNode *ret = reverseList(head->next);，直到满足条件；

归是回退的时候ret的值不变，从最后节点往前面节点执行head->next->next = head;head->next = NULL;  return ret;更改顺序。

```c
struct ListNode* reverseList(struct ListNode* head) {
    if(head == NULL || head->next == NULL){
        return head;
    }
    struct ListNode *ret = reverseList(head->next);
    head->next->next = head;
    head->next = NULL;
    return ret;
}
```

### 环状链表

[环状链表](https://leetcode.cn/problems/linked-list-cycle/?envType=study-plan-v2&envId=top-interview-150)：给你一个链表的头节点 `head` ，判断链表中是否有环。

题解一：快慢指针

情况 A：链表没有环（直路）

兔子跑得快，它会一路领先，直到它看到终点（NULL）。

- **结论**：只要兔子（快指针）或者兔子下一步的落脚点变成了 NULL，说明链表没有环，比赛结束。

情况 B：链表有环（死循环）

兔子冲进环形跑道后，因为没有终点，它会一直在里面转圈。
过一会儿，乌龟也慢吞吞地进了环形跑道。

此时，两人都在圈里跑：

- 兔子速度是乌龟的 2 倍。
- 这就好比在操场上套圈。**跑得快的人，一定会在未来的某一刻，从后面追上跑得慢的人。**
- **相遇时刻**：当兔子再次看到乌龟（指针地址相同）时，就能证明——**这绝对是一条环形跑道！**

```c
bool hasCycle(struct ListNode *head) {
    struct ListNode *slow = head;
    struct ListNode *fast = head;
    while(fast->next != NULL && fast->next->next != NULL){
        slow = slow->next;
        fast = fast->next->next;
        if(fast == slow){
            return true;
        }
    }
    return false;
}
```

### 两数相加

[两数相加](https://leetcode.cn/problems/add-two-numbers/description/?envType=study-plan-v2&envId=top-interview-150)：给你两个 **非空** 的链表，表示两个非负的整数。它们每位数字都是按照 **逆序** 的方式存储的，并且每个节点只能存储 **一位** 数字。

请你将两个数相加，并以相同形式返回一个表示和的链表。

题解一：直接加然后覆盖原本内容，先两个相加然后都覆盖，再在长链路上继续执行，如果最后有新的节点增加需要增加，最后输出覆盖后的头节点

```c

struct ListNode* addTwoNumbers(struct ListNode* l1, struct ListNode* l2) {
    int flag = 0;
    int add = 0;
    struct ListNode *temp1 = l1;
    struct ListNode *temp2 = l2;

    while(l1 != NULL && l2 != NULL){
        int num = l1->val + l2->val + add;
        if(num >= 10){
            l1->val = num-10;
            l2->val = num-10;
            add = 1;
        }
        else{
            l1->val = num;
            l2->val = num;
            add = 0;
        }
        l1 = l1->next;
        l2 = l2->next;
    }

    while(l1 != NULL){
        int num = l1->val + add;
        if(num >= 10){
            l1->val = num-10;
            add = 1;
        }
        else{
            l1->val = num;
            add = 0;
        }
        l1 = l1->next;
        flag = 1;
    }
    
    while(l2 != NULL){
        int num = l2->val + add;
        if(num >= 10){
            l2->val = num-10;
            add = 1;
        }
        else{
            l2->val = num;
            add = 0;
        }
        l2 = l2->next;
        flag = 2;
    }

    if(add == 1){
        struct ListNode *new = malloc(sizeof(struct ListNode));
        if(new == NULL){return NULL;}
        new->val = 1;
        new->next = NULL;
        struct ListNode *last = NULL;
        if(flag == 1 || flag == 0) {last = temp1;}
        else{last = temp2;}
        if(last == NULL){return new;}
        while(last->next!=NULL){
            last = last->next;
        }
        last->next = new;
    }

    if(flag == 1 || flag == 0){
        return temp1;
    }
    if(flag == 2){
        return temp2;
    }
    return temp1;
}
```

这个算法：

1. **原地修改 (In-place)**：虽然省内存，不得不维护 flag 来判断返回 temp1 还是 temp2。
2. **分段处理**：写了 3 个 while 循环（公有部分、l1剩余、l2剩余），代码冗余严重。
3. **尾部处理昂贵**：最后为了处理进位 add=1，又重新遍历了一遍链表找尾巴O(N)的时间浪费。

题解二：用了虚拟头节点加单次遍历

1. **申请新链表**：不要修改输入数据（除非内存极度受限）。
2. **虚拟头节点 (Dummy Head)**：省去判断“这是不是第一个节点”的麻烦。
3. **三合一循环**：将 l1、l2 和 carry (进位) 放在一个循环里处理。
4. 把虚拟头节点设为栈变量，用完自动回收，但是要用“.”。

```c
struct ListNode* addTwoNumbers(struct ListNode* l1, struct ListNode* l2) {
    int carry = 0;
    int sum = 0;
    struct ListNode dummy;
    dummy.val = 0;
    dummy.next = NULL;
    struct ListNode *tail = &dummy;
    while(l1 != NULL || l2 != NULL || carry>0){
        sum  = carry;
        if(l1 != NULL){
            sum += l1->val;
            l1 = l1->next;
        }
        if(l2 != NULL){
            sum += l2->val;
            l2 = l2->next;
        }
        carry = sum / 10;
        int digit = sum % 10;
        struct ListNode *newNode = (struct ListNode*)malloc(sizeof(struct ListNode));
        newNode->val = digit;
        newNode->next = NULL;
        tail->next = newNode;
        tail = newNode;
    }
    return dummy.next;
}
```

### 合并两个有序链表

[合并两个有序链表](https://leetcode.cn/problems/merge-two-sorted-lists/)：将两个升序链表**合并**为一个新的 **升序** 链表并返回。新链表是通过拼接给定的两个链表的所有节点组成的。

题解一：拉链法

1. **循环条件**：只要 list1 和 list2 **都有值**的时候，才进行比较 PK。
2. **PK 过程**：谁小，就让 tail->next 指向谁，然后谁就往后移一步。
3. **收尾**：如果循环结束，说明有一个链表空了。把另一个链表**剩下的所有节点**直接挂到尾部即可（不需要遍历了，因为剩下的本来就是有序的）。

```c
struct ListNode* mergeTwoLists(struct ListNode* list1, struct ListNode* list2) {
    struct ListNode Dummy;
    Dummy.val = 0;
    Dummy.next = NULL;
    struct ListNode *tail = &Dummy;
    if(list1 == NULL && list2 == NULL)
    {return NULL;}
    while(list1 != NULL && list2 !=NULL){
        if(list1->val <= list2->val){
            tail->next = list1;
            tail = list1;
            list1 = list1->next;
        }
        else{
            tail->next = list2;
            tail = list2;
            list2 = list2->next;
        }
    }
    if(list1 != NULL){
        tail->next = list1;
    }
    if(list2 != NULL){
        tail->next = list2;
    }
    return Dummy.next;
}
```

