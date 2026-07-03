const std = @import("std");
const tdb = @import("tidesdb");

pub fn main() !void {
    var config = tdb.DbConfig.default();
    config.db_path = "/tmp/tidesdb_zig_demo";
    config.log_level = .none;

    const db = try tdb.Db.open(&config);
    defer db.close() catch {};

    var cf_config = tdb.ColumnFamilyConfig.default();
    cf_config.enable_bloom_filter = 1;

    db.createColumnFamily("users", &cf_config) catch |err| switch (err) {
        error.Exists => {},
        else => return err,
    };

    const cf = db.getColumnFamily("users") orelse return error.ColumnFamilyNotFound;

    const wtxn = try db.beginTxn();
    defer wtxn.deinit();
    try wtxn.put(cf, "alice", "25", 0);
    try wtxn.put(cf, "bob", "30", 0);
    try wtxn.put(cf, "carol", "28", 0);
    try wtxn.commit();

    const rtxn = try db.beginTxn();
    defer rtxn.deinit();

    const val = try rtxn.get(cf, "alice");
    defer val.deinit();
    std.debug.print("alice => {s}\n", .{val.bytes});

    const iter = try rtxn.newIter(cf);
    defer iter.deinit();
    try iter.seekToFirst();
    std.debug.print("all entries:\n", .{});
    while (iter.valid()) {
        const kv = try iter.keyValue(); // borrowed — do NOT free
        std.debug.print("  {s} => {s}\n", .{ kv.key, kv.value });
        iter.next() catch break;
    }

    const stats = try cf.getStats();
    defer tdb.ColumnFamily.freeStats(stats);
    std.debug.print("levels={d} total_keys={d}\n", .{ stats.num_levels, stats.total_keys });
}
