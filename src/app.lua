#!/usr/bin/env tarantool

package.path = package.path .. ';../?.lua'
local fiber = require('fiber')
local log = require('log')
local metrics = require('metrics')
local json = require 'json'
local http =
    require('http.client').new(
    {
        max_connections = 500
    }
)

local hiveon_api = require('hiveon-pool-client').new()
local TwoMinersApi = require('2miners-pool-client').new()
local SUPPORTED_POOLS = {}
SUPPORTED_POOLS['hiveon'] = true
SUPPORTED_POOLS['2miners'] = true

local env_POOLS = os.getenv('POOLS')
local env_UPDATE_INTERVAL = os.getenv('UPDATE_INTERVAL') or 60
local POOLS = {}
for pool_string in string.gmatch(env_POOLS, '([^,]+)') do
    local pool, coin, address = string.match(pool_string, '(%w+):(%w+):(%w+)')
    if (SUPPORTED_POOLS[string.lower(pool)] ~= nil) then
        table.insert(
            POOLS,
            {
                pool = string.lower(pool),
                coin = coin,
                address = address
            }
        )
    else
        log.error('Unsupported pool %s in "%s"', string.lower(pool), pool_string)
    end
end

-- Init Prometheus Exporter
local httpd = require('http.server')
local http_handler = require('metrics.plugins.prometheus').collect_http
httpd.new('0.0.0.0', 52080, {log_requests = false, log_errors = true}):route(
    {
        path = '/metrics'
    },
    function(...)
        return http_handler(...)
    end
):route(
    {path = '/health'},
    function()
        return {
            status = 200,
            body = 'OK'
        }
    end
):start()

local _metrics = {
    'mining_pool_hashrate',
    'mining_pool_hashrate_avg',
    'mining_pool_workers',
    --
    'mining_pool_worker_hashrate',
    'mining_pool_worker_hashrate_avg',
    'mining_pool_worker_online',
    'mining_pool_worker_shares_valid',
    'mining_pool_worker_shares_invalid',
    'mining_pool_worker_shares_stale',
    'mining_pool_worker_shares_stale_p',
    --
    'mining_pool_workers_online',
    'mining_pool_workers_offline',
    'mining_pool_workers_total',
    'mining_pool_shares_valid',
    'mining_pool_shares_invalid',
    'mining_pool_shares_stale',
    'mining_pool_shares_stale_p',
    'mining_pool_shares_last',
    'mining_pool_balance',
    'mining_pool_paid_total',
    'mining_pool_24hreward'
}

local function labelPairsTreater(labelsto, labelsfrom)
    local new = {}
    local value_new
    for key, value in pairs(labelsto) do
        if (key ~= 'value') then
            new[key] = value
        else
            value_new = value
        end
    end
    for key, value in pairs(labelsfrom) do
        new[key] = value
    end
    -- labelsto = new
    return value_new, new
end

local METRICS = {}
for i = 1, #_metrics, 1 do
    METRICS[_metrics[i]] = metrics.gauge(_metrics[i])
end

TwoMinersApi:use_http_client(http)
hiveon_api:use_http_client(http)

while true do
    for i, p in ipairs(POOLS) do
        local raw_metrics
        if p.pool == '2miners' then
            raw_metrics = TwoMinersApi:getMetrics(p.coin, p.address)
        end
        if p.pool == 'hiveon' then
            raw_metrics = hiveon_api:getMetrics(p.coin, p.address)
        end
        if (raw_metrics ~= nil) then
            for metric_name, value in pairs(raw_metrics) do
                local labels = {pool = p.pool, coin = p.coin, address = p.address}
                if (type(value) == 'table') then
                    for index, __value in ipairs(value) do
                        local value_new, labels_new = labelPairsTreater(__value, labels)
                        METRICS[metric_name]:set(value_new, labels_new)
                    end
                else
                    METRICS[metric_name]:set(value, labels)
                end
            end
        end
    end
    fiber.sleep(env_UPDATE_INTERVAL)
end
