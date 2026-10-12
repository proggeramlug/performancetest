// binary-trees with an arena: nodes are indices into two Int32Arrays (struct-of-arrays).
// No per-node objects, so the GC never sees the nodes; reset() reuses the memory.
class Arena {
  left: Int32Array;
  right: Int32Array;
  size: number = 0;
  constructor(capacity: number) {
    this.left = new Int32Array(capacity);
    this.right = new Int32Array(capacity);
  }
}

function make(a: Arena, depth: number): number {
  let l = -1;
  let r = -1;
  if (depth > 0) {
    l = make(a, depth - 1);
    r = make(a, depth - 1);
  }
  const i = a.size++;
  a.left[i] = l;
  a.right[i] = r;
  return i;
}

function check(a: Arena, i: number): number {
  const l = a.left[i];
  if (l < 0) return 1;
  return 1 + check(a, l) + check(a, a.right[i]);
}

const minDepth = 4;
const maxDepth = 21;
const scratch = new Arena(1 << (maxDepth + 2));
const stretch = make(scratch, maxDepth + 1);
console.log("stretch tree of depth " + (maxDepth + 1) + "\t check: " + check(scratch, stretch));
const longArena = new Arena(1 << (maxDepth + 1));
const longLived = make(longArena, maxDepth);
for (let d = minDepth; d <= maxDepth; d += 2) {
  const iterations = 1 << (maxDepth - d + minDepth);
  let sum = 0;
  for (let i = 0; i < iterations; i++) {
    scratch.size = 0;
    sum += check(scratch, make(scratch, d));
  }
  console.log(iterations + "\t trees of depth " + d + "\t check: " + sum);
}
console.log("long lived tree of depth " + maxDepth + "\t check: " + check(longArena, longLived));
