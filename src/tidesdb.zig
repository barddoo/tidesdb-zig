// TidesDB Zig bindings.
// Pattern: pub extern fn + native Zig types, methods on opaque handles.
// No @cImport — all types declared manually.
const std = @import("std");

// ─── Error handling ───────────────────────────────────────────────────────────

pub const Error = error{
    Memory,
    InvalidArgs,
    NotFound,
    Io,
    Corruption,
    Exists,
    Conflict,
    TooLarge,
    MemoryLimit,
    InvalidDb,
    Unknown,
    Locked,
    ReadOnly,
    Busy,
    Precondition,
};

pub fn wrap(code: c_int) Error!void {
    return switch (code) {
        0 => {},
        -1 => error.Memory,
        -2 => error.InvalidArgs,
        -3 => error.NotFound,
        -4 => error.Io,
        -5 => error.Corruption,
        -6 => error.Exists,
        -7 => error.Conflict,
        -8 => error.TooLarge,
        -9 => error.MemoryLimit,
        -10 => error.InvalidDb,
        -11 => error.Unknown,
        -12 => error.Locked,
        -13 => error.ReadOnly,
        -14 => error.Busy,
        -15 => error.Precondition,
        else => error.Unknown,
    };
}

// ─── Enums ────────────────────────────────────────────────────────────────────

pub const LogLevel = enum(c_int) {
    debug = 0,
    info = 1,
    warn = 2,
    @"error" = 3,
    fatal = 4,
    none = 99,
};

pub const IsolationLevel = enum(c_int) {
    read_uncommitted = 0,
    read_committed = 1,
    repeatable_read = 2,
    snapshot = 3,
    serializable = 4,
};

pub const SyncMode = enum(c_int) {
    none = 0,
    full = 1,
    interval = 2,
};

pub const CompressionAlgorithm = enum(c_int) {
    none = 0,
    snappy = 1,
    lz4 = 2,
    zstd = 3,
    lz4_fast = 4,
};

// ─── Function pointer types ───────────────────────────────────────────────────

pub const ComparatorFn = *const fn (
    key1: [*]const u8,
    key1_size: usize,
    key2: [*]const u8,
    key2_size: usize,
    ctx: ?*anyopaque,
) callconv(.c) c_int;

pub const CommitHookFn = *const fn (
    ops: [*]const CommitOp,
    num_ops: c_int,
    commit_seq: u64,
    ctx: ?*anyopaque,
) callconv(.c) c_int;

// ─── Opaque object store handles (pointer-only, used in DbConfig) ─────────────

pub const ObjStore = opaque {};
pub const ObjStoreConfig = opaque {};

// ─── Plain value types ────────────────────────────────────────────────────────

pub const CommitOp = extern struct {
    key: ?[*]const u8,
    key_size: usize,
    value: ?[*]const u8,
    value_size: usize,
    ttl: i64,
    is_delete: c_int,
};

// ─── Config structs ───────────────────────────────────────────────────────────

pub const ColumnFamilyConfig = extern struct {
    name: [128]u8,
    write_buffer_size: usize,
    level_size_ratio: usize,
    min_levels: c_int,
    dividing_level_offset: c_int,
    klog_value_threshold: usize,
    compression_algorithm: CompressionAlgorithm,
    enable_bloom_filter: c_int,
    bloom_fpr: f64,
    enable_block_indexes: c_int,
    index_sample_ratio: c_int,
    block_index_prefix_len: c_int,
    sync_mode: c_int,
    sync_interval_us: u64,
    comparator_name: [64]u8,
    comparator_ctx_str: [256]u8,
    comparator_fn_cached: ?ComparatorFn,
    comparator_ctx_cached: ?*anyopaque,
    skip_list_max_level: c_int,
    skip_list_probability: f32,
    default_isolation_level: IsolationLevel,
    min_disk_space: u64,
    l1_file_count_trigger: c_int,
    l0_queue_stall_threshold: c_int,
    tombstone_density_trigger: f64,
    tombstone_density_min_entries: u64,
    use_btree: c_int,
    commit_hook_fn: ?CommitHookFn,
    commit_hook_ctx: ?*anyopaque,
    object_target_file_size: usize,
    object_lazy_compaction: c_int,
    object_prefetch_compaction: c_int,

    pub fn default() ColumnFamilyConfig {
        return tidesdb_default_column_family_config();
    }
};

pub const DbConfig = extern struct {
    // const here is safe: TidesDB copies the path on open
    db_path: ?[*:0]const u8,
    num_flush_threads: c_int,
    num_compaction_threads: c_int,
    log_level: LogLevel,
    block_cache_size: usize,
    max_open_sstables: usize,
    log_to_file: c_int,
    log_truncation_at: usize,
    max_memory_usage: usize,
    unified_memtable: c_int,
    unified_memtable_write_buffer_size: usize,
    unified_memtable_skip_list_max_level: c_int,
    unified_memtable_skip_list_probability: f32,
    unified_memtable_sync_mode: c_int,
    unified_memtable_sync_interval_us: u64,
    object_store: ?*ObjStore,
    object_store_config: ?*ObjStoreConfig,
    max_concurrent_flushes: c_int,
    finish_compactions_on_close: c_int,

    pub fn default() DbConfig {
        return tidesdb_default_config();
    }
};

// ─── Stats structs ────────────────────────────────────────────────────────────

pub const Stats = extern struct {
    num_levels: c_int,
    memtable_size: usize,
    level_sizes: ?[*]usize,
    level_num_sstables: ?[*]c_int,
    config: ?*ColumnFamilyConfig,
    total_keys: u64,
    total_data_size: u64,
    avg_key_size: f64,
    avg_value_size: f64,
    level_key_counts: ?[*]u64,
    read_amp: f64,
    hit_rate: f64,
    use_btree: c_int,
    btree_total_nodes: u64,
    btree_max_height: u32,
    btree_avg_height: f64,
    total_tombstones: u64,
    tombstone_ratio: f64,
    level_tombstone_counts: ?[*]u64,
    max_sst_density: f64,
    max_sst_density_level: c_int,
    wal_bytes_written: u64,
    flush_bytes_written: u64,
    compaction_bytes_written: u64,
    compaction_bytes_read: u64,
    user_bytes_written: u64,
    flush_count: u64,
    compaction_count: u64,
};

pub const CacheStats = extern struct {
    enabled: c_int,
    total_entries: usize,
    total_bytes: usize,
    hits: u64,
    misses: u64,
    hit_rate: f64,
    num_partitions: usize,
};

pub const DbStats = extern struct {
    num_column_families: c_int,
    total_memory: u64,
    available_memory: u64,
    resolved_memory_limit: usize,
    memory_pressure_level: c_int,
    flush_pending_count: c_int,
    total_memtable_bytes: i64,
    total_immutable_count: c_int,
    total_sstable_count: c_int,
    total_data_size_bytes: u64,
    num_open_sstables: c_int,
    global_seq: u64,
    txn_memory_bytes: i64,
    compaction_queue_size: usize,
    flush_queue_size: usize,
    unified_memtable_enabled: c_int,
    unified_memtable_bytes: i64,
    unified_immutable_count: c_int,
    unified_is_flushing: c_int,
    unified_next_cf_index: u32,
    unified_wal_generation: u64,
    object_store_enabled: c_int,
    object_store_connector: ?[*:0]const u8,
    local_cache_bytes_used: usize,
    local_cache_bytes_max: usize,
    local_cache_num_files: c_int,
    last_uploaded_generation: u64,
    upload_queue_depth: usize,
    total_uploads: u64,
    total_upload_failures: u64,
    replica_mode: c_int,
    primary_epoch: u64,
    seen_epoch: u64,
    uwal_bytes_written: u64,
    wal_bytes_written: u64,
    flush_bytes_written: u64,
    compaction_bytes_written: u64,
    compaction_bytes_read: u64,
    user_bytes_written: u64,
    flush_count: u64,
    compaction_count: u64,
};

// ─── Memory ownership helpers ─────────────────────────────────────────────────

/// Heap buffer allocated by TidesDB (e.g. txn.get). Caller must call deinit() exactly once.
pub const OwnedSlice = struct {
    bytes: []u8,

    pub fn deinit(self: OwnedSlice) void {
        tidesdb_free(self.bytes.ptr);
    }
};

/// Borrowed key+value from Iterator.keyValue(). Points into iterator internals —
/// valid only until the next next()/prev()/seek*() or deinit(). Do NOT free.
pub const BorrowedKeyValue = struct {
    key: []const u8,
    value: []const u8,
};

/// Column family name list from Db.listColumnFamilies().
/// Names are valid until deinit() is called.
pub const OwnedNames = struct {
    raw: [*c][*c]u8,
    count: usize,

    pub fn deinit(self: OwnedNames) void {
        for (0..self.count) |i| tidesdb_free(self.raw[i]);
        tidesdb_free(self.raw);
    }

    pub fn len(self: OwnedNames) usize {
        return self.count;
    }

    pub fn get(self: OwnedNames, i: usize) []const u8 {
        return std.mem.span(@as([*:0]const u8, @ptrCast(self.raw[i])));
    }
};

// ─── Opaque handle types ──────────────────────────────────────────────────────

pub const Db = opaque {
    pub fn open(config: *const DbConfig) Error!*Db {
        var db: ?*Db = null;
        try wrap(tidesdb_open(config, &db));
        return db.?;
    }

    pub fn close(db: *Db) Error!void {
        return wrap(tidesdb_close(db));
    }

    pub fn promoteToReplica(db: *Db) Error!void {
        return wrap(tidesdb_promote_to_primary(db));
    }

    pub fn createColumnFamily(db: *Db, name: [*:0]const u8, config: *const ColumnFamilyConfig) Error!void {
        return wrap(tidesdb_create_column_family(db, name, config));
    }

    pub fn dropColumnFamily(db: *Db, name: [*:0]const u8) Error!void {
        return wrap(tidesdb_drop_column_family(db, name));
    }

    pub fn deleteColumnFamily(db: *Db, cf: *ColumnFamily) Error!void {
        return wrap(tidesdb_delete_column_family(db, cf));
    }

    pub fn renameColumnFamily(db: *Db, old_name: [*:0]const u8, new_name: [*:0]const u8) Error!void {
        return wrap(tidesdb_rename_column_family(db, old_name, new_name));
    }

    pub fn cloneColumnFamily(db: *Db, src_name: [*:0]const u8, dst_name: [*:0]const u8) Error!void {
        return wrap(tidesdb_clone_column_family(db, src_name, dst_name));
    }

    /// Returned pointer is valid while the Db is open.
    pub fn getColumnFamily(db: *Db, name: [*:0]const u8) ?*ColumnFamily {
        return tidesdb_get_column_family(db, name);
    }

    /// Caller must call names.deinit() when done.
    pub fn listColumnFamilies(db: *Db) Error!OwnedNames {
        var raw: [*c][*c]u8 = null;
        var count: c_int = 0;
        try wrap(tidesdb_list_column_families(db, &raw, &count));
        return .{ .raw = raw, .count = @intCast(count) };
    }

    pub fn beginTxn(db: *Db) Error!*Transaction {
        var txn: ?*Transaction = null;
        try wrap(tidesdb_txn_begin(db, &txn));
        return txn.?;
    }

    pub fn beginTxnWithIsolation(db: *Db, level: IsolationLevel) Error!*Transaction {
        var txn: ?*Transaction = null;
        try wrap(tidesdb_txn_begin_with_isolation(db, level, &txn));
        return txn.?;
    }

    pub fn backup(db: *Db, dir: [*:0]u8) Error!void {
        return wrap(tidesdb_backup(db, dir));
    }

    pub fn checkpoint(db: *Db, dir: [*:0]const u8) Error!void {
        return wrap(tidesdb_checkpoint(db, dir));
    }

    pub fn purge(db: *Db) Error!void {
        return wrap(tidesdb_purge(db));
    }

    pub fn cancelBackgroundWork(db: *Db) Error!void {
        return wrap(tidesdb_cancel_background_work(db));
    }

    pub fn getDbStats(db: *Db) Error!DbStats {
        var stats: DbStats = undefined;
        try wrap(tidesdb_get_db_stats(db, &stats));
        return stats;
    }

    pub fn getCacheStats(db: *Db) Error!CacheStats {
        var stats: CacheStats = undefined;
        try wrap(tidesdb_get_cache_stats(db, &stats));
        return stats;
    }

    pub fn registerComparator(
        db: *Db,
        name: [*:0]const u8,
        fn_ptr: ComparatorFn,
        ctx_str: ?[*:0]const u8,
        ctx: ?*anyopaque,
    ) Error!void {
        return wrap(tidesdb_register_comparator(db, name, fn_ptr, ctx_str, ctx));
    }

    pub fn raiseOpenFileLimit(desired: c_long) c_long {
        return tidesdb_raise_open_file_limit(desired);
    }
};

pub const ColumnFamily = opaque {
    pub fn compact(cf: *ColumnFamily) Error!void {
        return wrap(tidesdb_compact(cf));
    }

    pub fn compactRange(cf: *ColumnFamily, start_key: []const u8, end_key: []const u8) Error!void {
        return wrap(tidesdb_compact_range(cf, start_key.ptr, start_key.len, end_key.ptr, end_key.len));
    }

    pub fn flushMemtable(cf: *ColumnFamily) Error!void {
        return wrap(tidesdb_flush_memtable(cf));
    }

    pub fn isFlushing(cf: *ColumnFamily) bool {
        return tidesdb_is_flushing(cf) != 0;
    }

    pub fn isCompacting(cf: *ColumnFamily) bool {
        return tidesdb_is_compacting(cf) != 0;
    }

    pub fn purge(cf: *ColumnFamily) Error!void {
        return wrap(tidesdb_purge_cf(cf));
    }

    pub fn syncWal(cf: *ColumnFamily) Error!void {
        return wrap(tidesdb_sync_wal(cf));
    }

    /// Returned Stats is heap-allocated. Call ColumnFamily.freeStats(stats) when done.
    pub fn getStats(cf: *ColumnFamily) Error!*Stats {
        var stats: ?*Stats = null;
        try wrap(tidesdb_get_stats(cf, &stats));
        return stats.?;
    }

    pub fn freeStats(stats: *Stats) void {
        tidesdb_free_stats(stats);
    }

    pub fn setCommitHook(cf: *ColumnFamily, fn_ptr: ?CommitHookFn, ctx: ?*anyopaque) Error!void {
        return wrap(tidesdb_cf_set_commit_hook(cf, fn_ptr, ctx));
    }

    pub fn updateRuntimeConfig(cf: *ColumnFamily, config: *const ColumnFamilyConfig, persist: bool) Error!void {
        return wrap(tidesdb_cf_update_runtime_config(cf, config, @intFromBool(persist)));
    }

    pub fn rangeCost(cf: *ColumnFamily, key_a: []const u8, key_b: []const u8) Error!f64 {
        var cost: f64 = 0;
        try wrap(tidesdb_range_cost(cf, key_a.ptr, key_a.len, key_b.ptr, key_b.len, &cost));
        return cost;
    }
};

pub const Transaction = opaque {
    pub fn put(txn: *Transaction, cf: *ColumnFamily, key: []const u8, value: []const u8, ttl: i64) Error!void {
        return wrap(tidesdb_txn_put(txn, cf, key.ptr, key.len, value.ptr, value.len, ttl));
    }

    /// Returns TidesDB-owned memory. Caller must call slice.deinit().
    pub fn get(txn: *Transaction, cf: *ColumnFamily, key: []const u8) Error!OwnedSlice {
        var value_ptr: ?[*]u8 = null;
        var value_size: usize = 0;
        try wrap(tidesdb_txn_get(txn, cf, key.ptr, key.len, &value_ptr, &value_size));
        return .{ .bytes = value_ptr.?[0..value_size] };
    }

    pub fn delete(txn: *Transaction, cf: *ColumnFamily, key: []const u8) Error!void {
        return wrap(tidesdb_txn_delete(txn, cf, key.ptr, key.len));
    }

    pub fn singleDelete(txn: *Transaction, cf: *ColumnFamily, key: []const u8) Error!void {
        return wrap(tidesdb_txn_single_delete(txn, cf, key.ptr, key.len));
    }

    pub fn commit(txn: *Transaction) Error!void {
        return wrap(tidesdb_txn_commit(txn));
    }

    pub fn rollback(txn: *Transaction) Error!void {
        return wrap(tidesdb_txn_rollback(txn));
    }

    pub fn deinit(txn: *Transaction) void {
        tidesdb_txn_free(txn);
    }

    pub fn reset(txn: *Transaction, level: IsolationLevel) Error!void {
        return wrap(tidesdb_txn_reset(txn, level));
    }

    pub fn savepoint(txn: *Transaction, name: [*:0]const u8) Error!void {
        return wrap(tidesdb_txn_savepoint(txn, name));
    }

    pub fn rollbackToSavepoint(txn: *Transaction, name: [*:0]const u8) Error!void {
        return wrap(tidesdb_txn_rollback_to_savepoint(txn, name));
    }

    pub fn releaseSavepoint(txn: *Transaction, name: [*:0]const u8) Error!void {
        return wrap(tidesdb_txn_release_savepoint(txn, name));
    }

    /// Creates an iterator over the given column family in this transaction's snapshot.
    /// Caller must call iter.deinit() when done.
    pub fn newIter(txn: *Transaction, cf: *ColumnFamily) Error!*Iterator {
        var iter: ?*Iterator = null;
        try wrap(tidesdb_iter_new(txn, cf, &iter));
        return iter.?;
    }
};

pub const Iterator = opaque {
    pub fn seekToFirst(iter: *Iterator) Error!void {
        return wrap(tidesdb_iter_seek_to_first(iter));
    }

    pub fn seekToLast(iter: *Iterator) Error!void {
        return wrap(tidesdb_iter_seek_to_last(iter));
    }

    pub fn seek(iter: *Iterator, target: []const u8) Error!void {
        return wrap(tidesdb_iter_seek(iter, target.ptr, target.len));
    }

    pub fn seekForPrev(iter: *Iterator, target: []const u8) Error!void {
        return wrap(tidesdb_iter_seek_for_prev(iter, target.ptr, target.len));
    }

    pub fn next(iter: *Iterator) Error!void {
        return wrap(tidesdb_iter_next(iter));
    }

    pub fn prev(iter: *Iterator) Error!void {
        return wrap(tidesdb_iter_prev(iter));
    }

    pub fn valid(iter: *Iterator) bool {
        return tidesdb_iter_valid(iter) != 0;
    }

    /// Borrowed — valid until next next()/prev()/seek*()/deinit(). Do NOT free.
    pub fn key(iter: *Iterator) Error![]const u8 {
        var k: ?[*]u8 = null;
        var k_size: usize = 0;
        try wrap(tidesdb_iter_key(iter, &k, &k_size));
        return k.?[0..k_size];
    }

    /// Borrowed — valid until next next()/prev()/seek*()/deinit(). Do NOT free.
    pub fn value(iter: *Iterator) Error![]const u8 {
        var v: ?[*]u8 = null;
        var v_size: usize = 0;
        try wrap(tidesdb_iter_value(iter, &v, &v_size));
        return v.?[0..v_size];
    }

    /// Returns both key and value. Both are borrowed — valid until next next()/prev()/seek*()/deinit().
    pub fn keyValue(iter: *Iterator) Error!BorrowedKeyValue {
        var k: ?[*]u8 = null;
        var k_size: usize = 0;
        var v: ?[*]u8 = null;
        var v_size: usize = 0;
        try wrap(tidesdb_iter_key_value(iter, &k, &k_size, &v, &v_size));
        return .{
            .key = k.?[0..k_size],
            .value = v.?[0..v_size],
        };
    }

    pub fn deinit(iter: *Iterator) void {
        tidesdb_iter_free(iter);
    }
};

// ─── Raw C function declarations ──────────────────────────────────────────────

/// Prefer ColumnFamilyConfig.default().
pub extern fn tidesdb_default_column_family_config() ColumnFamilyConfig;
/// Prefer DbConfig.default().
pub extern fn tidesdb_default_config() DbConfig;

/// Prefer Db.open.
pub extern fn tidesdb_open(config: *const DbConfig, db: *?*Db) c_int;
/// Prefer Db.close.
pub extern fn tidesdb_close(db: *Db) c_int;
pub extern fn tidesdb_raise_open_file_limit(desired: c_long) c_long;
pub extern fn tidesdb_promote_to_primary(db: *Db) c_int;

pub extern fn tidesdb_register_comparator(db: *Db, name: [*:0]const u8, fn_ptr: ComparatorFn, ctx_str: ?[*:0]const u8, ctx: ?*anyopaque) c_int;
pub extern fn tidesdb_get_comparator(db: *Db, name: [*:0]const u8, fn_ptr: *ComparatorFn, ctx: *?*anyopaque) c_int;

pub extern fn tidesdb_comparator_memcmp(key1: [*]const u8, key1_size: usize, key2: [*]const u8, key2_size: usize, ctx: ?*anyopaque) c_int;
pub extern fn tidesdb_comparator_lexicographic(key1: [*]const u8, key1_size: usize, key2: [*]const u8, key2_size: usize, ctx: ?*anyopaque) c_int;
pub extern fn tidesdb_comparator_uint64(key1: [*]const u8, key1_size: usize, key2: [*]const u8, key2_size: usize, ctx: ?*anyopaque) c_int;
pub extern fn tidesdb_comparator_int64(key1: [*]const u8, key1_size: usize, key2: [*]const u8, key2_size: usize, ctx: ?*anyopaque) c_int;
pub extern fn tidesdb_comparator_reverse_memcmp(key1: [*]const u8, key1_size: usize, key2: [*]const u8, key2_size: usize, ctx: ?*anyopaque) c_int;
pub extern fn tidesdb_comparator_case_insensitive(key1: [*]const u8, key1_size: usize, key2: [*]const u8, key2_size: usize, ctx: ?*anyopaque) c_int;

/// Prefer Db.createColumnFamily.
pub extern fn tidesdb_create_column_family(db: *Db, name: [*:0]const u8, config: *const ColumnFamilyConfig) c_int;
/// Prefer Db.dropColumnFamily.
pub extern fn tidesdb_drop_column_family(db: *Db, name: [*:0]const u8) c_int;
pub extern fn tidesdb_delete_column_family(db: *Db, cf: *ColumnFamily) c_int;
pub extern fn tidesdb_rename_column_family(db: *Db, old_name: [*:0]const u8, new_name: [*:0]const u8) c_int;
/// Prefer Db.getColumnFamily.
pub extern fn tidesdb_get_column_family(db: *Db, name: [*:0]const u8) ?*ColumnFamily;
pub extern fn tidesdb_list_column_families(db: *Db, names: *[*c][*c]u8, count: *c_int) c_int;
pub extern fn tidesdb_clone_column_family(db: *Db, src_name: [*:0]const u8, dst_name: [*:0]const u8) c_int;
pub extern fn tidesdb_cf_set_commit_hook(cf: *ColumnFamily, fn_ptr: ?CommitHookFn, ctx: ?*anyopaque) c_int;
pub extern fn tidesdb_cf_config_load_from_ini(ini_file: [*:0]const u8, section_name: [*:0]const u8, config: *ColumnFamilyConfig) c_int;
pub extern fn tidesdb_cf_config_save_to_ini(ini_file: [*:0]const u8, section_name: [*:0]const u8, config: *const ColumnFamilyConfig) c_int;
pub extern fn tidesdb_cf_update_runtime_config(cf: *ColumnFamily, config: *const ColumnFamilyConfig, persist_to_disk: c_int) c_int;

/// Prefer Db.beginTxn.
pub extern fn tidesdb_txn_begin(db: *Db, txn: *?*Transaction) c_int;
/// Prefer Db.beginTxnWithIsolation.
pub extern fn tidesdb_txn_begin_with_isolation(db: *Db, isolation: IsolationLevel, txn: *?*Transaction) c_int;
/// Prefer Transaction.put.
pub extern fn tidesdb_txn_put(txn: *Transaction, cf: *ColumnFamily, key: [*]const u8, key_size: usize, value: [*]const u8, value_size: usize, ttl: i64) c_int;
/// Prefer Transaction.get.
pub extern fn tidesdb_txn_get(txn: *Transaction, cf: *ColumnFamily, key: [*]const u8, key_size: usize, value: *?[*]u8, value_size: *usize) c_int;
/// Prefer Transaction.delete.
pub extern fn tidesdb_txn_delete(txn: *Transaction, cf: *ColumnFamily, key: [*]const u8, key_size: usize) c_int;
pub extern fn tidesdb_txn_single_delete(txn: *Transaction, cf: *ColumnFamily, key: [*]const u8, key_size: usize) c_int;
/// Prefer Transaction.commit.
pub extern fn tidesdb_txn_commit(txn: *Transaction) c_int;
/// Prefer Transaction.rollback.
pub extern fn tidesdb_txn_rollback(txn: *Transaction) c_int;
/// Prefer Transaction.deinit.
pub extern fn tidesdb_txn_free(txn: *Transaction) void;
pub extern fn tidesdb_txn_reset(txn: *Transaction, isolation: IsolationLevel) c_int;
pub extern fn tidesdb_txn_savepoint(txn: *Transaction, name: [*:0]const u8) c_int;
pub extern fn tidesdb_txn_rollback_to_savepoint(txn: *Transaction, name: [*:0]const u8) c_int;
pub extern fn tidesdb_txn_release_savepoint(txn: *Transaction, name: [*:0]const u8) c_int;

/// Prefer Transaction.newIter.
pub extern fn tidesdb_iter_new(txn: *Transaction, cf: *ColumnFamily, iter: *?*Iterator) c_int;
pub extern fn tidesdb_iter_seek(iter: *Iterator, key: [*]const u8, key_size: usize) c_int;
pub extern fn tidesdb_iter_seek_for_prev(iter: *Iterator, key: [*]const u8, key_size: usize) c_int;
pub extern fn tidesdb_iter_seek_to_first(iter: *Iterator) c_int;
pub extern fn tidesdb_iter_seek_to_last(iter: *Iterator) c_int;
pub extern fn tidesdb_iter_next(iter: *Iterator) c_int;
pub extern fn tidesdb_iter_prev(iter: *Iterator) c_int;
pub extern fn tidesdb_iter_valid(iter: *Iterator) c_int;
pub extern fn tidesdb_iter_key(iter: *Iterator, k: *?[*]u8, k_size: *usize) c_int;
pub extern fn tidesdb_iter_value(iter: *Iterator, v: *?[*]u8, v_size: *usize) c_int;
pub extern fn tidesdb_iter_key_value(iter: *Iterator, k: *?[*]u8, k_size: *usize, v: *?[*]u8, v_size: *usize) c_int;
/// Prefer Iterator.deinit.
pub extern fn tidesdb_iter_free(iter: *Iterator) void;

pub extern fn tidesdb_compact(cf: *ColumnFamily) c_int;
pub extern fn tidesdb_compact_range(cf: *ColumnFamily, start_key: [*]const u8, start_key_size: usize, end_key: [*]const u8, end_key_size: usize) c_int;
pub extern fn tidesdb_flush_memtable(cf: *ColumnFamily) c_int;
pub extern fn tidesdb_is_flushing(cf: *ColumnFamily) c_int;
pub extern fn tidesdb_is_compacting(cf: *ColumnFamily) c_int;
pub extern fn tidesdb_purge_cf(cf: *ColumnFamily) c_int;
pub extern fn tidesdb_purge(db: *Db) c_int;
pub extern fn tidesdb_cancel_background_work(db: *Db) c_int;
pub extern fn tidesdb_sync_wal(cf: *ColumnFamily) c_int;

pub extern fn tidesdb_backup(db: *Db, dir: [*:0]u8) c_int;
pub extern fn tidesdb_checkpoint(db: *Db, dir: [*:0]const u8) c_int;

pub extern fn tidesdb_get_stats(cf: *ColumnFamily, stats: *?*Stats) c_int;
pub extern fn tidesdb_free_stats(stats: *Stats) void;
pub extern fn tidesdb_get_db_stats(db: *Db, stats: *DbStats) c_int;
pub extern fn tidesdb_get_cache_stats(db: *Db, stats: *CacheStats) c_int;

pub extern fn tidesdb_range_cost(cf: *ColumnFamily, key_a: [*]const u8, key_a_size: usize, key_b: [*]const u8, key_b_size: usize, cost: *f64) c_int;
/// Free any pointer allocated by TidesDB.
pub extern fn tidesdb_free(ptr: ?*anyopaque) void;
pub extern fn tidesdb_log_write(level: c_int, file: [*:0]const u8, line: c_int, fmt: [*:0]const u8, ...) void;

// ─── Tests ────────────────────────────────────────────────────────────────────

test "open and close" {
    var config = DbConfig.default();
    config.db_path = "/tmp/tidesdb_zig_test_open";
    config.log_level = .none;
    const db = try Db.open(&config);
    try db.close();
}

test "create cf, put, get, iterate" {
    var config = DbConfig.default();
    config.db_path = "/tmp/tidesdb_zig_test_crud";
    config.log_level = .none;

    const db = try Db.open(&config);
    defer db.close() catch {};

    const cf_config = ColumnFamilyConfig.default();
    db.createColumnFamily("test", &cf_config) catch |err| {
        if (err != error.Exists) return err;
    };

    const cf = db.getColumnFamily("test") orelse return error.ColumnFamilyNotFound;

    const wtxn = try db.beginTxn();
    defer wtxn.deinit();
    try wtxn.put(cf, "k1", "v1", 0);
    try wtxn.put(cf, "k2", "v2", 0);
    try wtxn.commit();

    const rtxn = try db.beginTxn();
    defer rtxn.deinit();

    const val = try rtxn.get(cf, "k1");
    defer val.deinit();
    try std.testing.expectEqualStrings("v1", val.bytes);

    const iter = try rtxn.newIter(cf);
    defer iter.deinit();
    try iter.seekToFirst();
    var count: usize = 0;
    while (iter.valid()) {
        _ = try iter.keyValue(); // borrowed — do NOT free
        count += 1;
        iter.next() catch break;
    }
    try std.testing.expect(count >= 2);
}
