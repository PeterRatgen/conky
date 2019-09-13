import requests
import datetime
import csv
from bs4 import BeautifulSoup

Target_URLs = ['https://www.pricerunner.dk/pl/2-4873249/TV/Samsung-QE43Q60R-Sammenlign-Priser',
'https://www.pricerunner.dk/pl/2-4880274/TV/Samsung-UE43RU7475-Sammenlign-Priser',
'https://www.pricerunner.dk/pl/2-4870534/TV/Samsung-UE43RU7415-Sammenlign-Priser',
'https://www.pricerunner.dk/pl/2-4865350/TV/Samsung-UE43RU7105-Sammenlign-Priser']

head = {"User-Agent": 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:69.0) Gecko/20100101 Firefox/69.0'}

def get_name(soouup):
    name = soouup.find("h1", itemprop="name").get_text()
    return name

def get_price(soouup):
    minPrice = soouup.find("meta", itemprop="lowPrice")
    if(minPrice == None):
        #If only one vender, take the only price
        minPrice = soouup.find("meta", itemprop="price")
    return minPrice


def get_all_prices(URLs, header):
    prices = []
    for i in range(len(URLs)):
        page = requests.get(URLs[i], headers = header)
        soup = BeautifulSoup(page.content, 'html.parser')
        prices.append([get_name(soup),get_price(soup)["content"], datetime.datetime.now()])
    return sorted(prices)

def get_to_file(URLs, header):
    re = []
    with open("output.csv",'r+') as resultFile:
        csv_reader = csv.reader(resultFile, delimiter=',')
        for row in csv_reader:
            datetime_str = row[2]
            datetime_obj = datetime.datetime.strptime(datetime_str, '%Y-%m-%d %H:%M:%S.%f')
            row[2] = datetime_obj
            re.append(row)
        if(len(re) == 0):
            wr = csv.writer(resultFile, dialect='excel')
            wr.writerows(get_all_prices(URLs, head))
        else:
            if(datetime.datetime.now() - re[len(re)-1][2] > datetime.timedelta(seconds=5)):
                print("difference is greater than 1 hour")
                wr = csv.writer(resultFile, dialect='excel')
                rows = get_all_prices(Target_URLs, head);
                for i in range(len(URLs)):
                    k = i + len(URLs)*(len(re)/len(URLs))
                    rows[i].append(re[k][2]-rows[i][2])
                print(rows)
                wr.writerows(rows)
            else:
                print("difference is not greater than 1 hour")

def print_file():
    with open("output.csv",'r+') as resultFile:
        ss = []
        csv_reader = csv.reader(resultFile, delimiter=',')
        for row in csv_reader:
            ss.append(row)
        for i in range(int(len(ss)/3)):
            for j in range(int(len(ss)/4)):
                print(ss[i+(4*j)])

get_to_file(Target_URLs, head)
