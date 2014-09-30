mamba-init
==========
nit script for mamba applications


HOW TO ADD TO YOUR PROJECT
==========================
git clone git://development/u/robert/mamba-init init && rm -rf init/.git


HOW TO INSTALL THE INIT SCRIPT
==============================
sudo init/install.sh


HOW TO CHANGE THE USER TO RUN AS
================================
sudo vi /etc/defaults/<mamba-application-name>


HOW TO SET TO START ON BOOT
===========================
sudo update-rc.d <<mamba-application-name> defaults

