# ffmpeg-static


- make download

Download and decompress ffmpeg static binaries


- make fix-permissions

Without this step, the files will be generated with the current user as owner.
This changes it to root.


- make build

Gerenates .deb file.
It forces to be gzip to bypass old dpkg bugs
