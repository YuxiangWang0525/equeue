/*
Maiqueue Using GNU Public License to distribute software
By YuxiangWang0525 Initial Development
*/
import 'dart:async';
import 'dart:io';

class QueueItem {
  final String uid;
  DateTime arrivalTime;

  QueueItem(this.uid): arrivalTime = DateTime.now();
}


class QueueBackend {
  Map<String, List<QueueItem>> queues = {};

  void enqueue(String mid, String uid) {
    if (!queues.containsKey(mid)) {
      queues[mid] = [];
    }
    queues[mid]?.add(QueueItem(uid));
  }

  void dequeue(String mid, String uid) {
    if (queues.containsKey(mid)) {
      queues[mid]?.removeWhere((item) => item.uid == uid);
    }
  }

  int getQueueLength(String mid) {
    if (queues.containsKey(mid)) {
      return queues[mid]?.length ?? 0;
    }
    return 0;
  }
}

void main() {
  final backend = QueueBackend();

  HttpServer.bind('0.0.0.0', 8080).then((server) {
    print('Server running on 0.0.0.0:${server.port}');

    server.listen((request) {
      final uri = request.uri;
      final path = uri.path;
      final queryParams = uri.queryParameters;

      if (path == '/queue') {
        final uid = queryParams['uid'];
        final mid = queryParams['mid'];

        if (uid != null && mid != null) {
          backend.enqueue(mid, uid);
          request.response.write('User $uid added to queue $mid');
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write('Missing UID or MID parameter');
        }
      } else if (path == '/pick') {
        final uid = queryParams['uid'];
        final mid = queryParams['mid'];

        if (uid != null && mid != null) {
          backend.dequeue(mid, uid);
          Timer(Duration(minutes: 18), () {
            backend.enqueue(mid, uid);
          });
          request.response.write('User $uid picked from queue $mid');
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write('Missing UID or MID parameter');
        }
      } else if (path == '/done') {
        final uid = queryParams['uid'];
        final mid = queryParams['mid'];

        if (uid != null && mid != null) {
          backend.enqueue(mid, uid);
          request.response.write('User $uid marked as done for queue $mid');
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write('Missing UID or MID parameter');
        }
      } else if (path == '/outqueue') {
        final uid = queryParams['uid'];

        if (uid != null) {
          backend.queues.forEach((mid, queue) {
            queue.removeWhere((item) => item.uid == uid);
          });
          request.response.write('User $uid removed from all queues');
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write('Missing UID parameter');
        }
      } else if (path == '/lookup') {
        final mid = queryParams['mid'];

        if (mid != null) {
          final queueLength = backend.getQueueLength(mid);
          request.response.write('Current queue length for $mid: $queueLength');
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write('Missing MID parameter');
        }
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Not found');
      }

      request.response.close();
    });
  });
}
