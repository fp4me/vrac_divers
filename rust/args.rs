use std::i64;

fn main() {
let result = i64::from_str_radix("256757", 16).unwrap();
let ret = result | ((0xffffffff00000000 as u64) as i64);//result.overflowing_add(29);
println!(" tt {}", ret);
}
