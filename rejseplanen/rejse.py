import requests 
import re
import json
import csv
import os
import datetime
import psycopg2
from psycopg2.extras import Json
import json

baseurl = 'http://xmlopen.rejseplanen.dk/bin/rest.exe/'
departureboardurl = 'departureBoard?id=461077600'
formaturl = '&format=json'

# Retrieve the departurebord from rejseplanen
jsonurl = requests.get(baseurl+departureboardurl+formaturl).json()
departure_list = jsonurl['DepartureBoard']['Departure']

# Get the reference uri from the top entry on the departureboard
journey_detail = requests.get(departure_list[0]['JourneyDetailRef']['ref']).json()

try:
  connection = psycopg2.connect(user = "peter",
                                password = "peter1609",
                                host = "127.0.0.1",
                                port = "5432",
                                database = "rejseplanen")

  cursor = connection.cursor()

  # Insert the data for each entry of the departureboard
  for i in departure_list:
    if "rtTime" in i.keys():
      insert_query = "INSERT INTO departures (transport_id, date, time, name, stop, direction, journey_detail_ref, rtTime, rtDate) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)"
      insertion_record = (i['id'], i['date'], i['time'], i['name'], i['stop'], i['direction'], i['JourneyDetailRef']['ref'], i['rtTime'], i['rtDate'])
      cursor.execute(insert_query, insertion_record)
    else:
      insert_query = "INSERT INTO departures (transport_id, date, time, name, stop, direction, journey_detail_ref) VALUES (%s, %s, %s, %s, %s, %s, %s)"
      insertion_record = (i['id'], i['date'], i['time'], i['name'], i['stop'], i['direction'], i['JourneyDetailRef']['ref'])
      cursor.execute(insert_query, insertion_record)
  connection.commit()

  # get id of top departure
  select_latest = "select (id) from (select (id) from departures order by id desc limit 20) as foo order by id asc limit 1;"
  cursor.execute(select_latest)
  lastest_id = cursor.fetchone()[0]

  # insert journey into journey_table with the id of top departure
  insert_journey_query = "INSERT INTO journey_table (departure_id, query) VALUES (%s, %s)"
  insertion_record = (lastest_id, json.dumps(journey_detail))
  cursor.execute(insert_journey_query, insertion_record)
  connection.commit()

finally:
    if(connection):
        cursor.close()
        connection.close()
                                                        


