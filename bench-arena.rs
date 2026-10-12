// binary-trees with an arena: nodes live in one Vec, linked by index.
// Each short-lived tree reuses the same Vec (clear() keeps the capacity).
const NONE: u32 = u32::MAX;
struct TreeNode { left: u32, right: u32 }

fn make(arena: &mut Vec<TreeNode>, depth: u32) -> u32 {
    let (left, right) = if depth == 0 { (NONE, NONE) }
        else { (make(arena, depth - 1), make(arena, depth - 1)) };
    arena.push(TreeNode { left, right });
    (arena.len() - 1) as u32
}

fn check(arena: &[TreeNode], i: u32) -> u64 {
    let n = &arena[i as usize];
    if n.left == NONE || n.right == NONE { return 1; }
    1 + check(arena, n.left) + check(arena, n.right)
}

fn main() {
    let (min_depth, max_depth) = (4u32, 21u32);
    let mut scratch = Vec::new();
    let root = make(&mut scratch, max_depth + 1);
    println!("stretch tree of depth {}\t check: {}", max_depth + 1, check(&scratch, root));
    let mut long_arena = Vec::new();
    let long_root = make(&mut long_arena, max_depth);
    let mut d = min_depth;
    while d <= max_depth {
        let iterations = 1u64 << (max_depth - d + min_depth);
        let mut sum = 0;
        for _ in 0..iterations {
            scratch.clear();
            let r = make(&mut scratch, d);
            sum += check(&scratch, r);
        }
        println!("{}\t trees of depth {}\t check: {}", iterations, d, sum);
        d += 2;
    }
    println!("long lived tree of depth {}\t check: {}", max_depth, check(&long_arena, long_root));
}
