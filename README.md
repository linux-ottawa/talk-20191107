# Linux-Ottawa November 7, 2019

## Notes and files for the talk

This is for the Linux-Ottawa talk on setting up your laptop/desktop/whatever system. In my case, I have 

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
