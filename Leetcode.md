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

