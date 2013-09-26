Safe storage
------------

Script safe-store-prep creates \*.tar.xz.gpg files out of the first level subdirectories and files in a chosen directory in order to prepare them to storage in a non-safe environment, especially in a public storage service like google disk, dropbox, ubuntu one, etc.


PREMISE/PURPOSE

To make storage in the cloud safer.


WHY THIS FORMAT/SOLUTION
- The size of a directory may be too big. Even compression will not reduce the size enough for easy uploading. As a solution the directory is split into compressed sub-folders and files of the first depth level. The compression type used is '.tar.xz'.
- The GPG encryption makes it possible to encode the compressed files for safe storage.


USAGE

See the Installation section below, or just run

	safe-storage-prep.sh --help

or

	safe-storage-prep.sh -h

The script creates md5 check sums for the folders and files to be safely stored and compares the sums to the previously created check sums before creating \*.tar.xz.gpg files. The check sums are stored in a file in 

	/$HOME/.config/md5s.

To work faster, the script does not create .tar.xz.gpg files if the check sums for a given folder or file has not changed.

If you want to force the script to create a .tar.xz.gpg file modify 

	/$HOME/.config/safe-storage-prep/md5s 

file, or delete it to force a complete re-creation of all gpg's.

Warning! Any \*.tar.xz files that are already in the directory's first level when the script starts may be removed when their core name matches the name of a folder or file that will be prepared for safe storage.


INSTALLATION

As a bash script, 'safe-storage-prep.sh' does not need an installation process. However, it is assumed that the path of the directory that is supposed to be safely stored and the GPG recipient whose public key is supposed to be used for encryption will be stored in a configuration file.
	The configuration file path is hard-coded into the script. It is
	/$HOME/.config/safe-storage-prep/sf.conf
Do not create this file. It will be created automatically at the first use. Just follow the usage/help message displayed.

The same configuration file stores the GPG recipient, as well. Again, no configuration file edition is required. The configuration parameters will be stored when the script is called with correct parameters for the first time.

When the configuration file is created, it has to be edited manually in order to modify the default parameters.


DEPENDENCIES/CONFLICTS
- gnupg 	(Command: gpg)
- tar 	(Command: tar)
- gawk 	(Command: awk)
- sed 	(Command: sed)
- coreutils 	(Command: cut)

No conflicts.


FURTHER DEVELOPMENT
-The first improvement that comes to mind is adding a command line switch to save new parameters in the configuration file. However, I will not work on it in the foreseeable future. Manual config-file modification is not that complicated after all ;).
- The second thing is optimizing the script.

