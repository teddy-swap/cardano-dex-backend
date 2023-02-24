# Running the badger with Docker Compose

It is possible to run both Cardano Node and the Badger using [docker-compose](https://docs.docker.com/compose)

Before launching the stack with docker compose, it is necessary to follow the same preparation of the `badger-volume` as
explained in the [README.md](./README.md).

Once the `badger-volume` is ready, we need to decide where to persist the ledger of the cardano blockchain. Let's assume 
we decide to persist it in `/var/lib/cardano/preview`, where `preview` is the network.

You can create such folder by issuing

`mkdir -p /var/lib/cardano/preview`

We are now ready to launch the stack of node+badger. We can do so by simply changing dir into `docker`
and then executing

```shell
docker compose -e CARDANO_NODE_DATA_FOLDER=/var/lib/cardano/preview -e BADGER_VOLUME=<path_to_badger_volume> -d up
```

It is possible to specify additional environmental variable:

* CARDANO_NODE_VERSION: the version of the cardano node image to use
* NETWORK: which network to use, it can be one of mainnet, preprod, preview
* TEDDY_SWAP_BADGER_VERSION: the version of the badger image to use
* 