----
local log_dict = ngx.shared.log_dict
local latency_dict = ngx.shared.latency_dict
---- 重置字典字典
log_dict:flush_all()
latency_dict:flush_all()