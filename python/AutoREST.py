#!/usr/bin/env python3

import os
import argparse
from flask import Flask, request, render_template, abort, jsonify, make_response
from DatabaseEngine import DatabaseEngine


################################################################################


class Responses:
    OK = 200
    CREATED = 201
    BAD_REQUEST = 400
    NOT_FOUND = 404


################################################################################


class DatabaseServer(object):

    def __init__(self,
                 import_name,             # name of application package (__name__ is normal usage)
                 connection_string,       # database connection string
                 verbose=True,            # verbose output?
                 debug=True,              # run server in debug mode?
                 host='127.0.0.1',        # server hostname
                 port=5000,               # server port
                 static_url_path=None,    # url to static content (defaults to name of static folder)
                 static_folder='static',  # folder to use for serving static content
                 ):
        self.engine = DatabaseEngine(connection_string, verbose=verbose)
        self.app = Flask(import_name, static_folder=static_folder, static_url_path=static_url_path)
        self._attachHandlers()
        if verbose:
            self._describe(host, port)
        self.app.run(host=host, port=port, debug=debug)

    def _attachHandlers(self):

        def flask_get(table_name, record_id=None):
            result = self.engine.get(table_name, record_id)
            if result.ok:
                return jsonify(result.result), Responses.OK
            else:
                abort(Responses.NOT_FOUND, '\n'.join(result.errors))

        @self.app.errorhandler(Responses.BAD_REQUEST)
        def not_found(error):
            print('ERROR: {}'.format(error.description.__repr__()))
            return make_response(jsonify({'error': 'Bad request', 'details': error.description}), 400)

        @self.app.errorhandler(Responses.NOT_FOUND)
        def not_found(error):
            return make_response(jsonify({'error': 'Not found'}), 404)

        @self.app.route("/tables")
        def listTables():
            out = []
            for table_name in self.engine.table_names:
                if table_name in self.engine.views:
                    out.append({'name': table_name, 'type': 'view'})
                else:
                    meta = self.engine.tableMetadata(table_name)
                    out.append({'name': table_name, 'id': meta.primary_key, 'type': 'table'})
            return jsonify(out)

        @self.app.route("/tables/<table_name>")
        def getTable(table_name):
            print("GET: {}".format(table_name))
            return flask_get(table_name)

        @self.app.route("/tables/<table_name>/<int:record_id>", methods=['GET'])
        def getRecord(table_name, record_id):
            print('GET: {}/{}'.format(table_name, record_id))
            return flask_get(table_name, record_id)

        @self.app.route("/tables/<table_name>/<int:record_id>", methods=['PUT'])
        def updateRecord(table_name, record_id):
            print('PUT: {}/{} --> {}'.format(table_name, record_id, request.json))
            if not request.json:
                abort(Responses.BAD_REQUEST)
            result = self.engine.update(table_name, record_id, **request.json)
            if result.ok:
                return jsonify(result.result), Responses.OK
            else:
                abort(Responses.BAD_REQUEST, '\n'.join(result.errors))

        @self.app.route("/tables/<table_name>", methods=['POST'])
        def createRecord(table_name):
            print('POST: {} -> {}'.format(table_name, request.json))
            if not request.json:
                abort(Responses.BAD_REQUEST)
            result = self.engine.create(table_name, **request.json)
            if result.ok:
                print("Create OK: {}".format(result.result))
                return jsonify(result.result), Responses.CREATED
            else:
                abort(Responses.BAD_REQUEST, '\n'.join(result.errors))

        @self.app.route("/tables/<table_name>/<int:record_id>", methods=['DELETE'])
        def deleteRecord(table_name, record_id):
            print('DELETE: {}/{}'.format(table_name, record_id))
            status = self.engine.delete(table_name, record_id)
            if status.ok:
                return jsonify({'result': True}), Responses.OK
            else:
                abort(Responses.BAD_REQUEST, '\n'.join(result.errors))

    def _describe(self, host, port):
        print("REST server started at http://{}:{}".format(host, port))
        print("Tables:")
        for tbl in self.engine.table_names:
            print("    - {}{}".format(tbl, ' [View]' if tbl in self.engine.views else ''))
        print("GET table names:  curl {}:{}/tables".format(host, port))
        print("GET a table:      curl {}:{}/tables/table_name".format(host, port))
        print("GET an entry:     curl {}:{}/tables/table_name/record_id".format(host, port))
        print("PUT a new entry:  curl -d '{{\"update_field\": \"New Value\"}}' -H 'Content-Type: application/json' -X PUT {}:{}/tables/table_name/record_id".format(host, port))
        print("POST an update:   curl -d '{{\"field1\": \"Value1\", \"field2\": 10}}' -H 'Content-Type: application/json' {}:{}/tables/table_name".format(host, port))
        print("DELETE an entry:  curl -X DELETE {}:{}/tables/table_name/record_id".format(host, port))


################################################################################


if __name__ == '__main__':
    STATIC_DEFAULT = os.path.join(os.path.abspath('.'), 'static')
    parser = argparse.ArgumentParser()
    parser.add_argument('database', help='SQLITE database file')
    parser.add_argument('--quiet', action='store_true', help='Silence verbose output')
    parser.add_argument('--nodebug', action='store_true', help='Run without debug mode')
    parser.add_argument('--host', default='127.0.0.1', help='Web server hostname')
    parser.add_argument('--port', type=int, default=5000, help='Web server port')
    parser.add_argument('--static-url-path', help='URL for serving static content')
    parser.add_argument('--static-folder', default=STATIC_DEFAULT, help='Folder containing static content')
    parser.add_argument('--import-name', default=__name__, help='Name of application package')
    args = parser.parse_args()
    DatabaseServer(args.import_name, 'sqlite:///{}'.format(args.database), verbose=not args.quiet,
                   debug=not args.nodebug, host=args.host, port=args.port,
                   static_url_path=args.static_url_path, static_folder=args.static_folder)
