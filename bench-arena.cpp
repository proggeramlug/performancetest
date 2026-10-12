// binary-trees with an arena: each tree gets a std::pmr::monotonic_buffer_resource,
// nodes are bump-allocated and the whole tree is freed at once when it goes out of scope.
#include <cstdio>
#include <memory_resource>

struct TreeNode { TreeNode *left, *right; };
using Arena = std::pmr::monotonic_buffer_resource;

TreeNode* make(int depth, Arena& a) {
  auto* n = static_cast<TreeNode*>(a.allocate(sizeof(TreeNode), alignof(TreeNode)));
  n->left = depth > 0 ? make(depth - 1, a) : nullptr;
  n->right = depth > 0 ? make(depth - 1, a) : nullptr;
  return n;
}

long check(const TreeNode* n) {
  if (!n->left || !n->right) return 1;
  return 1 + check(n->left) + check(n->right);
}

int main() {
  const int minDepth = 4, maxDepth = 21;
  {
    Arena a;
    printf("stretch tree of depth %d\t check: %ld\n", maxDepth + 1, check(make(maxDepth + 1, a)));
  }
  Arena longArena;
  TreeNode* longLived = make(maxDepth, longArena);
  for (int d = minDepth; d <= maxDepth; d += 2) {
    long iterations = 1L << (maxDepth - d + minDepth);
    long sum = 0;
    for (long i = 0; i < iterations; i++) {
      Arena a;
      sum += check(make(d, a));
    }
    printf("%ld\t trees of depth %d\t check: %ld\n", iterations, d, sum);
  }
  printf("long lived tree of depth %d\t check: %ld\n", maxDepth, check(longLived));
}
