#!/usr/bin/env bash

cd /tmp

wget https://dl.google.com/go/go1.13.10.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.13.10.linux-amd64.tar.gz

echo "" >> ~/.bashrc
echo "export GOPATH=\${HOME}/go" >> ~/.bashrc
echo "export PATH=\"\${PATH}:/usr/local/go/bin:${HOME}/go/bin\"" >> ~/.bashrc

apt install pigz parallel aria2
