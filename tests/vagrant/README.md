# Vagrant

## Install Vagrant

```bash
brew cask install vagrant
```

## Install VirtualBox 6.0

```bash
brew cask install https://raw.githubusercontent.com/Homebrew/homebrew-cask/7e703e0466a463fe26ab4e253e28baa9c20d5f36/Casks/virtualbox.rb
```

## Change vagrant permissions

```bash
sudo chown -R devin: /opt/vagrant/embedded/gems/2.2.6/gems/vagrant-2.2.6
```

## Run Vagrant

```bash
vagrant up
```

## Remove VMs

```bash
vagrant destroy -f
```
