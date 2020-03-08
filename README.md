# Linux-Ottawa March 11, 2020

## Notes and files for the talk

This is for the Linux-Ottawa talk on setting up your laptop/desktop/whatever system. In my case, I have a variety of systems that include Dell XPS, HP Elitebook, Macbook Pro, Intel Nuc, Raspberry Pi, etc. as well as a sampling of many generations of hardware. I'm going to stick to the XPS for this talk, but the information will apply to pretty much any modern system (meaning it can net boot and run Linux). I also have a server system that was used for gaming that I have not powered on in a while and I am going to try it against that system as well. 

It does go over things to keep in mind and show where you can make semi-intelligent choices on system installation. There has also been some evolution since I first mentioned doing this talk, so the shell script portion will no longer be a "production" item. It can be done with ansible as well, right after the initial boot.  Not all of this is going to be achievable, but most will.

## First off, this is going to feature Arch Linux

Why? Simply because it starts out at a command line after booting and you build a custom environment from there. There are many other distros, but there is a wealth of documentation on doing this and on the oddities of much hardware on the Arch wiki, so I'm happy to run with a well documented distro. Sometimes it is too well documented and you end up with potentially conflicting information.

We are also going to assume a new install, so the initial steps will be performed as well as the follow-up portion. You can use the subsequent playbook against a built system and it shouldn't do anything it is not supposed to do.

Perhaps a future talk will go through the actual install so that you can see how it all fits together. I will continue to use the XPS for now, as I'm still working on what I want installed on it, so rebuilding is a common task right now. I'm a little rusty with Linux on laptops, as I have been using a Macbook for years and my work laptop is Windows based. The details of some of the hardware configurations are not something I am up on and doing the install this way means I have a way to rebuild without having to refer to notes all of the time.

Finally, we are going to assume that we are using UEFI instead of the legacy BIOS on the XPS.

### Ansible Install Sequence

There is great information on the arch webite and this follows that process, but does it with a mostly automated approach.

#### Part 1 - Preparation
. Download the current Arch image
. Burn it to bootable media
. Boot from the newly created media

#### Part 2 - Initial Steps
. Create a root password
. Get a network address and know what it is
. Allow root logins (temporary and only affects the installer session)
. Enable sshd

#### Part 3 - Perform initial install
. Connect from remote system
.
.
. Reboot

#### Part 4 - Perform standard install
. 

You should now have a proper system, already to use with your account setup and all of your software available. Additional playbooks can be crafted that will do specific software installations and configurations, but that is all in your hands.



Remove items below here later, no longer the correct information.

)Get network connectivity (kind of important)
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
