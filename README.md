# lua-resty-oss
阿里云oss lua sdk，基于openresty, fork [362228416/lua-resty-oss](https://github.com/362228416/lua-resty-oss)

使用方法
```lua

local oss = require "resty.oss.oss"

local accessKey	  =   "your accessKey";
local secretKey	  =   "your secretKey";
local bucket      =   "your bucket",

local opts = {
    endpoint = 'your oss endpoint',
    timeout  = 'request timeout',
}

local key_name = 'your key name'

local client, err_code, err_msg = resty_oss.new(bucket, ak, sk, opts)
if err_code == nil then
    local _
     _, err_code, err_msg = client:delete_object(key_name)
end

if err_code ~= nil then
    ngx.log(ngx.ERR, to_str('delete ali file error. key_name:',
        key_name, ', err_code:', err_code, ', err_msg:', err_msg))

    return nil, 'DeleteAliError', err_msg
end

```

上面的例子是直接上传文件并指定内容，文件类型，文件名

文件上传模块可以用[lua-resty-upload](https://github.com/openresty/lua-resty-upload)来处理


## 已实现方法

* delete_object     删除文件

## TODO
完整实现所有api，参考[阿里云OSS API文档](http://doc.oss.aliyuncs.com/)

基本功能是没有问题的，欢迎使用
