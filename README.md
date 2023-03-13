# Prometheus mining pool exporter + grafana dashboard

[GitHub repo](https://github.com/r3l0c/mining-pool-prometheus-exporter)
[DockerHub image](https://hub.docker.com/r/r3l0c/mining-pools-prometheus-exporter)

### Why?

Comfortable monitoring of mining from several pools and several addresses. The dashboard supports filtering by pools, workers, addresses. You no longer need to go to the sites of different pools - you can watch everything in one place!Comfor

![Grafana dashboard](https://github.com/r3l0c/mining-pool-prometheus-exporter/blob/master/screenshot/scr1.png?raw=true)

#### Supported pools

* 2miners (official API)
* hiveon (api for pool dashboard)

#### Settings

Docker env POOLS - comma separated pool list, format: ```pool:coin:address,pool:coin:address,pool:coin:address,...```

Example: ```POOLS='2miners:rvn:RDhh3HpPa3rsE6B43VZkmKaQZ2Caif8vzW,hiveon:rvn:RDhh3HpPa3rsE6B43VZkmKaQZ2Caif8vzW'```

Docker env UPDATE_INTERVAL - update stats from pool interval

#### Docker run

```
sudo docker run --restart always --health-cmd='wget -O - -q 127.0.0.1:52080/health || exit 1' --health-timeout=3s --health-interval=30s -d -p 127.0.0.1:52080:52080 --name mining-pool-prometheus-exporter -e UPDATE_INTERVAL=120 -e POOLS='POOL1:COIN:ADDRESS,POOL1:COIN:ADDRESS2,POOL2:COIN:ADDRESS1, ....,' r3l0c/mining-pools-prometheus-exporter

```

#### docker-compose.yml

```
version: '3.3'
services:
    mining-pools-prometheus-exporter:
        restart: always
        ports:
            - '127.0.0.1:52080:52080'
        container_name: mining-pool-prometheus-exporter
        environment:
            - 'POOLS=POOL1:COIN:ADDRESS,POOL1:COIN:ADDRESS2,POOL2:COIN:ADDRESS1,....,'
            - 'UPDATE_INTERVAL=120'
        image: r3l0c/mining-pools-prometheus-exporter
```

#### prometheus.yml

```
  - job_name: mining_exporter
    scrape_interval: 120s
    static_configs:
     - targets: ['127.0.0.1:52080']
```

## Donate/Say thx

* Ethereum: 0x06d31b274655712e15F1f3a250eDC066c81F599D
* Ravecoin: RDhh3HpPa3rsE6B43VZkmKaQZ2Caif8vzW
