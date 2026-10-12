// binary-trees: allocates ~300M short-lived nodes, keeps one long-lived tree.
class TreeNode {
  left: TreeNode | null;
  right: TreeNode | null;
  constructor(left: TreeNode | null, right: TreeNode | null) {
    this.left = left;
    this.right = right;
  }
}

function make(depth: number): TreeNode {
  if (depth === 0) return new TreeNode(null, null);
  return new TreeNode(make(depth - 1), make(depth - 1));
}

function check(node: TreeNode): number {
  const l = node.left;
  const r = node.right;
  if (l === null || r === null) return 1;
  return 1 + check(l) + check(r);
}

const minDepth = 4;
const maxDepth = 21;

console.log("stretch tree of depth " + (maxDepth + 1) + "\t check: " + check(make(maxDepth + 1)));
const longLived = make(maxDepth);
for (let d = minDepth; d <= maxDepth; d += 2) {
  const iterations = 1 << (maxDepth - d + minDepth);
  let sum = 0;
  for (let i = 0; i < iterations; i++) sum += check(make(d));
  console.log(iterations + "\t trees of depth " + d + "\t check: " + sum);
}
console.log("long lived tree of depth " + maxDepth + "\t check: " + check(longLived));
