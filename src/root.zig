//! TidesDB Zig bindings. Import as `const tdb = @import("tidesdb")`.
const t = @import("tidesdb.zig");

pub const Db = t.Db;
pub const ColumnFamily = t.ColumnFamily;
pub const Transaction = t.Transaction;
pub const Iterator = t.Iterator;

pub const DbConfig = t.DbConfig;
pub const ColumnFamilyConfig = t.ColumnFamilyConfig;
pub const Stats = t.Stats;
pub const CacheStats = t.CacheStats;
pub const DbStats = t.DbStats;
pub const CommitOp = t.CommitOp;

pub const OwnedSlice = t.OwnedSlice;
pub const BorrowedKeyValue = t.BorrowedKeyValue;
pub const OwnedNames = t.OwnedNames;

pub const LogLevel = t.LogLevel;
pub const IsolationLevel = t.IsolationLevel;
pub const SyncMode = t.SyncMode;
pub const CompressionAlgorithm = t.CompressionAlgorithm;

pub const ComparatorFn = t.ComparatorFn;
pub const CommitHookFn = t.CommitHookFn;

pub const Error = t.Error;
pub const wrap = t.wrap;

pub const comparatorMemcmp = t.tidesdb_comparator_memcmp;
pub const comparatorLexicographic = t.tidesdb_comparator_lexicographic;
pub const comparatorUint64 = t.tidesdb_comparator_uint64;
pub const comparatorInt64 = t.tidesdb_comparator_int64;
pub const comparatorReverseMemcmp = t.tidesdb_comparator_reverse_memcmp;
pub const comparatorCaseInsensitive = t.tidesdb_comparator_case_insensitive;
