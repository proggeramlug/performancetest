// binary-trees: allocates ~300M short-lived nodes, keeps one long-lived tree.
// No GC: unique_ptr frees each tree when it goes out of scope (malloc/free).
#include <cstdio>
#include <memory>

struct TreeNode {
  std::unique_ptr<TreeNode> left, right;
};

std::unique_ptr<TreeNode> make(int depth) {
  auto n = std::make_unique<TreeNode>();
  if (depth > 0) {
    n->left = make(depth - 1);
    n->right = make(depth - 1);
  }
  return n;
}

long check(const TreeNode* n) {
  if (!n->left || !n->right) return 1;
  return 1 + check(n->left.get()) + check(n->right.get());
}

int main() {
  const int minDepth = 4, maxDepth = 21;
  printf("stretch tree of depth %d\t check: %ld\n", maxDepth + 1, check(make(maxDepth + 1).get()));
  auto longLived = make(maxDepth);
  for (int d = minDepth; d <= maxDepth; d += 2) {
    long iterations = 1L << (maxDepth - d + minDepth);
    long sum = 0;
    for (long i = 0; i < iterations; i++) sum += check(make(d).get());
    printf("%ld\t trees of depth %d\t check: %ld\n", iterations, d, sum);
  }
  printf("long lived tree of depth %d\t check: %ld\n", maxDepth, check(longLived.get()));
}
