import requests 
import re
import json
import csv
import os
import datetime

baseurl = 'http://xmlopen.rejseplanen.dk/bin/rest.exe/'
departureboardurl = 'departureBoard?id=461077600'
formaturl = '&format=json'

jsonurl = requests.get(baseurl+departureboardurl+formaturl).json()
departure_list = jsonurl['DepartureBoard']['Departure']

with open('/home/peter/.config/conky/rejseplanen/data.csv', 'w') as file:
    writer = csv.writer(file)
    for i in departure_list:
        suss = re.sub('\(.*\)','',i['stop'])
        writer.writerow([i['name'], i['time'], i['direction'], suss])

time = os.path.getmtime('/home/peter/.config/conky/rejseplanen/data.csv')

