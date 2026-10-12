// binary-trees: allocates ~300M short-lived nodes, keeps one long-lived tree.
// No GC: Box ownership frees each tree when it goes out of scope.
struct TreeNode {
    left: Option<Box<TreeNode>>,
    right: Option<Box<TreeNode>>,
}

fn make(depth: u32) -> Box<TreeNode> {
    if depth == 0 {
        return Box::new(TreeNode { left: None, right: None });
    }
    Box::new(TreeNode { left: Some(make(depth - 1)), right: Some(make(depth - 1)) })
}

fn check(n: &TreeNode) -> u64 {
    match (&n.left, &n.right) {
        (Some(l), Some(r)) => 1 + check(l) + check(r),
        _ => 1,
    }
}

fn main() {
    let (min_depth, max_depth) = (4u32, 21u32);
    println!("stretch tree of depth {}\t check: {}", max_depth + 1, check(&make(max_depth + 1)));
    let long_lived = make(max_depth);
    let mut d = min_depth;
    while d <= max_depth {
        let iterations = 1u64 << (max_depth - d + min_depth);
        let mut sum = 0;
        for _ in 0..iterations {
            sum += check(&make(d));
        }
        println!("{}\t trees of depth {}\t check: {}", iterations, d, sum);
        d += 2;
    }
    println!("long lived tree of depth {}\t check: {}", max_depth, check(&long_lived));
}
