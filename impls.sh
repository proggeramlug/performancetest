# Shared list of implementations, sourced by run.sh and run-gated.sh.
IMPLS="node node-arena go swift kotlin rust rust-arena cpp cpp-arena perry perry-arena scriptc scriptc-arena porffor porffor-arena"
impl_cmd() {
  case $1 in
    node) echo "node bench.js" ;;
    node-arena) echo "node bench-arena.js" ;;
    *) echo "./bin/$1" ;;
  esac
}
