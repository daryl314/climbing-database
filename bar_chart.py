import sqlite3, datetime, pandas as pd, numpy as np

def genChart(df, nYears=10):
    def pivot(row,col):
        return pd.pivot_table(df.loc[:,[row,col]], index=row, columns=col, aggfunc=len)
    pivot('Grade','Years').plot.bar(stacked=True, figsize=(10,10))
    pivot('Year','Grade').plot.area(figsize=(10,10))

conn = sqlite3.connect('climbing.db')
c = conn.cursor()
query = c.execute('SELECT * FROM SENDS ORDER BY GradeSort')
cols = [d[0] for d in query.description]
data = [dict(zip(cols,row)) for row in c.fetchall()]
data = pd.DataFrame(data)

data.SendDate = pd.to_datetime(data.SendDate)
data['Year'] = data.SendDate.map(lambda x:x.year)
data['Years'] = np.ceil((datetime.datetime.now() - data.SendDate).dt.days / 365.25)
data['Grade'] = data.Grade.map(lambda x:x[:5])

genChart(data[(data.RouteType == 'Boulder') & (data.GradeSort >= 6)])
genChart(data[(data.RouteType == 'Route') & (data.GradeSort >= 512)])
