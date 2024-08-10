# Networking

put `br0.networkthese` and `bridge-br0.netdev` files in `/etc/systemd/network/`

```sh
sudo cp br0.network /etc/systemd/network/

sudo cp bridge-br0.netdev /etc/systemd/network/
```

Check the network status

```sh
sudo systemctl status systemd-networkd
```

Start and enalbe
```sh
sudo systemctl start systemd-networkd

sudo systemctl eanble systemd-networkd
```

Restart the network

```sh
sudo systemctl restart systemd-networkd
```
