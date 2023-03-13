local json = require 'json'
local log = require 'log'
local HiveOn = {}
HiveOn.__index = HiveOn

HiveOn.ENDPOINT = 'https://hiveon.net/api/v1/'

function HiveOn.new()
    local obj = {}
    setmetatable(obj, HiveOn)
    obj:clear()
    return obj
end
function HiveOn:clear()
    self.http = nil
end
function HiveOn:use_http_client(http_client)
    self.http = http_client
end

function HiveOn:_http_client_check()
    if (self.http == nil) then
        self.http =
            require('http.client').new(
            {
                max_connections = 500
            }
        )
    end
end

-- {
--   "hashrate": "193276477",
--   "hashrate24h": "175579351",
--   "onlineWorkerCount": "1",
--   "sharesStatusStats": {
--     "lastShareDt": "2023-03-11T12:20:00Z",
--     "staleCount": "6",
--     "staleRate": 0.16982734220209453,
--     "validCount": "3527",
--     "validRate": 99.8301726577979
--   }
-- }
function HiveOn:Miner(coin, address)
    local query = self.ENDPOINT .. string.format('stats/miner/%s/%s', address, string.upper(coin))
    local r = self.http:request('GET', query)
    if (r.status ~= 200) then
        return
    end
    return json.decode(r.body)
end

-- {
--     "workers": {
--       "rig3water_andrey": {
--         "hashrate": "171801313",
--         "hashrate24h": "175629062",
--         "online": true,
--         "sharesStatusStats": {
--           "lastShareDt": "2023-03-11T12:20:00Z",
--           "staleCount": "6",
--           "staleRate": 0.16982734220209453,
--           "validCount": "3527",
--           "validRate": 99.8301726577979
--         }
--       }
--     }
--   }
function HiveOn:Workers(coin, address)
    local query = self.ENDPOINT .. string.format('stats/miner/%s/%s/workers', address, string.upper(coin))
    local r = self.http:request('GET', query)
    return json.decode(r.body)
end

-- {"items":
--     [
--     {"count":"1","timestamp":"2023-03-11T12:50:00Z"},
--     {"count":"1","timestamp":"2023-03-11T12:40:00Z"},
--      ....
--     ]
-- }
function HiveOn:WorkersCount(coin, address, window, limit, offset)
    local query =
        self.ENDPOINT ..
        string.format(
            'stats/workers-count?minerAddress=%s&coin=%s&window=%s&limit=%d&offset=&d',
            address,
            string.upper(coin),
            window or '10m',
            limit or 144,
            offset or 0
        )
    local r = self.http:request('GET', query)
    return json.decode(r.body)
end

-- {
--     "earningStats": [
--       {
--         "meanReward": 2.77643014,
--         "reward": 2.21279984,
--         "timestamp": "2023-03-11T10:00:00Z"
--       },
--       {
--         "meanReward": 2.8009358,
--         "reward": 2.51695524,
--         "timestamp": "2023-03-11T09:00:00Z"
--       },
--      ...
--     ],
--     "expectedReward24H": 61.07887776,
--     "expectedRewardWeek": 427.55214432,
--     "pendingPayouts": [],
--     "succeedPayouts": [
--       {
--         "amount": 66.37721993,
--         "approveUUID": "782072ec-6c2e-4700-bf83-0372dd9ce8c7",
--         "coin": "RVN",
--         "createdAt": "2023-03-11T07:11:39.741346Z",
--         "meta": "{\"req_data\": {\"coin\": \"RVN\", \"amount\": 6637721993, \"end_dt\": \"2023-03-11T06:30:00Z\", \"start_dt\": \"2023-03-10T06:30:00Z\", \"approveUUID\": \"782072ec-6c2e-4700-bf83-0372dd9ce8c7\", \"user_address\": \"RC9oamLHuRXtQGp98mmQeJj4FKjmoAcLjn\", \"decimal_places\": 8, \"precise_amount\": \"663772199300000000\", \"idempotency_key\": \"63a2c88b-9047-553a-be6a-b6d9dc07db47\"}, \"tx_receipt\": {\"block_hash\": \"0000000000005dea743c0fda66847d17f5b07eecdf933405b087ba14ec6b0b55\"}}",
--         "payoutDirection": "MAIN_NET",
--         "status": "succeed",
--         "txHash": "35dbe613d23f49e1967d27422878818be5576c48d1c855820a57aee4e50ceb10",
--         "txMeta": "{\"nonce\":\"123\",\"gas\":0,\"gasUsed\":0,\"gasPrice\":0,\"effectiveGasPrice\":0,\"blockHash\":\"0000000000005dea743c0fda66847d17f5b07eecdf933405b087ba14ec6b0b55\",\"txHash\":\"35dbe613d23f49e1967d27422878818be5576c48d1c855820a57aee4e50ceb10\"}",
--         "type": "miner_reward",
--         "updatedAt": "2023-03-11T08:26:12.003366Z",
--         "userAddress": "RC9oamLHuRXtQGp98mmQeJj4FKjmoAcLjn",
--         "uuid": "63a2c88b-9047-553a-be6a-b6d9dc07db47"
--       }
--     ],
--     "totalPaid": 177.53300565,
--     "totalUnpaid": 13.30708806,
--     "walletStatus": "active"
--   }
function HiveOn:BillingACC(coin, address)
    local query = self.ENDPOINT .. string.format('stats/miner/%s/%s/billing-acc', address, string.upper(coin))
    local r = self.http:request('GET', query)
    return json.decode(r.body)
end

-- {"items":
--     [
--         {"lastShareDt":"2023-03-11T13:00:00Z","timestamp":"2023-03-11T13:00:00Z","validCount":"31","validRate":100},
--         {"lastShareDt":"2023-03-11T12:50:00Z","staleCount":"1","staleRate":3.5714285714285716,"timestamp":"2023-03-11T12:50:00Z","validCount":"27","validRate":96.42857142857143},
--         ...
--     ]
-- }
function HiveOn:Shares(coin, address, window, limit, offset, worker)
    local query =
        self.ENDPOINT ..
        string.format(
            'stats/shares?minerAddress=%s&coin=%s&window=%s&limit=%d&offset=&d&worker=%s',
            address,
            string.upper(coin),
            window or '10m',
            limit or 144,
            offset or 0,
            worker or ''
        )
    local r = self.http:request('GET', query)
    return json.decode(r.body)
end
-- {"items":
--     [
--     {"hashrate":"221910029","meanHashrate":"176971259","reportedHashrate":"0","timestamp":"2023-03-11T13:00:00Z"},
--     {"hashrate":"200434865","meanHashrate":"176374727","reportedHashrate":"0","timestamp":"2023-03-11T12:50:00Z"},
--        ...
--     ]
-- }
function HiveOn:Hashrates(coin, address, window, limit, offset, worker)
    local query =
        self.ENDPOINT ..
        string.format(
            'stats/hashrates?minerAddress=%s&coin=%s&window=%s&limit=%d&offset=&d&worker=%s',
            address,
            string.upper(coin),
            window or '10m',
            limit or 144,
            offset or 0,
            worker or ''
        )
    local r = self.http:request('GET', query)
    return json.decode(r.body)
end

function HiveOn:getMetrics(coin, address)
    local m = {}
    local resp_miner = self:Miner(coin, address)
    if (resp_miner == nil or resp_miner['hashrate24h'] == nil) then
        return
    end
    local resp_workers = self:Workers(coin, address)
    local resp_billing = self:BillingACC(coin, address)
    local offline_worker_count = resp_miner['offlineWorkerCount'] or 0

    local online_worker_count = resp_miner['onlineWorkerCount'] or 0
    m['mining_pool_hashrate'] = resp_miner['hashrate']
    m['mining_pool_hashrate_avg'] = resp_miner['hashrate24h']
    m['mining_pool_workers_online'] = online_worker_count
    m['mining_pool_workers_offline'] = offline_worker_count
    m['mining_pool_workers_total'] = #resp_workers['workers']
    m['mining_pool_shares_valid'] = resp_miner['sharesStatusStats']['validCount']
    m['mining_pool_shares_invalid'] = resp_miner['sharesStatusStats']['staleCount']
    m['mining_pool_shares_stale'] = resp_miner['sharesStatusStats']['staleCount']
    m['mining_pool_shares_stale_p'] = resp_miner['sharesStatusStats']['staleRate'] or 0
    m['mining_pool_shares_last'] = 0
    -- resp_miner['sharesStatusStats']['lastShareDt']
    m['mining_pool_balance'] = resp_billing['totalUnpaid']
    m['mining_pool_paid_total'] = resp_billing['totalPaid']
    m['mining_pool_24hreward'] = resp_billing['succeedPayouts'][1]['amount']
    --

    m['mining_pool_worker_hashrate'] = {}
    m['mining_pool_worker_hashrate_avg'] = {}
    m['mining_pool_worker_online'] = {}
    m['mining_pool_worker_shares_valid'] = {}
    m['mining_pool_worker_shares_invalid'] = {}
    m['mining_pool_worker_shares_stale'] = {}
    m['mining_pool_worker_shares_stale_p'] = {}
    for worker_name, worker_stats in pairs(resp_workers['workers']) do
        local w_shares_stats = worker_stats['sharesStatusStats']

        table.insert(m['mining_pool_worker_hashrate'], {worker = worker_name, value = (worker_stats['hashrate'] or 0)})

        table.insert(
            m['mining_pool_worker_hashrate_avg'],
            {worker = worker_name, value = (worker_stats['hashrate24h'] or 0)}
        )
        table.insert(
            m['mining_pool_worker_online'],
            {worker = worker_name, value = worker_stats['online'] == true and 1 or 0}
        )
        table.insert(
            m['mining_pool_worker_shares_valid'],
            {worker = worker_name, value = w_shares_stats['validCount'] or 0}
        )
        table.insert(
            m['mining_pool_worker_shares_invalid'],
            {worker = worker_name, value = w_shares_stats['invalidCount'] or 0}
        )
        table.insert(
            m['mining_pool_worker_shares_stale'],
            {worker = worker_name, value = w_shares_stats['staleCount'] or 0}
        )
        table.insert(
            m['mining_pool_worker_shares_stale_p'],
            {
                worker = worker_name,
                value = ((w_shares_stats['staleCount'] or 0) / w_shares_stats['validCount'] * 100) or 0
            }
        )
    end
    return m
end

return HiveOn
