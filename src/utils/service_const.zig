pub const API_ROUTE_SCHEMA = "/api/{s}/{s}"; // INFO: Schema => /api/{version}/{connection_type}"
pub const CONN_TYPE_ADMIN = "admin";
pub const CONN_TYPE_WORKER = "worker";
pub const STATUS_ERROR = "error";
pub const STATUS_OK = "ok";

pub const ErrorCode = enum {
    none,
    not_found,
    connection_type_not_found,
    connection_type_not_implemented,
    server_internal_error,
    server_illegal_argument,

    pub fn asString(self: ErrorCode) []const u8 {
        return @tagName(self);
    }
};