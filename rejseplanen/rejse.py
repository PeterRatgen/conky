import requests 
import re
import json
import csv
import os
import datetime
import psycopg2

baseurl = 'http://xmlopen.rejseplanen.dk/bin/rest.exe/'
departureboardurl = 'departureBoard?id=461077600'
formaturl = '&format=json'

jsonurl = requests.get(baseurl+departureboardurl+formaturl).json()
departure_list = jsonurl['DepartureBoard']['Departure']

try:
  connection = psycopg2.connect(user = "peter",
                                password = "peter1609",
                                host = "127.0.0.1",
                                port = "5432",
                                database = "rejseplanen")

  cursor = connection.cursor()

    #cursor.execute("INSERT INTO departures (id, date, time, name, direction, rtTime) VALUES (461082109, '12.06.20', '15:56', 'Bus 10C', 'Citybus', '15:57');")
    #connection.commit()

  for i in departure_list:
    suss = re.sub('\(.*\)','',i['stop'])
    if "rtTime" in i.keys():
      insert_query = "INSERT INTO departures (transport_id, date, time, name, direction, rtTime, rtDate) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"
      insertion_record = (i['id'], i['date'], i['time'], i['name'], i['stop'], i['direction'], i['rtTime'], i['rtDate'])
      cursor.execute(insert_query, insertion_record)
      connection.commit()
    else:
      insert_query = "INSERT INTO departures (transport_id, date, time, name, stop, direction) VALUES (%s, %s, %s, %s, %s, %s)"
      insertion_record = (i['id'], i['date'], i['time'], i['name'], i['stop'], i['direction'])
      cursor.execute(insert_query, insertion_record)
      connection.commit()

finally:
        #closing database connection.
    if(connection):
        cursor.close()
        connection.close()
        print("PostgreSQL connection is closed")
                                                        

time = os.path.getmtime('/home/peter/.config/conky/rejseplanen/data.csv')

