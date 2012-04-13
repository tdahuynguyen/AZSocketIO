var io = require('socket.io').listen(9000);

io.sockets.on('connection', function (socket) {
  socket.emit('news', { hello: 'world' });
  socket.on('my other event', function (data) {
    console.log(data);
  });
	socket.on('message', function(msg) {
		socket.emit("Oh happy day.", msg);
	});
	socket.on('foo', function(msg) {
		socket.emit('foo', msg);
	});
	socket.on('zippy', function (name, fn) {
    fn('kthx');
  });
});
