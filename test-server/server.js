var io = require('socket.io').listen(9000);

io.sockets.on('connection', function (socket) {
  socket.emit('news', { hello: 'world' });
  socket.on('my other event', function (data) {
    console.log(data);
  });
    setInterval(function() {
	socket.emit("time", { date: new Date()});
    }, 5000);
    socket.on('message', function(msg) {
	socket.emit("Oh happy day.", msg);
    });
});
