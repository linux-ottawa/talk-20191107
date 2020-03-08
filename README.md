# Linux-Ottawa March 5. 2020

## Notes and files for the talk

This is for the Linux-Ottawa talk on setting up your laptop/desktop/whatever system. In my case, I have a couple of Dell XPS systems, a PinebookPro, an older HP business laptop, two macbook pros, and several versions of Raspberry Pi to set up. While this is not all of my environment, it does cover a few things so that the ease of configuration does bcome apparent. I also have a server system that I have not powered on in a while and if I get a chance to do so, I'll run this against that system as well. Not all of this is going to be achievable, but most will.

## First off, this is going to feature Arch Linux

Why? Simply because it starts out at a command line after booting and you build a custom environment from there. There are many other distros, but I found a wealth of documentation on doing this and on the oddities of much hardware on the Arch wiki, so I'm happy to run with a well documented distro. Sometimes it is too well documented and you end up with conflicting information.

We are also going to assume a new install. Perhaps a future talk will cover recivering from a crash/dead HDD, etc. Last month's talk should have been an eye-opener for some people. I will be using my XPS 13 for this talk.

Finally, we are going to assume that we are using UEFI instead of the legacy BIOS on the Dell laptop.

### Sequence of what we are doing.

. Download the current Arch image
. Burn it to bootable media
. Boot from the newly created media
. Get network connectivity (kind of important)
. Make the font readable
. Start sshd
. Set a root password for connectivity
. Download the install script from GitHub (or whever you are keeping it)
. Run the script, answer some questions, wait for it to finish.
. Reboot
. Log in, start sshd again and remotely run the ansible playbook to finish setting up your system.

The first three items are not being covered, as that is installing Arch basics.
Once booted:
- Enable networking
- Download the setup script
- Check the script has things set up as expected
- Make the script executable
- Run the script

```
wifi-menu
curl -O https://raw.githubusercontent.com/linux-ottawa/talk-20191107/master/setup-xps.sh
less setup-xps.sh
chmod 755 setup-xps.sh
./setup-xps
```

You should get a full Arch install along with Ansible and git. 

Once that is up and running, you will need the Ansible playbook to take care of all of the "other things"


Gotcha's

Dell "Killer" chips
- The installer has full support, the reboot after install appears to have it, but it doesn't work initially. NetworkManager seems to fix whatever was wrong.

I decided to replace the chip with an Intel one for support purposes. It appears to be working properly.
