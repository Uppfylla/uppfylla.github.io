use example::zig::zig_add as add;

fn main() {
    println!("Example!");
    for n in 1..101 {
        unsafe {
                println!("Using zig add: {:?}", add(1*n, 2*n));
        }
    }
}
