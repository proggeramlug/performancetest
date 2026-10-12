// binary-trees: allocates ~300M short-lived nodes, keeps one long-lived tree.
// Runs on the JVM with its default GC (G1) and no tuning flags.
class TreeNode(val left: TreeNode?, val right: TreeNode?)

fun make(depth: Int): TreeNode =
    if (depth == 0) TreeNode(null, null)
    else TreeNode(make(depth - 1), make(depth - 1))

fun check(node: TreeNode): Int {
    val l = node.left
    val r = node.right
    if (l == null || r == null) return 1
    return 1 + check(l) + check(r)
}

fun main() {
    val minDepth = 4
    val maxDepth = 21
    println("stretch tree of depth ${maxDepth + 1}\t check: ${check(make(maxDepth + 1))}")
    val longLived = make(maxDepth)
    for (d in minDepth..maxDepth step 2) {
        val iterations = 1 shl (maxDepth - d + minDepth)
        var sum = 0L
        repeat(iterations) { sum += check(make(d)) }
        println("$iterations\t trees of depth $d\t check: $sum")
    }
    println("long lived tree of depth $maxDepth\t check: ${check(longLived)}")
}
