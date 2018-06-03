import sqlite3, json, argparse, SocketServer
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer

################################################################################

def query_db(db, query, as_json=True):
    """Query a SQLite3 database"""
    if isinstance(db, sqlite3.Connection):
        conn = db
    else:
        conn = sqlite3.connect(db)
    c = conn.cursor()
    query = c.execute(query)
    cols = [d[0] for d in query.description]
    out = [dict(zip(cols,row)) for row in c.fetchall()]
    if as_json:
        out = json.dumps(out)
    return out

################################################################################

def run(db, addr='127.0.0.1', port=8888):
    """Start a server backed by a SQLite3 database"""

    class WrappedHandler(SQLiteServer):
        """Inner class to handle requests"""

        def __init__(self, *args, **kwargs):
            self.conn = sqlite3.connect(db)
            super(WrappedHandler, self).__init__(*args, **kwargs)

        def _set_headers(self):
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()

        def do_GET(self):
            self._set_headers()
            if self.path.startswith('/') and self.path[1:].isalnum():
                self.wfile.write(query_db(self.conn, 'SELECT * from %s' % self.path[1:]))
            else:
                self.wfile.write('<html><body><h1>Invalid query: %s</h1></body></html>')

        def do_HEAD(self):
            self._set_headers()

    print 'Starting http server: %s:%s' % (addr,port)
    HTTPServer((addr,port), WrappedHandler).serve_forever()

################################################################################

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="SQLite3 data server")
    parser.add_argument('database', help='Database file to query')
    parser.add_argument('--address', help='Address for server (default 127.0.0.1)', default='127.0.0.1')
    parser.add_argument('--port', help='Port for server (default 8888)', type=int, default=8888)
    parser.add_argument('--dump-table', help='Dump specified table as json to stdout instead of serving')
    parser.add_argument('--dump-variable', help='Variable to use to wrap dumped json')
    args = parser.parse_args()
    if args.dump_table is None:
        run(args.database, addr=args.address, port=args.port)
    else:
        out = query_db(args.database, 'SELECT * from '+args.dump_table, as_json=True)
        if args.dump_variable is not None:
            out = '%s=%s;' % (args.dump_variable,out)
        print out
