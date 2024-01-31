# OpusKit

> Opus is a totally open, royalty-free, highly versatile audio codec. Opus is unmatched for interactive speech and music transmission over the Internet, but is also intended for storage and streaming applications. It is standardized by the Internet Engineering Task Force (IETF) as RFC 6716 which incorporated technology from Skype's SILK codec and Xiph.Org's CELT codec.

iOS build scripts for the [Opus Codec](http://www.opus-codec.org).

## Usage

The build-libopus.sh script will download the source automatically, but if you want to manually download the source, you can do that.  Download the [latest stable tar file](http://opus-codec.org/downloads/) 
and place it into the `build/src` directory

Note: If it's a new version of opus or if the iOS SDKs changed since the last time you built it, update that version at the top of the `build-xcframework.sh` file.

#### Step 2

From the command line, run:

```bash
$ ./build-xcframework.sh
```

The script will build static libraries for the iPhone (arm64) and iPhone simulator (arm64 and x86_64).  It then creates xcarchives for each platform and then generates an xcframework.

Include the xcframework in your project using Swift package manager or Cocoapods.


```
pod 'OpusKit', :git => 'https://github.com/phonebooth/OpusKit.git', :tag => '1.4.0'
```


## License

MIT
