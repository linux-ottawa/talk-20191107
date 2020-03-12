# Linux-Ottawa March 11, 2020

## Notes and files for the talk

This is for the Linux-Ottawa talk on setting up your laptop/desktop/whatever system. In my case, I have a variety of systems that include Dell XPS, HP Elitebook, Macbook Pro, Intel Nuc, Raspberry Pi, etc. as well as a sampling of many generations of hardware. I'm going to stick to the XPS for this talk, but the information will apply to pretty much any modern system (meaning it can net boot, boot from USB, and run Linux). I also have a server system that was used for gaming that I have not powered on in a while and I am going to try it against that system as well. 

It does go over things to keep in mind and show where you can make semi-intelligent choices on system installation. There has also been some evolution since I first mentioned doing this talk, so the shell script portion will no longer be a "production" item. It can be done with ansible as well, right after the initial boot. Not all of this is going to be easily achievable, but most will.

I ran across many github :github: pages on doig this and they will be referenced at the end. One in particular stood out, as it took the Arch Linux install and made a playbook out of it. I will use that one as the basis of the talk.

## First off, this is going to feature Arch Linux

Why? Simply because it starts out at a command line after booting and you build a custom environment from there. There are many other distros, but there is a wealth of documentation on doing this and on the oddities of much hardware on the Arch wiki, so I'm happy to run with a well documented distro. Sometimes it is too well documented and you end up with potentially conflicting information.

We are also going to assume a new install, so the initial steps will be performed as well as the follow-up portion. You can use the subsequent playbook against a built system and it shouldn't do anything it is not supposed to do.

Perhaps a future talk will go through the actual install so that you can see how it all fits together. I will continue to use the XPS for now, as I'm still working on what I want installed on it, so rebuilding is a common task right now. I'm a little rusty with Linux on laptops, as I have been using a Macbook for years and my work laptop is Windows based. The details of some of the hardware configurations are not something I am up on and doing the install this way means I have a way to rebuild without having to refer to notes all of the time.

Finally, we are going to assume that we are using UEFI instead of the legacy BIOS on the XPS. This would probably be easier with traditional legacy BIOS, but there are issues with UEFI booting a number of Dell models post install due to grub issues and some "design decisions." Since I have a Dell, it would be nice to solve that and carry on.

### Ansible Install Sequence

There is great information on the Arch wiki and this process follows that process, but does it with a mostly automated approach. I'm going to be a little more detailed than the original reference material, as it is not immediately obvious what needs to be done to make this a successful project, particularly if you are new to Ansible, Arch, roles, tags, etc. 

#### Part 1 - Preparation
. Download the current Arch image
. Burn it to bootable media
. Boot from the newly created media

#### Part 2 - Initial Steps

On the target XPS laptop
. Create a root password
. Get a network address and know what it is
. Allow root logins (temporary and only affects the installer session)
. Enable sshd

#### Part 3 - Perform initial install
This is done from a system that already has Ansible installed and has a network connection.
. Connect from remote system to make sure it all works
. get the wired network name and the install disk name
. Edit necessary variable files to set these values
. Run the ansible-playbook with appropriate options. 
. When completed, it should automatically reboot.

#### Part 4 - Perform standard install
. You can now run the second Ansible playbook.

## Past here is still rough notes. Ignore at present.

You should now have a proper system, already to use with your account setup and all of your software available. Additional playbooks can be crafted that will do specific software installations and configurations, but that is all in your hands.

## Gotcha's, hurdles, etc.

First off, I am using my macbook for the remote system. MacOS does not have a utility that understands sha512 hashing. All of the standard methods (that are not mkpasswd) generate a DES password. Everything calls the system crypt library which has no such support. I spent some time with carious work arounds but they all failed.

Eventually I went with the expedient of running a linux docker image for the ability:

```
docker run -it --rm alpine mkpasswd -m sha-512 <password>
```

Sample run:

```
$ docker run -it --rm alpine mkpasswd -m sha512 do-not-use-me
$6$x56zEoknzw92nKi2$w5AISQ9jC0I1NxGFYvvvxZCd0MCy6m/sbDwMFHIaQoERQhwFoozAqeyjcaETIcmNaKSjLUJKW8WUAk4ogFw8R1
$

```

Initial commands after boot from install media
Set a root password: `passwd root` 
I'm not sure if this is necessary, but enable ChallengeResponseAuthentication in sshd:
`sed -i '/^Challenge/s/no/yes/' /etc/ssh/sshd_config`
Restart sshd: `systemctl restart sshd`
Get the name of the block device to install to: `lsblk`
Get the wired LAN and address the system has: `ip a`

Once that is done, go to your remote system (your ansible host) and connect once to make sure it all works

ssh root@<ip from previous command>


If you have to clean the target media after you discover an issue, you need to wipe the existing partitions. I don't know if it creates a 2MB initial area, and since it is fast, just write zeros to the first 2MB of the disk

ssh root@10.9.8.191
Password: 
Last login: Wed Mar 11 16:48:54 2020 from 10.9.8.194
root@archiso ~ # umount /mnt/boot
root@archiso ~ # umount /mnt     
root@archiso ~ # dd if=/dev/zero of=/dev/nvme0n1 bs=512 count=4096
4096+0 records in
4096+0 records out
2097152 bytes (2.1 MB, 2.0 MiB) copied, 0.110876 s, 18.9 MB/s

You have to reboot after this, as the existing partition tables are still in memory. I think there is a way to make it work, but the reboot and initial load is still quite fastand may be faster than any methos to present the disk again.

If this system has previously had something installed, you may need to deal with it.





I am always amazed by the odd things hiding in MacOS. Even using `brew` and installing `expect` will call the underlying system libraries, so still no support.



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
