import sqlite3, json

def query_db(db, query):
    conn = sqlite3.connect(db)
    c = conn.cursor()
    query = c.execute(query)
    cols = [d[0] for d in query.description]
    return [dict(zip(cols,row)) for row in c.fetchall()]

with open('data.js','wt') as F:
    F.write('data=%s;' % json.dumps(query_db(
            'climbing.db', 
            'SELECT * FROM SENDS ORDER BY GradeSort'
            )))