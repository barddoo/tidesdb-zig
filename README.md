# tidesdb-zig

Zig bindings for [TidesDB](https://github.com/tidesdb/tidesdb) — an LSM-tree embedded key-value store with MVCC transactions.

## Requirements

- Zig 0.16.0+

TidesDB C sources (v9.3.10) are vendored — no separate checkout needed.

## Usage

Run in your project:

```sh
zig fetch --save=tidesdb_zig git+https://github.com/barddoo/tidesdb-zig
```

Then in `build.zig`:

```zig
const tdb_dep = b.dependency("tidesdb_zig", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("tidesdb", tdb_dep.module("tidesdb"));
```

## Example

```zig
const tdb = @import("tidesdb");

// Open database
var config = tdb.DbConfig.default();
config.db_path = "/tmp/mydb";
const db = try tdb.Db.open(&config);
defer db.close() catch {};

// Create column family
var cf_config = tdb.ColumnFamilyConfig.default();
db.createColumnFamily("users", &cf_config) catch |err| switch (err) {
    error.Exists => {},
    else => return err,
};
const cf = db.getColumnFamily("users") orelse return error.NotFound;

// Write
const wtxn = try db.beginTxn();
defer wtxn.deinit();
try wtxn.put(cf, "alice", "25", 0);
try wtxn.commit();

// Read
const rtxn = try db.beginTxn();
defer rtxn.deinit();
const val = try rtxn.get(cf, "alice");
defer val.deinit(); // val is heap-allocated — must free
std.debug.print("alice => {s}\n", .{val.bytes});

// Iterate
const iter = try rtxn.newIter(cf);
defer iter.deinit();
try iter.seekToFirst();
while (iter.valid()) {
    const kv = try iter.keyValue(); // borrowed — valid until next()/deinit()
    std.debug.print("{s} => {s}\n", .{ kv.key, kv.value });
    iter.next() catch break;
}
```

## Ownership rules

| API                                                                                   | Ownership                                                           |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| `txn.get()` → `OwnedSlice`                                                            | heap copy — call `.deinit()`                                        |
| `iter.key()` / `iter.value()` / `iter.keyValue()` → `[]const u8` / `BorrowedKeyValue` | borrowed — valid until `next()`, `prev()`, `seek*()`, or `deinit()` |
| `cf.getStats()` → `*Stats`                                                            | heap-allocated — call `ColumnFamily.freeStats(stats)`               |
| `db.listColumnFamilies()` → `OwnedNames`                                              | heap-allocated — call `.deinit()`                                   |

## Building

```sh
zig build          # compile
zig build run      # run example
zig build test     # run tests
```

## License

MIT
