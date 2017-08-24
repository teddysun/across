#!/usr/bin/env python3
#coding=utf-8


def text(files):
	with open('cet.txt','w+') as f:
		f.write(files)

def read_text():
	with open('cet.txt','r') as f:
		data = f.read()
	return data
	
import requests,os
from time import sleep
from urllib.parse import quote
from bs4 import BeautifulSoup as bs


URL='http://www.chsi.com.cn/cet/'
data = 'query?zkzh={}&xm={}'

H = {'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
'Accept-Encoding':'gzip, deflate',
'Accept-Language':'zh-CN,zh;q=0.8',
'Connection':'keep-alive',
'Host':'www.chsi.com.cn',
'Referer':'http://www.chsi.com.cn/cet/',
'Upgrade-Insecure-Requests':'1',
'User-Agent':'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.101 Safari/537.36',
}

def query(id__,name):
	s = requests.Session()
	req = s.get(URL,headers=H)

	if req.ok :
		url = URL + data.format(id__,quote(name))
		req = requests.get(url,headers=H,cookies=req.cookies)
		return req.text
	else:
		print(id__,name,'出错',sep='-->')
		return False


def check(html):
	soup = bs(html,'html.parser')
	
	if soup.find('div',{"class":"error alignC marginT20"}):
		return False
	elif soup.find('div',{"class":"error alignC"}):
		print("缺少验证码")
		return False
	else:
		return True

#html = read_text()
def parse(html):
	soup = bs(html,'html.parser')

	table = soup.find('table',{"border":"0","align":"center"})

	string = ''
	for n in table.getText().split():
		string += n

	return string


def append_file(string):
	with open('cet.txt','a+') as f:
		f.writelines(string + os.linesep)

number = 420550171103500,420550171103599 ### 420550171103524 贺深


### testing
'''text = query(420550171103524,'贺深')
if check(text):
	print(parse(text))
else:
	print('没有')
exit(0)'''
### testing end
names = ['贺深','张旭','陈飞扬','赵昊罡','潘猛']
for num in range(1,11):
    for zkzh in [i for i in range(*number)]:
        for xm in names:
            text = query(zkzh,xm)
            if check(text):
                result = parse(text)
                print(result)
                append_file(result)
                continue
            else:
                print(zkzh,xm,sep='-->')
            sleep(2)
