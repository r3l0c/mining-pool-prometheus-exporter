local json = require 'json'
local TwoMiners = {}
TwoMiners.__index = TwoMiners

TwoMiners._ENDPOINT = 'https://%s.2miners.com/api/'

function TwoMiners:ENDPOINT(coin)
    return string.format(self._ENDPOINT, coin)
end

TwoMiners._BALANCE_DIVIDER = {
    _ = 8,
    rvn = 8,
    etc = 9,
    beam = 8
}

function TwoMiners.new()
    local obj = {}
    setmetatable(obj, TwoMiners)
    obj:clear()
    return obj
end
function TwoMiners:clear()
    self.http = nil
end
function TwoMiners:use_http_client(http_client)
    self.http = http_client
end

function TwoMiners:_http_client_check()
    if (self.http == nil) then
        self.http =
            require('http.client').new(
            {
                max_connections = 500
            }
        )
    end
end

function TwoMiners:balance_calc(value, coin)
    return value / 10 ^ (self._BALANCE_DIVIDER[coin] or self._BALANCE_DIVIDER['_'])
end

-- {
--     "currentHashrate": 0,
--     "currentLuck": "string",
--     "hashrate": 0,
--     "pageSize": 0,
--     "payments": [
--       {
--         "amount": 0,
--         "timestamp": 0,
--         "tx": "string"
--       }
--     ],
--     "paymentsTotal": 0,
--     "rewards": [
--       {
--         "blockheight": 0,
--         "timestamp": 0,
--         "blockhash": "string",
--         "reward": 0,
--         "percent": 0,
--         "immature": false,
--         "currentLuck": 0,
--         "uncle": false
--       }
--     ],
--     "roundShares": 0,
--     "shares": [
--       "string"
--     ],
--     "stats": {
--       "balance": 0,
--       "blocksFound": 0,
--       "immature": 0,
--       "lastShare": 0,
--       "paid": 0,
--       "pending": false
--     },
--     "sumrewards": [
--       {
--         "inverval": 0,
--         "reward": 0,
--         "numreward": 0,
--         "name": "string",
--         "offset": 0
--       }
--     ],
--     "workers": {
--       "workerGroup": {
--         "lastBeat": "string",
--         "hr": 0,
--         "offline": false,
--         "hr2": 0
--       }
--     },
--     "workersOffline": 0,
--     "workersOnline": 0,
--     "workersTotal": 0,
--     "24hreward": 0,
--     "24hnumreward": 0
--   }
function TwoMiners:Accounts(coin, address)
    local query = self:ENDPOINT(coin) .. string.format('accounts/%s', address)
    self:_http_client_check()
    local r = self.http:request('GET', query)
    if (r.status == 200) then
        return json.decode(r.body)
    else
        return
    end
end

function TwoMiners:getMetrics(coin, address)
    local m = {}
    local resp = self:Accounts(coin, address)
    if (resp == nil) then
        return
    end
    m['mining_pool_hashrate'] = resp['currentHashrate']
    m['mining_pool_hashrate_avg'] = resp['hashrate']
    m['mining_pool_workers_online'] = resp['workersOnline']
    m['mining_pool_workers_offline'] = resp['workersOffline']
    m['mining_pool_workers_total'] = resp['workersTotal']
    m['mining_pool_shares_valid'] = resp['sharesValid']
    m['mining_pool_shares_invalid'] = resp['sharesInvalid']
    m['mining_pool_shares_stale'] = resp['sharesStale']
    m['mining_pool_shares_stale_p'] = (resp['sharesStale'] / resp['sharesValid'] * 100) or 0
    m['mining_pool_shares_last'] = resp['stats']['lastShare']
    m['mining_pool_balance'] = self:balance_calc(resp['stats']['balance'], coin)
    m['mining_pool_paid_total'] = self:balance_calc(resp['stats']['paid'], coin)
    m['mining_pool_24hreward'] = self:balance_calc(resp['24hreward'], coin)
    --
    --
    m['mining_pool_worker_hashrate'] = {}
    m['mining_pool_worker_hashrate_avg'] = {}
    m['mining_pool_worker_online'] = {}
    m['mining_pool_worker_shares_valid'] = {}
    m['mining_pool_worker_shares_invalid'] = {}
    m['mining_pool_worker_shares_stale'] = {}
    m['mining_pool_worker_shares_stale_p'] = {}
    for worker_name, worker_stats in pairs(resp['workers']) do
        table.insert(m['mining_pool_worker_hashrate'], {worker = worker_name, value = worker_stats['hr'] or 0})
        table.insert(m['mining_pool_worker_hashrate_avg'], {worker = worker_name, value = worker_stats['hr2'] or 0})
        table.insert(
            m['mining_pool_worker_online'],
            {worker = worker_name, value = worker_stats['offline'] == false and 1 or 0}
        )
        table.insert(
            m['mining_pool_worker_shares_valid'],
            {worker = worker_name, value = worker_stats['sharesValid'] or 0}
        )
        table.insert(
            m['mining_pool_worker_shares_invalid'],
            {worker = worker_name, value = worker_stats['sharesInvalid'] or 0}
        )
        table.insert(
            m['mining_pool_worker_shares_stale'],
            {worker = worker_name, value = worker_stats['sharesStale'] or 0}
        )
        table.insert(
            m['mining_pool_worker_shares_stale_p'],
            {
                worker = worker_name,
                value = ((worker_stats['sharesStale'] or 0) / worker_stats['sharesValid'] * 100) or 0
            }
        )
    end
    return m
end
return TwoMiners
