# Linux-Ottawa March 5. 2020

## Notes and files for the talk

This is for the Linux-Ottawa talk on setting up your laptop/desktop/whatever system. In my case, I have a couple of Dell XPS systems, a PinebookPro, and a Raspberry Pi to set up. While this is not all of my environment, it does cover a few things so that the ease of configuration does bcome apparent. I also have a server system that I have not powered on in a while and if I get a chance to do so, I'll run this against that system as well.

## First off, this is going to feature Arch Linux

Why? Simply because it starts out at a command line and you build a custom environment from there. There are many other ones like it, but I found a wealth of documentation on doing this and on the oddities of much hardware on the Arch wiki, so I'm happy to run with a well documented distro.

We are also going to assume a new install. Perhaps a future talk will cover recivering from a crash/dead HDD, etc. Last month's talk should have been an eye-opener for some people.

Finally, we are going to assume that we are using UEFI for the Dell laptops at least

### Gettign started.

1. Download the current Arch image
2. Burn it to bootable media
3. Boot from it
4. Get network connectivity
5. Download the install script
6. Run the script, answer some questions, wait for it to finish.
7. Reboot
8. Log in and run the ansible playbook to finish setting up your syetem.

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
