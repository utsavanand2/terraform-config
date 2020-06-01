#cloud-config
ssh_authorized_keys:
    - ${ssh_key}

package_update: true

packages:
    - runc

runcmd:
- curl -sLSf https://github.com/containerd/containerd/releases/download/v1.3.4/containerd-1.3.4.linux-amd64.tar.gz -o /tmp/containerd.tar.gz && tar -xvf /tmp/containerd.tar.gz -C /usr/local/bin/ --strip-components=1
- curl -sLSf https://raw.githubusercontent.com/containerd/containerd/v1.3.4/containerd.service | tee /etc/systemd/system/containerd.service
- systemctl daemon-reload && systemctl start containerd
- /sbin/sysctl -w net.ipv4.conf.all.forwarding=1
- mkdir -p /opt/cni/bin
- curl -sLSf https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz -o /tmp/cni-plugins-linux-amd64.tgz && tar -xvf /tmp/cni-plugins-linux-amd64.tgz -C /opt/cni/bin
- mkdir -p /go/src/github.com/openfaas
- mkdir -p /var/lib/faasd/secrets
- echo ${gateway_password} > /var/lib/faasd/secrets/basic-auth-password
- echo admin > /var/lib/faasd/secrets/basic-auth-user
- cd /go/src/github.com/openfaas/ && git clone https://github.com/openfaas/faasd
- curl -sLSf "https://github.com/openfaas/faasd/releases/download/0.8.3/faasd -o "/usr/local/bin/faasd" && chmod a+x "/usr/local/bin/faasd"
- cd /go/src/github.com/openfaas/faasd/ && /usr/local/bin/faasd install
- systemctl status -l containerd --no-pager
- journalctl -u faasd-provider --no-pager
- systemctl status -l faasd-provider --no-pager
- systemctl status -l faasd --no-pager
- curl -sLSf https://cli.openfaas.com | sh
- sleep 5 && journalctl -u faasd --no-pager
- cat /var/lib/faasd/secrets/basic-auth-password | /usr/local/bin/faas-cli login --password-stdin