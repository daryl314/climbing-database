import json
import collections
import sqlalchemy as db
from sqlalchemy.orm import scoped_session, sessionmaker


################################################################################


class TableMetadata(collections.namedtuple('TableMetadata', ['table', 'columns', 'primary_key', 'index'])):

    @property
    def data_columns(self):
        return {c for c in self.columns if c != self.primary_key}


################################################################################


class QueryResult(collections.namedtuple('QueryResult', ['result', 'errors'])):

    @property
    def ok(self):
        return self.errors is None

    @property
    def err(self):
        return self.errors is not None


################################################################################


class DatabaseEngine(object):

    # mappings from SQL types to native types
    TYPE_MAP = {
        db.sql.sqltypes.VARCHAR: [str],
        db.sql.sqltypes.INTEGER: [int],
    }

    def __init__(self, connection_string, verbose=True):
        # create an engine
        engine = db.create_engine(connection_string, echo=verbose)
        # session with threading support
        self.Session = scoped_session(sessionmaker(bind=engine))
        # metadata including views
        self.metadata = db.MetaData()
        self.metadata.reflect(bind=engine, views=True)
        # use metadata excluding views to identify keys associated with views
        table_meta = db.MetaData()
        table_meta.reflect(bind=engine)
        self.views = set(self.metadata.tables.keys()) - set(table_meta.tables.keys())

    @property
    def table_names(self):
        return sorted(self.metadata.tables.keys())

    def tableMetadata(self, table_name, record_id=None):
        """TableMetadata associated with a specified table"""
        # metadata associated with current table
        table = self.metadata.tables[table_name]
        # column names
        cols = [col.name for col in table.columns.values()]
        # primary key
        primary_keys = [col.name for col in table.columns if col.primary_key]
        primary_key = primary_keys[0] if len(primary_keys) == 1 else None
        # get an indexer if a record_id was specified
        if record_id is not None and primary_key is not None:
            idx = getattr(table.c, primary_key) == record_id
        else:
            idx = None
        # wrap everything in a TableMetadata container
        return TableMetadata(table=table, columns=cols, primary_key=primary_key, index=idx)

    def get(self, table_name, record_id=None):
        return self._check(table_name, read_only=True, callback=lambda: self._get(table_name, record_id=record_id))

    def create(self, table_name, **data):
        return self._check(table_name, data=data, all_columns=True, callback=lambda: self._create(table_name, data))

    def update(self, table_name, record_id, **data):
        return self._check(table_name, data=data, all_columns=False, callback=lambda: self._update(table_name, record_id, data))

    def delete(self, table_name, record_id):
        return self._check(table_name, callback=lambda: self._delete(table_name, record_id))

    ##### PRIVATE METHODS #####

    def _recordToDict(self, table_name, fields):
        """Convert a record (list of field values) to a dict"""
        cols = [col.name for col in self.metadata.tables[table_name].columns.values()]
        return dict(zip(cols, fields))

    def _check(self,
               table_name,         # name of table involved in transaction
               callback,           # function to call if checks pass
               read_only=False,    # is this a read-only transaction?
               data=None,          # new data for record
               all_columns=False,  # do all columns need to be provided in data?
               ):
        """Check conditions for a transaction"""
        if table_name not in self.metadata.tables:
            return self._err('Table not found: {}'.format(table_name))
        if not read_only and table_name in self.views:
            return self._err('View is read-only: {}'.format(table_name))
        if data is not None:
            meta = self.tableMetadata(table_name)
            if all_columns and set(data.keys()) != meta.data_columns:
                return self._err('Table columns {} != provided keys {}'.format(meta.data_columns, set(data.keys())))
            data_errors = []
            for k, v in data.items():
                if k not in meta.columns:
                    data_errors.append("Column {} does not exist in table {}".format(k, table_name))
                else:
                    dtype = type(meta.table.columns[k].type)
                    if dtype in self.TYPE_MAP:
                        if not any([isinstance(v, t) for t in self.TYPE_MAP[dtype]]):
                            data_errors.append("Invalid column data type.  Provided: {}  Expected: {}".format(dtype, self.TYPE_MAP[dtype]))
                            return False
                    else:
                        raise RuntimeError("Unexpected SQL data type: {}".format(dtype))
            if len(data_errors) > 0:
                return self._errs(data_errors)
        return callback()

    def _err(self, msg):
        return QueryResult(result=None, errors=[msg])

    def _errs(self, msgs):
        return QueryResult(result=None, errors=msgs)

    def _ok(self, result):
        return QueryResult(result=result, errors=None)

    def _get(self, table_name, record_id=None):
        meta = self.tableMetadata(table_name, record_id)
        if record_id is None:
            result = [self._recordToDict(table_name, row) for row in self.Session.execute(meta.table.select())]
        elif meta.index is not None:
            rows = self.Session.execute(meta.table.select().where(meta.index)).fetchone()
            if rows is None:
                return self._err('Failed to fetch record: {}'.format(record_id))
            result = self._recordToDict(table_name, rows)
        else:
            return self._err('Failed to select index column(s): {}'.format([col.name for col in table.columns if col.primary_key]))
        return self._ok(result)

    def _create(self, table_name, data):
        meta = self.tableMetadata(table_name)
        record = data.copy()
        result = self.Session.execute(meta.table.insert().values(**record))
        [record[meta.primary_key]] = result.inserted_primary_key
        self.Session.commit()
        return self._ok(record)

    def _update(self, table_name, record_id, data):
            meta = self.tableMetadata(table_name, record_id)
            self.Session.execute(meta.table.update().where(meta.index).values(**data))
            self.Session.commit()
            return self.get(table_name, record_id)

    def _delete(self, table_name, record_id):
        meta = self.tableMetadata(table_name, record_id)
        result = self.get(table_name, record_id)
        if result.err:
            return result
        else:
            self.Session.execute(meta.table.delete().where(meta.index))
            self.Session.commit()
            return result
