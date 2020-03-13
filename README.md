![Devbook logo](https://0x0.st/spdA.png)
---
<p align="right">
  <a href="https://travis-ci.org/Luciditi/devbook"><img src="https://travis-ci.org/Luciditi/devbook.svg?branch=mk1"></a>
</p>
A developer workstation provisioner for macOS powered by Ansible.

## Installation

- **Dependencies:** `sh <(curl -sL jig.io/devbook-boot)` for XCode CLI tools & Ansible 
- **Installer:**
  - **Full (~1 hour):** `sh <(curl -sL jig.io/devbook-init)`
  - **Partial (~0.5 hour):** `sh <(curl -sL jig.io/devbook-init) jig.io/devbook-config-mini`
  - <sub>(or clone the repo & run `./bootstrap.sh` & `./init.sh` if you don't trush me)</sub>

## Toolchain
Devbook contains the following features (not exhaustive, see [`default.config.yml`](default.config.yml) for the full manifest):

- Version-controlled dotfiles (e.g. defaulted to [`Luciditi/dotfiles`](https://github.com/Luciditi/dotfiles))
- Version-controlled private dotfiles (e.g. sensitive info like SSH hosts, e.g. [`Luciditi/dotfiles-example`](https://github.com/Luciditi/dotfiles-example))
- Custom [SH](https://github.com/Luciditi/dotfiles/tree/master/.sh)/[ZSH](https://github.com/Luciditi/dotfiles/tree/master/.zsh) functions, [scripts](https://github.com/Luciditi/dotfiles/tree/master/.bin), completions, & aliases.
- Git [hook templates](https://github.com/Luciditi/dotfiles/tree/master/.git_template/template/hooks)
- macOS [configuration](https://github.com/Luciditi/dotfiles/blob/master/.macos)
- [Vim](https://github.com/vim/vim)/[Vundle](https://github.com/VundleVim/Vundle.vim) [Setup](https://github.com/Luciditi/dotfiles/blob/master/.vimrc)
- Various CLI tools via [Homebrew](https://github.com/Homebrew/brew).
- Various macOS applications via [Homebrew cask](https://github.com/Homebrew/homebrew-cask) & [Mas](https://github.com/mas-cli/mas) (App Store)
- Various packages for Go, PHP, Ruby, Node, & Python via their respective dependency managers.
- Customized [ZSH](http://www.zsh.org/) environment via [Antigen](https://github.com/zsh-users/antigen), [OMZ](https://github.com/robbyrussell/oh-my-zsh/), [PL9K](https://github.com/bhilburn/powerlevel9k)

## Configuration
There are 3 config areas: [override](#override), [devbook extension](#devbook-extension), & [task/role](#taskrole).

### Override
If you want to set your own custom config it's easy to override defaults. Put a `config.yml` file into the Devbook repo and its values will be used instead of the defaults. Alternatively, adding a HTTP url param to `./init.sh` (or its curlsh equivalent) will retrieve the config file from the URL and use it as the `config.yml`.

#### Examples
  - Override the `dotfiles_*` values to specify the dotfiles repo & files you want to mount into your `$HOME` dir.
  - Override the `prv_*` values to specify the SSH-key protected repo & sensitive files you want to mount into your `$HOME` dir.
  - Specify the Homebrew packages/casks in `homebrew_installed_packages`/`homebrew_cask_apps`.
  - Specify custom `mas_*` values to customize your own App Store config.
  - Add various packages specified for the `extra-packages` task.
  - Add your own custom .macos file for your personal macOS system/app preferences.

### Devbook Extension
Devbook has a few other extensible bits. 

#### Extensions
Upon completion, Devbook will look inside `$HOME/.devbook/` for subdirs that have `init.sh` for execution.
If you're familar with Ansible & Shell scripting, you can provide your own custom Ansible playbooks/roles & scripts needed to provision personal projects, client projects, or various role-based tools you need (e.g. you might need to provision a suite of design tools or DB developer tools).

To get started make sure `prv_repo` (or `dotfiles_repo`) has a mounted `.devbook` dir and subdirs with `init.sh`. 
- **EXAMPLE:** [`Luciditi/dotfiles-example`](https://github.com/Luciditi/dotfiles-example).
- **Template Creator:** You can also run `./dir.sh $MY_DIR` (or `sh <(curl -sL jig.io/devbook-dir) $MY_DIR`) to grab the [`Luciditi/devbook-config` starter template](https://github.com/Luciditi/devbook-config) and drop it into `.devbook/$MY_DIR`.

#### Custom Notes
If you have any post-provision steps that might require manual steps (e.g. enabling FileVault, manual app install, etc.) you can drop them into `NOTES.md`. After Devbook completes, it will print the contents out to the console after installation.

### Task/Role
If you're familar with Ansible's tag system, you can tell Devbook to skip certain tags associated with tasks/roles in a `.devbook.skip` file (inside in the repo directory). The file contains a line-delimited list of tags to skip (run `ansible-playbook main.yml --list-tags` to see the list of Devbook tags.

## Help/FAQ

> The best laid schemes o' mice an' men...

I've found macOS provisioning prone to all kinds of problems (various types of app installers, a huge selection of open source tools, a consumer-oriented OS that's designed to abstract the technical bits). Don't be suprised at hiccups (I'm looking at you `java8` Homebrew). 

Luckily, Ansible is a great tool here. it's designed to be idempotent; you can run it over-and-over again without breaking things. 

As Devbook runs through its playbook, it will tag its progress (in `.devbook.tags`). Running `./init.sh` after failure will skip completed tags and resume where it left off. If you provision a large tool chain expect: failures in package downloads and other unforseen problems. 

If you hit any other issues, post it [over here](https://github.com/luciditi//devbook/issues).

## Development/Testing
A shout out to geerlingguy & mathiasbynens which I based my work on. I pulled much cool stuff from these repos: [`geerlingguy/mac-dev-playbook`](https://github.com/geerlingguy/mac-dev-playbook) & [`mathiasbynens/dotfiles`](https://github.com/mathiasbynens/dotfiles)

If you like to do testing, this [repo](https://github.com/geerlingguy/macos-virtualbox-vm) is good for bootstrapping your own VirtualBox macOS image so you don't trash your current configuration.
