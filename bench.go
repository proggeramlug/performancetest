// binary-trees: allocates ~300M short-lived nodes, keeps one long-lived tree.
package main

import "fmt"

type TreeNode struct{ left, right *TreeNode }

func make_(depth int) *TreeNode {
	if depth == 0 {
		return &TreeNode{}
	}
	return &TreeNode{make_(depth - 1), make_(depth - 1)}
}

func check(n *TreeNode) int {
	if n.left == nil || n.right == nil {
		return 1
	}
	return 1 + check(n.left) + check(n.right)
}

func main() {
	minDepth, maxDepth := 4, 21
	fmt.Printf("stretch tree of depth %d\t check: %d\n", maxDepth+1, check(make_(maxDepth+1)))
	longLived := make_(maxDepth)
	for d := minDepth; d <= maxDepth; d += 2 {
		iterations := 1 << (maxDepth - d + minDepth)
		sum := 0
		for i := 0; i < iterations; i++ {
			sum += check(make_(d))
		}
		fmt.Printf("%d\t trees of depth %d\t check: %d\n", iterations, d, sum)
	}
	fmt.Printf("long lived tree of depth %d\t check: %d\n", maxDepth, check(longLived))
}
