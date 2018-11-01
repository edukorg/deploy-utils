.PHONY: download build fix-permissions

download:
	curl 'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-64bit-static.tar.xz' | tar --xz --get --directory=./ffmpeg-static/usr/local/bin --strip=1 ffmpeg-4.0.2-64bit-static/ffmpeg ffmpeg-4.0.2-64bit-static/ffprobe

fix-permissions:
	chown -R root:root ./ffmpeg-static

build:
	dpkg-deb -Zgzip --build ./ffmpeg-static
