import requests

response = requests.get('http://localhost:54664/sample')
data = response.json()
print(data)
