Docker GlassFish
================

Build images locally with `latest` tag from `master`
----------------------------------------------------

It is not needed to clone this repo, they can be built directly from
*github.com* remote sources.

```
docker build \
-t miquelo/glassfish-4.1.1-debian:latest \
https://github.com/miquelo/docker-glassfish.git#master:image/glassfish-4.1.1-debian
```

```
docker build \
-t miquelo/glassfish-4.1.1-server:latest \
https://github.com/miquelo/docker-glassfish.git#master:image/glassfish-4.1.1-server
```

Run application server
----------------------

* With `glassfish` user public key output. Supposing public key target path is
  `$HOME/.glassfish/das-1.pem`:

  ```
  docker run -it \
  -v $HOME/.glassfish/das-1.pem:/usr/lib/glassfish4/.ssh/id_rsa.pub
  miquelo/glassfish-4.1.1-server:latest
  ```

* With password authentication. Supposing desired password is `12345678`:

  ```
  docker run -it \
  -e "GLASSFISH_SSH_PASSWORD=12345678" \
  miquelo/glassfish-4.1.1-server:latest
  ```

* With public key authentication. Mounting public key files on
  `/usr/lib/glassfish4/.ssh/authorized_keys.dir/` directory. Supposing you want
  to use `$HOME/.ssh/id_rsa.pub` and `$HOME/.glassfish/das-1.pem`:

  ```
  docker run -it \
  -v $HOME/.ssh/id_rsa.pub:/usr/lib/glassfish4/.ssh/authorized_keys.dir/mgmt.pem \
  -v $HOME/.glassfish/das-1.pem:/usr/lib/glassfish4/.ssh/authorized_keys.dir/das.pem \
  miquelo/glassfish-4.1.1-server:latest
  ```
  
Both authentication ways can be mixed.

Connectivity between MAC OSX and a Docker Machine container
-----------------------------------------------------------

It is explained [here](https://gist.github.com/makuk66/8380c901a9a620df7023).

1. Obtain Docker Machine IP. We will call it `docker-machine-ip`.

   ```
   docker-machine inspect default -f '{{ .Driver.IPAddress }}'
   ```

   It is used to be `192.168.99.100`.

2. Obtain Docker subnet. We will call it `docker-subnet`.

   Figuring that bridge on VM is called `docker0`.

   ```
   docker-machine ssh default ip -4 addr list docker0
   ```

   It is used to be `172.17.0.0/16`.

3. Add a route for that subnet.

   ```
   sudo route add <docker-subnet> <docker-machine-ip>
   ```

   It is used to be

   ```
   sudo route add 172.17.0.0/16 192.168.99.100
   ```

