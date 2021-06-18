# weblink

weblink allows you to use any device with a web browser as a proxy server.
Simply, start weblink and connect your device to it.

<img src="weblink.png" alt="weblink" align="right" width="40%">

## Installation

- (Windows only) weblink requires ruby to run. If you are on Windows, go to
   rubyinstaller.org, download *ruby+devkit* and install it. You need version
   2.5 or higher. Then open Command Prompt and follow the instructions bellow.

- (Windows only) Install eventmachine

   ```
   gem install eventmachine --platform=ruby
   ```

1. Install weblink

   ```
   gem install weblink
   ```

1. Start weblink

   ```
   weblink
   ```

1. weblink will output a URL that you need to open on the device you want to use
   as a proxy.

1. Now weblink is ready. Change proxy settings in your browser:

   |||
   |---|---|
   | type | `HTTPS` |
   | host | `127.0.0.1` |
   | port | `3128` |

   It's highly recommended to let the proxy resolve domain names.

   To test it, you can run:

   ```
   curl -px http://127.0.0.1:3128 https://www.google.com/
   ```

## Development

Pull requests are welcome!

Execute `./test` to run tests.
