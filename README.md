# FafCn

## Prerequisites

### Install asdf 

The easiest way to install asdf is from go: download one of go binary from `https://go.dev/dl/`.

```sh 
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
echo 'export GOPATH=$HOME/go' >> ~/.profile
source ~/.profile
go version
go install github.com/asdf-vm/asdf/cmd/asdf@v0.17.0

# expose go bin path to terminal
echo 'export PATH="$PATH:$HOME/go/bin"' >> ~/.bashrc
# expose asdf installed code (add to bashrc to make it permanent)
export PATH="$HOME/.asdf/shims:$PATH"
source ~/.bashrc
```


### Install Elixir and Erlang 

```sh 
asdf --version
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git

asdf list all erlang 
asdf list all elixir

asdf install erlang latest
asdf install elixir 1.20.0-rc.1-otp-28

# expose asdf installed code (add to bashrc to make it permanent)
export PATH="$HOME/.asdf/shims:$PATH"

asdf list erlang 
asdf list elixir 

asdf set erlang 28.3.1
asdf set elixir 1.20.0-rc.1-otp-28

# check current erlang and elixir setting
erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'
elixir -v
```

### Install latest Phoenix

```sh
# Install the latest Phoenix installer
mix archive.install hex phx_new
```

## Get Start

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix

