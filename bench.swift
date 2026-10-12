// binary-trees: allocates ~300M short-lived nodes, keeps one long-lived tree.
// No GC: ARC frees each node when its last reference goes away (reference counting).
final class TreeNode {
    let left: TreeNode?
    let right: TreeNode?
    init(_ left: TreeNode?, _ right: TreeNode?) {
        self.left = left
        self.right = right
    }
}

func make(_ depth: Int) -> TreeNode {
    if depth == 0 { return TreeNode(nil, nil) }
    return TreeNode(make(depth - 1), make(depth - 1))
}

func check(_ node: TreeNode) -> Int {
    guard let l = node.left, let r = node.right else { return 1 }
    return 1 + check(l) + check(r)
}

let minDepth = 4
let maxDepth = 21

print("stretch tree of depth \(maxDepth + 1)\t check: \(check(make(maxDepth + 1)))")
let longLived = make(maxDepth)
var d = minDepth
while d <= maxDepth {
    let iterations = 1 << (maxDepth - d + minDepth)
    var sum = 0
    for _ in 0..<iterations { sum += check(make(d)) }
    print("\(iterations)\t trees of depth \(d)\t check: \(sum)")
    d += 2
}
print("long lived tree of depth \(maxDepth)\t check: \(check(longLived))")
