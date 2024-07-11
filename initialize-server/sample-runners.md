# Run commands

The `configure_system.sh` file should alredy be copied to the VM. Most likely in a directory called `~/initialize-server`.

Make sure `configure_system.sh` is executable. If needed run the following:

```sh
chmod +x ./configure_system.sh
```

## KMaster command

```sh
sudo ./configure_system.sh 192.168.1.100 192.168.1.100 kmaster
```

## KWorker01

```sh
sudo ./configure_system.sh 192.168.1.100 192.168.1.110 kworker01
```

## KWroker02

```sh
sudo ./configure_system.sh 192.168.1.100 192.168.1.111 kworker02
```
