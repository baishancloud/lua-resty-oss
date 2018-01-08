local netutil = require('netutil')
local net= require("acid.net")
local httpclient = require("acid.httpclient")

local _M = {
    __version = "0.01"
}

local mt = {__index = _M}
local default_timeout = 600000

local function calc_sign(self, str)
    if self.accesskey == nil or self.secretkey == nil then
        return nil
    end

    local key = ngx.encode_base64(ngx.hmac_sha1(self.secretkey, str))
    return 'OSS '.. self.accesskey .. ':' .. key
end

local function send_http_request(self, host, uri, method, headers, body)
    local ip = host

    if not net.is_ip4(host) then
        local ips, err_code, err_msg = netutil.get_ips_from_domain(host)
        if err_code ~= nil then
            return nil, err_code, err_msg
        end

        ip = ips[1]
    end

    local httpc = httpclient:new(ip, 80, self.timeout)

    local h_opts = {
        method = method,
        headers = headers,
        body = body,
    }

    local _, err_code, err_msg = httpc:request(uri, h_opts)
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    local read_body = function(size)
        return httpc:read_body(size)
    end

    return {
        status  = httpc.status,
        headers = httpc.headers,
        read_body = read_body,
    }
end

local function build_auth_headers(self, verb, content, content_type, object_name, acl)
    local bucket            =   self.bucket
    local endpoint          =   self.endpoint
    local bucket_host       =   bucket .. "." .. endpoint
    local Date              =   ngx.http_time(ngx.time())
    local acl               =   acl or 'public-read'
    local aclName           =   "x-oss-acl"
    local MD5               =   ngx.encode_base64(ngx.md5_bin(content))
    local _content_type     =   content_type or  "application/octet-stream"
    local amz               =   "\n" .. aclName .. ":" ..acl
    local resource          =   '/' .. bucket .. '/' .. (object_name or '')
    local CL                =   string.char(10)
    local check_param       =   verb .. CL .. MD5 .. CL .. _content_type .. CL .. Date .. amz .. CL .. resource

    local headers = {
        ['Date']          = Date,
        ['Content-MD5']   = MD5,
        ['Content-Type']  = _content_type,
        ['Authorization'] = calc_sign(self, check_param),
        ['Connection']    = 'keep-alive',
        ['Host']          = bucket_host
    }

    headers[aclName] = acl

    return headers
end

function _M.new(bucket, accesskey, secretkey, opts)
    if bucket == nil then
        return nil, 'InvalidArgment', 'no bucket'
    end

    local obj = {
        bucket = bucket,
        accesskey = accesskey,
        secretkey = secretkey,
    }

    obj.endpoint = opts.endpoint or 'oss-cn-beijing.aliyuncs.com'
    obj.timeout = opts.timeout or default_timeout

    return setmetatable(obj, mt)
end

function _M.delete_object(self, object_name)
    local uri = '/' .. object_name
    local headers = build_auth_headers(self, 'DELETE', nil, nil, object_name)

    local resp, err_code, err_msg =
        send_http_request(self, self.endpoint, uri, "DELETE", headers)
    if err_code ~= nil then
        return nil, err_code, err_msg
    end

    if resp.status ~= 204 then
        local body, err_code, err_msg = resp.read_body(1024 * 1024)
        if err_code ~= nil then
            ngx.log(ngx.ERR, err_code, ':', err_msg)
        else
            ngx.log(ngx.ERR, body)
        end

        return nil, 'DeleteFileError', 'response status:' .. tostring(resp.status)
    end

    return nil, nil,nil
end

return _M
