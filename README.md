# streamdataio-iOS / stockmarket sample
This application shows how to use the <a href="http://streamdata.io" target="_blank">streamdata.io</a> proxy in a simple iOS app.

Streamdata.io allows to get data pushed from various sources. This sample application shows simulated market data values pushed by Streamdata.io proxy using Server-sent events.

## License

* [Apache Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)


To run the sample, you can clone this GitHub repository, and then open the project with XCode.


## Add the Streamdata.io authentication token

Before running the project on a phone or emulator, you have to paste a token to be authenticated by the proxy.

Modify ViewController.m on line 28 :

```
static NSString * kToken =
    @"YOUR_TOKEN-HERE";
```

To get a token, please sign up for free to the <a href="https://portal.streamdata.io/" target="_blank">streamdata.io portal</a> and follow the guidelines. You will find your token in the 'security' section.

## Project dependencies


The application dependencies are available on GitHub

* TRVSEventSource Server-Sent-Event library : <a href="https://github.com/travisjeffery/TRVSEventSource" target="_blank">https://github.com/travisjeffery/TRVSEventSource</a>
* JSONTools : <a href="https://github.com/grgcombs/JSONTools" target="_blank">https://github.com/grgcombs/JSONTools</a>

If you have any questions or feedback, feel free to contact us at <a href="mailto://support@streamdata.io">support@streamdata.io</a>

Enjoy!
