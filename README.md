AZSocketIO
==========

AZSocketIO is a socket.io client for iOS. It:

* Supports websockets and XHR-polling transports
* Is about alpha stage
* Is heavily reliant on blocks for it's API
* Has appledocs for all user facing classes
* Welcomes patches and issues

It does not currently support namespacing a socket.

Requirements
------------

* 0.0.5 -> iOS 5.x+
* 0.0.6 -> iOS 6.x+

Protocol Support
----------------

The last stable version (0.0.6) support socket.io ~> 0.9. New version supporting socket.io 1.0 is currently on developement.

Dependencies
------------
AZSocketIO uses cocoapods, so you shouldn't have to think too much about dependencies, but here they are.

* [SocketRocket](https://github.com/square/SocketRocket)
* [AFNetworking](https://github.com/AFNetworking/AFNetworking)


Usage
-----
``` objective-c
AZSocketIO *socket = [[AZSocketIO alloc] initWithHost:@"localhost" andPort:@"9000" secure:NO];
[socket setEventReceivedBlock:^(NSString *eventName, id data) {
    NSLog(@"%@ : %@", eventName, data);
}];
[socket connectWithSuccess:^{
    [socket emit:@"Send Me Data" args:@"cows" error:nil];
} andFailure:^(NSError *error) {
    NSLog(@"Boo: %@", error);
}];
```

Author
-------

Luca Bernardi

* github:  https://github.com/lukabernardi
* twitter: https://twitter.com/luka_bernardi

Pat Shields

* github: http://github.com/pashields
* twitter: http://twitter.com/whatidoissecret

Contributors
------------

* Oli Kingshott (https://github.com/oliland)

License
-------
Apache 2.0
